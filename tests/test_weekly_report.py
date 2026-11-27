"""Unit tests for the weekly-report skill scripts."""

import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = ROOT / "plugins" / "myst-dev-kit" / "skills" / "weekly-report" / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import collect_token_usage as ctu  # noqa: E402
import collect_weekly_work as cww  # noqa: E402
import save_weekly_report as swr  # noqa: E402


class WeeklyReportTests(unittest.TestCase):
    def test_compute_window_rolling_hour_and_since_until_override(self):
        tz = timezone(timedelta(hours=8))
        now = datetime(2026, 11, 27, 13, 45, 12, tzinfo=tz)
        cutoff, end = cww.compute_window(days=7, now=now)
        self.assertEqual(cutoff, datetime(2026, 11, 20, 13, 0, 0, tzinfo=tz))
        self.assertEqual(end, now)

        cutoff_custom, end_custom = cww.compute_window(
            days=7,
            since="2026-11-25 09:30:15+08:00",
            until="2026-11-27 14:00:01+08:00",
            now=now,
        )
        self.assertEqual(cutoff_custom, datetime(2026, 11, 25, 9, 30, 15, tzinfo=tz))
        self.assertEqual(end_custom, datetime(2026, 11, 27, 14, 0, 1, tzinfo=tz))

        cutoff_ps, _ = cww.compute_window(days=7, since="11/25/2026 09:30:15", now=now)
        self.assertEqual(cutoff_ps, datetime(2026, 11, 25, 9, 30, 15, tzinfo=tz))

    def test_detect_vcs_uninitialized_git_vs_ambiguous_dual_vcs(self):
        with tempfile.TemporaryDirectory() as tmp:
            p4_probe = {"available": True, "bound": True}
            git_no_head = {"available": True, "work_tree": True, "has_head": False, "has_remote": False}
            self.assertEqual(cww.detect_vcs(tmp, p4_probe, git_no_head, "auto"), "p4")

            # Dual VCS with initialized Git HEAD (with or without remote) must require explicit --vcs choice.
            git_with_remote = {"available": True, "work_tree": True, "has_head": True, "has_remote": True}
            git_no_remote = {"available": True, "work_tree": True, "has_head": True, "has_remote": False}
            with self.assertRaises(RuntimeError):
                cww.detect_vcs(tmp, p4_probe, git_with_remote, "auto")
            with self.assertRaises(RuntimeError):
                cww.detect_vcs(tmp, p4_probe, git_no_remote, "auto")
            self.assertEqual(cww.detect_vcs(tmp, p4_probe, git_with_remote, "p4"), "p4")
            self.assertEqual(cww.detect_vcs(tmp, p4_probe, git_with_remote, "git"), "git")

            # Explicit --vcs p4 must fail if workspace is not bound to the active P4 client.
            with self.assertRaises(RuntimeError):
                cww.detect_vcs(tmp, {"available": True, "bound": False, "client": "other", "client_root": "/other"}, git_with_remote, "p4")

            # Without p4 binding, git work_tree selects git.
            self.assertEqual(cww.detect_vcs(tmp, {"available": True, "bound": False}, git_with_remote, "auto"), "git")

    def test_parse_p4_describe_and_offset(self):
        tz_utc = cww.parse_offset_str("+0000")
        tz_local = timezone(timedelta(hours=8))
        sample = (
            "Change 5122 by dev@ws on 2026/11/26 04:30:00\n\n"
            "\t[design][sxc] Add continuous escape gait\n\n"
            "\t## Summary\n"
            "\tImplement continuous escape and target hold.\n"
            "\tTicket: .scratch/npc-melee/issues/04.md\n\n"
            "\t## Verification\n"
            "\tHeadless PIE 16/16 passed.\n\n"
            "Affected files ...\n\n"
            "... //Depot/main/Foo.as#3 edit\n"
            "... //Depot/main/Bar.as#1 add\n"
        )
        parsed = cww.parse_p4_describe(sample, tz_utc, tz_local)
        self.assertEqual(parsed["local_time"], "2026-11-26 12:30")
        self.assertEqual(parsed["tags"], ["design", "sxc"])
        self.assertEqual(parsed["ticket"], ".scratch/npc-melee/issues/04.md")
        self.assertIn("Implement continuous escape", parsed["summary"])
        self.assertIn("16/16 passed", parsed["verification"])
        self.assertEqual(parsed["file_count"], 2)
        self.assertEqual(parsed["sample_files"], ["//Depot/main/Foo.as", "//Depot/main/Bar.as"])

    def test_collect_perforce_scopes_end_bound_and_raises_on_query_failure(self):
        tz = timezone.utc
        cutoff = datetime(2026, 11, 16, 12, 0, tzinfo=tz)
        now_local = datetime(2026, 11, 23, 12, 0, tzinfo=tz)
        seen_cmds = []

        def fake_ok(cmd, **kwargs):
            seen_cmds.append(cmd)
            if "submitted" in cmd:
                return 0, "5122\n5199\n", ""
            if "pending" in cmd:
                return 0, "5124\n5125\n", ""
            if "describe" in cmd and "5122" in cmd:
                return 0, "Change 5122 by u@wsA on 2026/11/22 10:00:00\n\n\t[design] A\n\nAffected files ...\n\n... //ProjA/main/F.as#1 edit\n", ""
            if "describe" in cmd and "5199" in cmd:
                # Out-of-window later submission must be excluded even if server returned it.
                return 0, "Change 5199 by u@wsA on 2026/11/24 10:00:00\n\n\t[design] Later\n\nAffected files ...\n\n... //ProjA/main/L.as#1 edit\n", ""
            if "describe" in cmd and "5124" in cmd:
                return 0, "Change 5124 by u@wsA on 2026/11/22 11:00:00 *pending*\n\n\t[design] B\n", ""
            if "describe" in cmd and "5125" in cmd:
                # Post-until pending CL must be classified into wip_older, not wip_active.
                return 0, "Change 5125 by u@wsA on 2026/11/24 11:00:00 *pending*\n\n\t[design] FuturePending\n", ""
            return 0, "", ""

        probe = {"user": "u", "client": "wsA", "client_root": "/wsA", "client_stream": "//ProjA/main", "server_tz": tz, "server_offset_str": "+0000"}
        with patch.object(cww, "run_cmd", side_effect=fake_ok):
            res = cww.collect_perforce(probe, "/wsA", "ProjA", "", cutoff, now_local, {})
        self.assertTrue(res["meta"]["complete"])
        self.assertEqual(res["counts"]["completed"], 1)
        self.assertEqual(res["counts"]["completed_ids_returned"], 1)
        self.assertEqual([c["id"] for c in res["completed"]], ["5122"])
        self.assertEqual([w["id"] for w in res["wip_active"]], ["5124"])
        self.assertEqual([w["id"] for w in res["wip_older"]], ["5125"])
        sub_cmd = next(c for c in seen_cmds if "submitted" in c)
        pend_cmd = next(c for c in seen_cmds if "pending" in c)
        self.assertTrue(any(arg == "//ProjA/main/...@2026/11/16:12:00:00,@2026/11/23:12:00:00" for arg in sub_cmd))
        self.assertIn("-c", pend_cmd)
        self.assertIn("wsA", pend_cmd)

        def fake_fail(cmd, **kwargs):
            if "submitted" in cmd:
                return 1, "", "Perforce password invalid"
            return 0, "", ""

        with patch.object(cww, "run_cmd", side_effect=fake_fail):
            with self.assertRaises(RuntimeError):
                cww.collect_perforce(probe, "/wsA", "ProjA", "", cutoff, now_local, {})

    def test_collect_git_rejects_malformed_and_id_mismatch_and_bounds_wip_until(self):
        start = datetime(2026, 11, 20, tzinfo=timezone.utc)
        end = datetime(2026, 11, 23, tzinfo=timezone.utc)
        valid_rec = ("a" * 40) + "\x1faaaaaaa\x1f2026-11-22T08:00:00+00:00\x1fSubject\x1fBody"
        other_rec = ("b" * 40) + "\x1fbbbbbbb\x1f2026-11-22T09:00:00+00:00\x1fOther\x1fBody"

        def fake_malformed(cmd, **kwargs):
            if "rev-parse" in cmd:
                return 0, ("a" * 40) + "\n", ""
            if "rev-list" in cmd:
                return 0, ("a" * 40) + "\n" + ("b" * 40) + "\n", ""
            if "log" in cmd:
                return 0, valid_rec + "\x1e" + ("b" * 40) + "\x1e", ""
            return 0, "", ""

        with patch.object(cww, "resolve_git_default_ref", return_value="main"), patch.object(cww, "run_cmd", side_effect=fake_malformed):
            with self.assertRaises(RuntimeError):
                cww.collect_git({"has_head": True}, ".", "GitRepo", "", start, end, {})

        def fake_id_mismatch(cmd, **kwargs):
            if "rev-parse" in cmd:
                return 0, ("a" * 40) + "\n", ""
            if "rev-list" in cmd:
                return 0, ("a" * 40) + "\n", ""
            if "log" in cmd:
                return 0, other_rec + "\x1e", ""
            return 0, "", ""

        with patch.object(cww, "resolve_git_default_ref", return_value="main"), patch.object(cww, "run_cmd", side_effect=fake_id_mismatch):
            with self.assertRaises(RuntimeError):
                cww.collect_git({"has_head": True}, ".", "GitRepo", "", start, end, {})

        def fake_future_stash(cmd, **kwargs):
            if "rev-parse" in cmd:
                return 0, ("a" * 40) + "\n", ""
            if "stash" in cmd:
                return 0, "stash@{0}\x1f2026-11-24T08:00:00+00:00\x1fAfter until\n", ""
            return 0, "", ""

        with patch.object(cww, "resolve_git_default_ref", return_value="main"), patch.object(cww, "run_cmd", side_effect=fake_future_stash):
            res = cww.collect_git({"has_head": True}, ".", "GitRepo", "", start, end, {})
        self.assertEqual(res["counts"]["wip_active"], 0)
        self.assertEqual([w["id"] for w in res["wip_older"]], ["stash@{0}"])

    def test_collect_git_end_to_end_and_index_untouched(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            env = dict(os.environ, GIT_TERMINAL_PROMPT="0")

            def g(*args):
                return subprocess.run(["git", *args], cwd=repo, env=env, check=True, capture_output=True, text=True)

            g("init", "-b", "main")
            g("config", "user.name", "Test User")
            g("config", "user.email", "test@example.com")

            (repo / "a.txt").write_text("hello\n", encoding="utf-8")
            g("add", "a.txt")
            g("commit", "-m", "feat(core): add initial file (#12)")

            g("checkout", "-b", "feat/wip-branch")
            (repo / "b.txt").write_text("wip\n", encoding="utf-8")
            g("add", "b.txt")
            g("commit", "-m", "wip: branch work")

            g("checkout", "main")
            (repo / "a.txt").write_text("stashed\n", encoding="utf-8")
            g("stash", "push", "-m", "saved work")
            (repo / "dirty.txt").write_text("dirty\n", encoding="utf-8")

            index_path = repo / ".git" / "index"
            before_bytes = index_path.read_bytes()

            cutoff, now_local = cww.compute_window(days=7)
            p4_probe = {"available": False, "bound": False}
            git_probe = cww.probe_git(str(repo))
            res = cww.collect_git(git_probe, str(repo), repo.name, "", cutoff, now_local, p4_probe)

            self.assertEqual(index_path.read_bytes(), before_bytes)
            self.assertEqual(res["meta"]["vcs"], "git")
            self.assertTrue(res["meta"]["complete"])
            self.assertEqual(res["counts"]["completed"], 1)
            self.assertEqual(res["completed"][0]["tags"], ["feat", "core"])
            self.assertEqual(res["completed"][0]["ticket"], "#12")
            kinds = {item["kind"] for item in res["wip_active"]}
            self.assertEqual(kinds, {"working_tree", "branch", "stash"})

    def test_collect_token_usage_across_three_hosts_and_cross_file_claude_dedup(self):
        tz = timezone(timedelta(hours=8))
        now = datetime(2026, 11, 27, 13, 0, 0, tzinfo=tz)
        since = now - timedelta(days=7)

        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws = base / "MyRepo"
            ws.mkdir()

            ag_root = base / "ag"
            conv_id = "conv-1"
            log_dir = ag_root / "brain" / conv_id / ".system_generated" / "logs"
            log_dir.mkdir(parents=True)
            db_path = ag_root / "conversation_summaries.db"
            con = sqlite3.connect(db_path)
            con.execute("CREATE TABLE conversation_summaries (conversation_id TEXT PRIMARY KEY, workspace_uris TEXT, parent_conversation_id TEXT)")
            con.execute("INSERT INTO conversation_summaries VALUES (?, ?, ?)", (conv_id, json.dumps([ws.as_uri()]), ""))
            con.commit()
            con.close()

            (log_dir / "transcript.jsonl").write_text(
                json.dumps({
                    "created_at": (now - timedelta(hours=2)).isoformat(),
                    "model": "gemini-4-neon-high",
                    "input_tokens": 100_000,
                    "cache_read_tokens": 900_000,
                    "output_tokens": 10_000,
                }) + "\n",
                encoding="utf-8",
            )

            codex_dir = base / "codex" / "sessions" / "2026" / "11" / "26"
            codex_dir.mkdir(parents=True)
            (codex_dir / "s1.jsonl").write_text(
                "\n".join([
                    json.dumps({"type": "session_meta", "payload": {"cwd": str(ws)}}),
                    json.dumps({"type": "turn_context", "payload": {"model": "gpt-6.2-sol"}}),
                    json.dumps({
                        "timestamp": (since - timedelta(hours=1)).isoformat(),
                        "type": "event_msg",
                        "payload": {"type": "token_count", "info": {"total_token_usage": {
                            "input_tokens": 1_000_000, "cached_input_tokens": 800_000, "output_tokens": 20_000, "reasoning_output_tokens": 5_000
                        }}},
                    }),
                    json.dumps({
                        "timestamp": (now - timedelta(hours=1)).isoformat(),
                        "type": "event_msg",
                        "payload": {"type": "token_count", "info": {"total_token_usage": {
                            "input_tokens": 2_000_000, "cached_input_tokens": 1_700_000, "output_tokens": 70_000, "reasoning_output_tokens": 25_000
                        }}},
                    }),
                ]) + "\n",
                encoding="utf-8",
            )

            # Claude Code: same requestId across files with partial vs final snapshot must produce identical totals regardless of order.
            claude_dir = base / "claude" / "projects" / "proj"
            claude_dir.mkdir(parents=True)
            partial_row = json.dumps({
                "cwd": "",
                "timestamp": (now - timedelta(hours=3, minutes=1)).isoformat(),
                "requestId": "req-1",
                "message": {"model": "claude-sonnet-4", "usage": {"input_tokens": 10_000, "cache_creation_input_tokens": 5_000, "cache_read_input_tokens": 50_000, "output_tokens": 0}},
            }) + "\n"
            final_row = json.dumps({
                "cwd": str(ws),
                "timestamp": (now - timedelta(hours=3)).isoformat(),
                "requestId": "req-1",
                "message": {"model": "claude-sonnet-4", "usage": {"input_tokens": 10_000, "cache_creation_input_tokens": 5_000, "cache_read_input_tokens": 50_000, "output_tokens": 4_000}},
            }) + "\n"
            (claude_dir / "a_final.jsonl").write_text(final_row, encoding="utf-8")
            (claude_dir / "z_partial.jsonl").write_text(partial_row, encoding="utf-8")

            res = ctu.collect_all_usage(
                since_dt=since,
                until_dt=now,
                workspace=str(ws),
                pricing_path=SCRIPTS_DIR / "pricing.json",
                completed_count=2,
                ag_root=ag_root,
                codex_root=base / "codex",
                claude_root=base / "claude",
            )

            ws_data = res["workspace"]
            self.assertEqual(ws_data["uncached_input"], 215_000)
            self.assertEqual(ws_data["cached_input"], 1_850_000)
            self.assertEqual(ws_data["output"], 64_000)
            self.assertEqual(ws_data["by_tool"]["claude_code"]["turns"], 1)
            self.assertGreater(ws_data["cache_savings_usd"], 0)
            self.assertEqual(res["efficiency"]["completed_count"], 2)

            home_dir = base / "home"
            (home_dir / ".myst").mkdir(parents=True)
            override = home_dir / ".myst" / "weekly-report-pricing.json"
            override.write_text("{}", encoding="utf-8")
            self.assertEqual(ctu.resolve_pricing_path("", SCRIPTS_DIR, home_dir=home_dir), override)

    def test_save_weekly_report_protects_unrelated_files_and_unowned_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            arc = Path(tmp)
            now = datetime(2026, 11, 27, 13, 45, 0)
            old_ts = (now - timedelta(days=95)).timestamp()

            # Expired owned report -> pruned.
            expired_owned = arc / "OldProj_2026-08-01_1000.md"
            expired_owned.write_text(f"{swr.REPORT_MARKER}\n# Old\n", encoding="utf-8")
            os.utime(expired_owned, (old_ts, old_ts))

            # Expired unrelated note -> MUST NOT be pruned or indexed.
            unrelated = arc / "unrelated-notes.md"
            unrelated.write_text("# Personal Notes\n", encoding="utf-8")
            os.utime(unrelated, (old_ts, old_ts))

            # Expired filename-matching file without archive marker -> MUST NOT be pruned.
            unmarked_similar = arc / "Custom_2026-08-01_1000.md"
            unmarked_similar.write_text("# Not an archive report\n", encoding="utf-8")
            os.utime(unmarked_similar, (old_ts, old_ts))

            res = swr.save_report(
                project="My Project",
                vcs="git",
                window="2026-11-20 13:00 to 2026-11-27 13:45",
                content="# Report\n\n- Shipped\n",
                archive_dir=arc,
                retention_days=90,
                now=now,
            )

            self.assertEqual(res["pruned_count"], 1)
            self.assertEqual(res["pruned_files"], ["OldProj_2026-08-01_1000.md"])
            self.assertEqual(res["retained_count"], 1)
            self.assertFalse(expired_owned.exists())
            self.assertTrue(unrelated.exists())
            self.assertTrue(unmarked_similar.exists())
            idx = Path(res["index_path"]).read_text(encoding="utf-8")
            self.assertIn("My-Project_2026-11-27_1345.md", idx)
            self.assertNotIn("unrelated-notes.md", idx)

            # Collision test: when both minute and seconds names exist, allocate unique -2 suffix without overwriting either.
            occupied_min = arc / "Collide_2026-11-27_1345.md"
            occupied_sec = arc / "Collide_2026-11-27_1345-00.md"
            occupied_min.write_text("# Keep 1\n", encoding="utf-8")
            occupied_sec.write_text("# Keep 2\n", encoding="utf-8")
            col_res = swr.save_report("Collide", "git", "w", "# New\n", archive_dir=arc, now=now)
            self.assertTrue(col_res["saved_path"].endswith("Collide_2026-11-27_1345-00-2.md"))
            self.assertEqual(occupied_min.read_text(encoding="utf-8"), "# Keep 1\n")
            self.assertEqual(occupied_sec.read_text(encoding="utf-8"), "# Keep 2\n")

            # Unowned INDEX.md must refuse overwrite.
            foreign_dir = arc / "foreign"
            foreign_dir.mkdir()
            (foreign_dir / "INDEX.md").write_text("# Existing Foreign Index\n", encoding="utf-8")
            with self.assertRaises(RuntimeError):
                swr.save_report("P", "git", "w", "# R\n", archive_dir=foreign_dir, now=now)

            # Dangling or linked INDEX.md symlink must be refused without creating external target.
            link_dir = arc / "linked"
            link_dir.mkdir()
            sibling_target = arc / "outside_INDEX.md"
            with patch.object(Path, "is_symlink", autospec=True, side_effect=lambda self: self.name == "INDEX.md"):
                with self.assertRaises(RuntimeError):
                    swr.save_report("P", "git", "w", "# R\n", archive_dir=link_dir, now=now)
            self.assertFalse(sibling_target.exists())
            try:
                (link_dir / "INDEX.md").symlink_to(sibling_target)
            except (OSError, NotImplementedError):
                pass
            else:
                with self.assertRaises(RuntimeError):
                    swr.save_report("P", "git", "w", "# R\n", archive_dir=link_dir, now=now)
                self.assertFalse(sibling_target.exists())

    def test_claude_tied_snapshots_are_order_invariant(self):
        tz = timezone.utc
        start = datetime(2026, 11, 20, tzinfo=tz)
        end = datetime(2026, 11, 27, tzinfo=tz)
        pricing = json.loads((SCRIPTS_DIR / "pricing.json").read_text(encoding="utf-8"))

        def make_row(uncached, cached, cwd):
            return json.dumps({
                "cwd": cwd,
                "timestamp": "2026-11-25T12:00:00+00:00",
                "requestId": "req-tie",
                "message": {"model": "claude-sonnet-4", "usage": {"input_tokens": uncached, "cache_read_input_tokens": cached, "output_tokens": 2000}},
            }) + "\n"

        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws = base / "TargetRepo"
            ws.mkdir()
            cdir = base / "claude" / "projects" / "p"
            cdir.mkdir(parents=True)
            (cdir / "a.jsonl").write_text(make_row(100_000, 0, ""), encoding="utf-8")
            (cdir / "b.jsonl").write_text(make_row(0, 100_000, str(ws)), encoding="utf-8")

            agg1 = ctu.ScopeAggregator(pricing)
            ws1 = ctu.ScopeAggregator(pricing)
            with patch.object(ctu.os, "walk", return_value=[(str(cdir), [], ["a.jsonl", "b.jsonl"])]):
                ctu.collect_claude_code(start, end, tz, ctu.normalize_path(str(ws)), base / "claude", ws1, agg1)

            agg2 = ctu.ScopeAggregator(pricing)
            ws2 = ctu.ScopeAggregator(pricing)
            with patch.object(ctu.os, "walk", return_value=[(str(cdir), [], ["b.jsonl", "a.jsonl"])]):
                ctu.collect_claude_code(start, end, tz, ctu.normalize_path(str(ws)), base / "claude", ws2, agg2)

            self.assertEqual(agg1.to_dict(), agg2.to_dict())
            self.assertEqual(ws1.to_dict(), ws2.to_dict())
            self.assertEqual(ws1.to_dict()["cached_input"], 100_000)


if __name__ == "__main__":
    unittest.main()

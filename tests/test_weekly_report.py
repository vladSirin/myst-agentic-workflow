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

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = ROOT / "plugins" / "myst-dev-kit" / "skills" / "weekly-report" / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import collect_token_usage as ctu  # noqa: E402
import collect_weekly_work as cww  # noqa: E402
import save_weekly_report as swr  # noqa: E402


class WeeklyReportTests(unittest.TestCase):
    def test_compute_window_rolling_hour_and_since_override(self):
        tz = timezone(timedelta(hours=8))
        now = datetime(2026, 11, 27, 13, 45, 12, tzinfo=tz)
        cutoff, end = cww.compute_window(days=7, now=now)
        self.assertEqual(cutoff, datetime(2026, 11, 20, 13, 0, 0, tzinfo=tz))
        self.assertEqual(end, now)

        cutoff_custom, _ = cww.compute_window(days=7, since="2026-11-25 09:30", now=now)
        self.assertEqual(cutoff_custom, datetime(2026, 11, 25, 9, 30, 0, tzinfo=tz))

    def test_detect_vcs_prefers_p4_when_uninitialized_git_present(self):
        with tempfile.TemporaryDirectory() as tmp:
            p4_probe = {"available": True, "bound": True}
            git_probe = {"available": True, "work_tree": True, "has_head": False, "has_remote": False}
            self.assertEqual(cww.detect_vcs(tmp, p4_probe, git_probe, "auto"), "p4")

            # Even with HEAD, .p4ignore marker selects p4 over secondary git.
            (Path(tmp) / ".p4ignore").write_text("Saved/\n", encoding="utf-8")
            git_probe_with_head = {"available": True, "work_tree": True, "has_head": True, "has_remote": True}
            self.assertEqual(cww.detect_vcs(tmp, p4_probe, git_probe_with_head, "auto"), "p4")

            # Without p4 binding, git work_tree selects git.
            self.assertEqual(cww.detect_vcs(tmp, {"available": True, "bound": False}, git_probe_with_head, "auto"), "git")

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

    def test_collect_git_end_to_end_on_temp_repo(self):
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

            # Unmerged feature branch ahead of main
            g("checkout", "-b", "feat/wip-branch")
            (repo / "b.txt").write_text("wip\n", encoding="utf-8")
            g("add", "b.txt")
            g("commit", "-m", "wip: branch work")

            g("checkout", "main")
            # Stash an edit, then leave a dirty file in working tree
            (repo / "a.txt").write_text("stashed\n", encoding="utf-8")
            g("stash", "push", "-m", "saved work")
            (repo / "dirty.txt").write_text("dirty\n", encoding="utf-8")

            cutoff, now_local = cww.compute_window(days=7)
            p4_probe = {"available": False, "bound": False}
            git_probe = cww.probe_git(str(repo))
            res = cww.collect_git(git_probe, str(repo), repo.name, "", cutoff, now_local, p4_probe)

            self.assertEqual(res["meta"]["vcs"], "git")
            self.assertEqual(res["counts"]["completed"], 1)
            self.assertEqual(res["completed"][0]["tags"], ["feat", "core"])
            self.assertEqual(res["completed"][0]["ticket"], "#12")
            kinds = {item["kind"] for item in res["wip_active"]}
            self.assertEqual(kinds, {"working_tree", "branch", "stash"})

    def test_collect_token_usage_across_three_hosts_and_override(self):
        tz = timezone(timedelta(hours=8))
        now = datetime(2026, 11, 27, 13, 0, 0, tzinfo=tz)
        since = now - timedelta(days=7)

        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws = base / "MyRepo"
            ws.mkdir()

            # 1. Antigravity synthetic transcript + summaries db
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

            # 2. Codex synthetic session with pre-window baseline + in-window delta
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

            # 3. Claude Code synthetic log with duplicate streaming requestId
            claude_dir = base / "claude" / "projects" / "proj"
            claude_dir.mkdir(parents=True)
            (claude_dir / "c1.jsonl").write_text(
                "\n".join([
                    json.dumps({
                        "cwd": str(ws),
                        "timestamp": (now - timedelta(hours=3)).isoformat(),
                        "requestId": "req-1",
                        "message": {"model": "claude-sonnet-4", "usage": {"input_tokens": 10_000, "cache_creation_input_tokens": 5_000, "cache_read_input_tokens": 50_000, "output_tokens": 1_000}},
                    }),
                    json.dumps({
                        "cwd": str(ws),
                        "timestamp": (now - timedelta(hours=3)).isoformat(),
                        "requestId": "req-1",
                        "message": {"model": "claude-sonnet-4", "usage": {"input_tokens": 10_000, "cache_creation_input_tokens": 5_000, "cache_read_input_tokens": 50_000, "output_tokens": 4_000}},
                    }),
                ]) + "\n",
                encoding="utf-8",
            )

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
            # AG: 100k + 900k + 10k; Codex delta: 100k uncached + 900k cached + 50k out; Claude (deduped): 15k uncached + 50k cached + 4k out
            self.assertEqual(ws_data["uncached_input"], 215_000)
            self.assertEqual(ws_data["cached_input"], 1_850_000)
            self.assertEqual(ws_data["output"], 64_000)
            self.assertEqual(ws_data["by_tool"]["claude_code"]["turns"], 1)
            self.assertGreater(ws_data["cache_savings_usd"], 0)
            self.assertEqual(res["efficiency"]["completed_count"], 2)

            # Pricing override resolution
            home_dir = base / "home"
            (home_dir / ".myst").mkdir(parents=True)
            override = home_dir / ".myst" / "weekly-report-pricing.json"
            override.write_text("{}", encoding="utf-8")
            self.assertEqual(ctu.resolve_pricing_path("", SCRIPTS_DIR, home_dir=home_dir), override)

    def test_save_weekly_report_prunes_old_and_builds_index(self):
        with tempfile.TemporaryDirectory() as tmp:
            arc = Path(tmp)
            now = datetime(2026, 11, 27, 13, 45, 0)
            expired = arc / "OldProj_2026-08-01_1000.md"
            expired.write_text("# Old\n", encoding="utf-8")
            old_ts = (now - timedelta(days=95)).timestamp()
            os.utime(expired, (old_ts, old_ts))

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
            self.assertEqual(res["retained_count"], 1)
            self.assertFalse(expired.exists())
            self.assertTrue(Path(res["saved_path"]).is_file())
            idx = Path(res["index_path"]).read_text(encoding="utf-8")
            self.assertIn("My-Project_2026-11-27_1345.md", idx)


if __name__ == "__main__":
    unittest.main()

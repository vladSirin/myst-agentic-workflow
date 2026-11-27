"""Unit tests for the weekly-report skill scripts."""

import io
import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from threading import Event
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

    def test_main_explicit_vcs_skips_unselected_probe(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = str(Path(tmp).resolve())
            timeout = subprocess.TimeoutExpired(cmd="unselected probe", timeout=1)
            for vcs, selected_probe, other_probe, selected_state, other_state, collector in (
                ("git", "probe_git", "probe_perforce", {"available": True, "work_tree": True},
                 {"available": False, "bound": False}, "collect_git"),
                ("p4", "probe_perforce", "probe_git", {"available": True, "bound": True},
                 {"available": False, "work_tree": False}, "collect_perforce"),
            ):
                with (
                    self.subTest(vcs=vcs),
                    patch.object(sys, "argv", ["collect_weekly_work.py", "--workspace", tmp, "--vcs", vcs]),
                    patch.object(sys, "stdout", io.StringIO()),
                    patch.object(cww, selected_probe, return_value=selected_state) as selected,
                    patch.object(cww, other_probe, side_effect=timeout) as unselected,
                    patch.object(cww, collector, return_value={}) as collect,
                ):
                    cww.main()
                    selected.assert_called_once_with(root)
                    unselected.assert_not_called()
                    collect.assert_called_once()
                    self.assertEqual(collect.call_args.args[-1], other_state)

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
                # Post-until pending CL must be classified into wip_after_window, not wip_active or wip_older.
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
        self.assertEqual([w["id"] for w in res["wip_older"]], [])
        self.assertEqual([w["id"] for w in res["wip_after_window"]], ["5125"])
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

        future_branches = [
            f"future-{i:02d}\t2026-11-24T08:00:00+00:00\tDev\tdev@example.com\tFuture {i}" for i in range(1, 21)
        ]
        pre_branch = "older-01\t2026-11-18T08:00:00+00:00\tDev\tdev@example.com\tOlder pre-window branch"

        def fake_future_and_capped(cmd, **kwargs):
            if "rev-parse" in cmd:
                return 0, ("a" * 40) + "\n", ""
            if "for-each-ref" in cmd:
                return 0, "\n".join([*future_branches, pre_branch]) + "\n", ""
            if "rev-list" in cmd and "--count" in cmd:
                return 0, "2\n", ""
            if "stash" in cmd:
                return 0, "stash@{0}\x1f2026-11-24T08:00:00+00:00\x1fAfter until\n", ""
            return 0, "", ""

        with patch.object(cww, "resolve_git_default_ref", return_value="main"), patch.object(cww, "run_cmd", side_effect=fake_future_and_capped):
            res = cww.collect_git({"has_head": True}, ".", "GitRepo", "", start, end, {})
        self.assertEqual(res["counts"]["wip_active"], 0)
        self.assertEqual(res["counts"]["wip_older"], 1)
        self.assertEqual(res["counts"]["wip_after_window"], 21)
        self.assertEqual(res["meta"]["vcs_details"]["older_unmerged_branches"], 1)
        self.assertEqual([w["id"] for w in res["wip_older"]], ["older-01"])
        after_ids = [w["id"] for w in res["wip_after_window"]]
        self.assertIn("stash@{0}", after_ids)
        self.assertIn("future-01", after_ids)
        self.assertIn("future-20", after_ids)

    def test_collect_perforce_mixed_wip_bounds_evidence_to_window_end(self):
        tz = timezone.utc
        cutoff = datetime(2026, 11, 16, 12, 0, tzinfo=tz)
        now_local = datetime(2026, 11, 23, 12, 0, tzinfo=tz)

        with tempfile.TemporaryDirectory() as tmp:
            ws = Path(tmp)
            pre_file = ws / "Pre.as"
            post_file = ws / "Post.as"
            pre_file.write_text("pre\n", encoding="utf-8")
            post_file.write_text("post\n", encoding="utf-8")
            pre_ts = datetime(2026, 11, 14, 10, 0, tzinfo=tz).timestamp()
            post_ts = datetime(2026, 11, 24, 10, 0, tzinfo=tz).timestamp()
            os.utime(pre_file, (pre_ts, pre_ts))
            os.utime(post_file, (post_ts, post_ts))

            def fake_p4(cmd, **kwargs):
                if "submitted" in cmd:
                    return 0, "", ""
                if "opened" in cmd:
                    return (
                        0,
                        "5130\tedit\t//ProjA/main/Post.as\t//wsA/Post.as\n"
                        "5130\tedit\t//ProjA/main/Undated.as\t//wsA/Undated.as\n"
                        "5130\tedit\t//ProjA/main/Pre.as\t//wsA/Pre.as\n",
                        "",
                    )
                if "pending" in cmd:
                    return 0, "5130\n", ""
                if "describe" in cmd and "-S" not in cmd:
                    return (
                        0,
                        "Change 5130 by u@wsA on 2026/11/12 09:00:00 *pending*\n\n"
                        "\t[design] Mixed pending\n\n"
                        "Affected files ...\n\n"
                        "... //ProjA/main/Post.as#1 edit\n"
                        "... //ProjA/main/Undated.as#1 edit\n"
                        "... //ProjA/main/Pre.as#1 edit\n",
                        "",
                    )
                if "describe" in cmd and "-S" in cmd:
                    return 0, "Shelved files ...\n\n... //ProjA/main/Shelf.as#1 edit\n", ""
                return 0, "", ""

            probe = {"user": "u", "client": "wsA", "client_root": str(ws), "client_stream": "//ProjA/main", "server_tz": tz, "server_offset_str": "+0000"}
            with patch.object(cww, "run_cmd", side_effect=fake_p4):
                res = cww.collect_perforce(probe, str(ws), "ProjA", "", cutoff, now_local, {})

        self.assertEqual(res["counts"]["wip_active"], 0)
        self.assertEqual(res["counts"]["wip_older"], 1)
        self.assertEqual(res["counts"]["wip_after_window"], 0)
        item = res["wip_older"][0]
        self.assertEqual(item["id"], "5130")
        self.assertEqual(item["cl_local_time"], "2026-11-12 09:00")
        self.assertEqual(item["latest_file_mtime"], "2026-11-14 10:00")
        self.assertEqual(item["last_touched_time"], "2026-11-14 10:00")
        self.assertEqual(item["bounded_opened_files_count"], 1)
        self.assertEqual(item["current_file_count"], 3)
        self.assertEqual(item["current_shelved_count"], 1)
        self.assertEqual(item["post_window_files_count"], 1)
        self.assertNotIn("file_count", item)
        self.assertNotIn("shelved_count", item)
        self.assertEqual(item["sample_files"], ["//ProjA/main/Pre.as"])
        self.assertEqual(item["current_shelved_sample_files"], ["//ProjA/main/Shelf.as"])

    def test_collect_git_mixed_working_tree_bounds_evidence_to_window_end(self):
        tz = timezone.utc
        start = datetime(2026, 11, 20, 0, 0, tzinfo=tz)
        end = datetime(2026, 11, 23, 0, 0, tzinfo=tz)

        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            pre_path = repo / "pre.txt"
            post_path = repo / "post.txt"
            pre_path.write_text("old\n", encoding="utf-8")
            post_path.write_text("later\n", encoding="utf-8")
            pre_ts = datetime(2026, 11, 18, 9, 0, tzinfo=tz).timestamp()
            post_ts = datetime(2026, 11, 24, 9, 0, tzinfo=tz).timestamp()
            os.utime(pre_path, (pre_ts, pre_ts))
            os.utime(post_path, (post_ts, post_ts))

            def fake_git(cmd, **kwargs):
                if "rev-parse" in cmd:
                    return 0, ("a" * 40) + "\n", ""
                if "status" in cmd:
                    self.assertEqual(cmd[-3:], ["--porcelain=v1", "-z", "-uall"])
                    # The literal arrow path is valid in Git output but cannot exist on Windows.
                    return 0, "?? pre.txt\x00?? post.txt\x00?? notes -> draft.txt\x00R  renamed.txt\x00old.txt\x00", ""
                return 0, "", ""

            probe = {"has_head": True, "branch": "main", "repo_root": str(repo), "remotes": []}
            with patch.object(cww, "resolve_git_default_ref", return_value="main"), patch.object(cww, "run_cmd", side_effect=fake_git):
                res = cww.collect_git(probe, str(repo), "GitRepo", "", start, end, {})

        self.assertEqual(res["counts"]["wip_active"], 0)
        self.assertEqual(res["counts"]["wip_older"], 1)
        self.assertEqual(res["counts"]["wip_after_window"], 1)
        self.assertEqual(res["counts"]["uncommitted_or_default"], 3)
        older = res["wip_older"][0]
        self.assertEqual(older["last_touched_time"], "2026-11-18 09:00")
        self.assertEqual(older["sample_files"], ["pre.txt", "notes -> draft.txt", "renamed.txt"])
        self.assertNotIn("post.txt", older["summary"])
        self.assertEqual(older["post_window_files_count"], 1)
        after = res["wip_after_window"][0]
        self.assertIn("[after-window]", after["id"])
        self.assertEqual(after["last_touched_time"], "2026-11-24 09:00")
        self.assertEqual(after["sample_files"], ["post.txt"])
        u = res["uncommitted_or_default"]
        self.assertEqual(u["modified_count"], 3)
        self.assertEqual(u["post_window_count"], 1)
        self.assertEqual(u["latest_file_mtime"], "2026-11-18 09:00")
        self.assertEqual(u["sample_files"], ["?? pre.txt", "?? notes -> draft.txt", "R renamed.txt"])

    def test_collect_git_uses_child_mtime_for_untracked_directory(self):
        start = datetime(2026, 11, 20, tzinfo=timezone.utc)
        end = datetime(2026, 11, 23, tzinfo=timezone.utc)
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            subprocess.run(["git", "init", "-b", "main"], cwd=repo, check=True, capture_output=True)
            folder = repo / "nested"
            folder.mkdir()
            child = folder / "post.txt"
            child.write_text("after the window\n", encoding="utf-8")
            post_ts = datetime(2026, 11, 24, 9, 0, tzinfo=timezone.utc).timestamp()
            os.utime(child, (post_ts, post_ts))
            os.utime(folder, (start.timestamp(), start.timestamp()))

            probe = cww.probe_git(str(repo))
            res = cww.collect_git(probe, str(repo), repo.name, "", start, end, {})

        self.assertEqual(res["uncommitted_or_default"]["modified_count"], 0)
        self.assertEqual(res["uncommitted_or_default"]["post_window_count"], 1)
        self.assertEqual(res["wip_after_window"][0]["sample_files"], ["nested/post.txt"])
        self.assertEqual(res["wip_after_window"][0]["last_touched_time"], "2026-11-24 09:00")

    def test_collect_git_reports_committer_time_for_commits_in_window(self):
        tz = timezone(timedelta(hours=8))
        start = datetime(2026, 11, 19, tzinfo=tz)
        end = datetime(2026, 11, 23, tzinfo=tz)
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            env = dict(
                os.environ, GIT_AUTHOR_NAME="Test User", GIT_AUTHOR_EMAIL="test@example.com",
                GIT_COMMITTER_NAME="Test User", GIT_COMMITTER_EMAIL="test@example.com",
                GIT_COMMITTER_DATE="2026-11-20T08:30:00+00:00",
            )

            def git(*args):
                return subprocess.check_output(["git", *args], cwd=repo, env=env, text=True).strip()

            git("init", "-b", "main")
            tree = git("write-tree")
            env["GIT_AUTHOR_DATE"] = "2026-11-01T08:30:00+00:00"
            first = git("commit-tree", tree, "-m", "Early author date")
            env["GIT_AUTHOR_DATE"] = "2026-11-25T08:30:00+00:00"
            second = git("commit-tree", tree, "-p", first, "-m", "Late author date")
            git("update-ref", "refs/heads/main", second)

            probe = cww.probe_git(str(repo))
            res = cww.collect_git(probe, str(repo), repo.name, "test@example.com", start, end, {})

        self.assertEqual(res["counts"]["completed"], 2)
        self.assertEqual(res["counts"]["completed_ids_returned"], 2)
        self.assertEqual(
            {item["title"]: item["local_time"] for item in res["completed"]},
            {"Early author date": "2026-11-20 16:30", "Late author date": "2026-11-20 16:30"},
        )

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
            self.assertEqual(res["efficiency"]["scope"], "workspace")

            home_dir = base / "home"
            (home_dir / ".myst").mkdir(parents=True)
            override = home_dir / ".myst" / "weekly-report-pricing.json"
            override.write_text("{}", encoding="utf-8")
            self.assertEqual(ctu.resolve_pricing_path("", SCRIPTS_DIR, home_dir=home_dir), override)

    def test_collect_all_usage_keeps_efficiency_within_selected_workspace(self):
        start = datetime(2026, 11, 20, tzinfo=timezone.utc)
        end = datetime(2026, 11, 23, tzinfo=timezone.utc)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            claude_root = root / "claude"
            claude_project = claude_root / "projects" / "other"
            claude_project.mkdir(parents=True)
            (claude_project / "session.jsonl").write_text(
                json.dumps({
                    "cwd": str(root / "OtherRepo"),
                    "timestamp": "2026-11-22T12:00:00+00:00",
                    "requestId": "req-other",
                    "message": {"model": "claude-sonnet-4", "usage": {"input_tokens": 120, "output_tokens": 20}},
                }) + "\n",
                encoding="utf-8",
            )
            options = {
                "since_dt": start, "until_dt": end,
                "pricing_path": SCRIPTS_DIR / "pricing.json", "completed_count": 2,
                "ag_root": root / "ag", "codex_root": root / "codex", "claude_root": claude_root,
            }
            scoped = ctu.collect_all_usage(workspace=str(root / "TargetRepo"), **options)
            unscoped = ctu.collect_all_usage(workspace="", **options)

        self.assertEqual(scoped["workspace"]["total_tokens"], 0)
        self.assertEqual(scoped["all_machine"]["total_tokens"], 140)
        self.assertIsNone(scoped["efficiency"])
        self.assertIsNone(unscoped["workspace"])
        self.assertEqual(unscoped["efficiency"]["scope"], "all_machine")
        self.assertEqual(unscoped["efficiency"]["tokens_per_deliverable"], 70)

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

            # Hard-linked backup of INDEX.md must retain original bytes across updates (atomic replace, no O_TRUNC).
            index_path = Path(res["index_path"])
            before_bytes = index_path.read_bytes()
            hardlink_backup = arc / "INDEX_hardlink_backup.md"
            os.link(index_path, hardlink_backup)
            swr.save_report("HardLinkCheck", "git", "w", "# HL\n", archive_dir=arc, now=now)
            self.assertEqual(hardlink_backup.read_bytes(), before_bytes)
            self.assertNotEqual(index_path.read_bytes(), before_bytes)
            hardlink_backup.unlink()

            # Concurrent first-time INDEX.md creation must fail with FileExistsError without overwriting the foreign file.
            race_dir = arc / "race_first"
            race_dir.mkdir()
            race_index = race_dir / "INDEX.md"
            real_link = swr.os.link

            def racing_link(src, dst):
                with race_index.open("x", encoding="utf-8") as fh:
                    fh.write("# Unrelated Race Index\n")
                real_link(src, dst)

            with patch.object(swr.os, "link", side_effect=racing_link):
                with self.assertRaises(FileExistsError):
                    swr.save_report("RaceProj", "git", "w", "# R\n", archive_dir=race_dir, now=now)
            self.assertEqual(race_index.read_text(encoding="utf-8"), "# Unrelated Race Index\n")
            self.assertEqual(list(race_dir.glob(".INDEX.*.tmp")), [])

            # Unowned INDEX.md must refuse overwrite.
            foreign_dir = arc / "foreign"
            foreign_dir.mkdir()
            (foreign_dir / "INDEX.md").write_text("# Existing Foreign Index\n", encoding="utf-8")
            with self.assertRaises(RuntimeError):
                swr.save_report("P", "git", "w", "# R\n", archive_dir=foreign_dir, now=now)

            # Dangling or linked INDEX.md symlink must be refused without creating external target.
            link_dir = arc / "linked"
            link_dir.mkdir()
            link_index = link_dir / "INDEX.md"
            sibling_target = arc / "outside_INDEX.md"
            link_index.touch()
            with patch.object(Path, "is_symlink", autospec=True, side_effect=lambda self: self.name == "INDEX.md"):
                with self.assertRaisesRegex(RuntimeError, "symlinked index"):
                    swr.save_report("P", "git", "w", "# R\n", archive_dir=link_dir, now=now)
            link_index.unlink()
            self.assertFalse(sibling_target.exists())
            try:
                link_index.symlink_to(sibling_target)
            except (OSError, NotImplementedError):
                pass
            else:
                with self.assertRaises(RuntimeError):
                    swr.save_report("P", "git", "w", "# R\n", archive_dir=link_dir, now=now)
                self.assertFalse(sibling_target.exists())

    def test_save_weekly_report_preserves_replacement_after_owned_index_disappears(self):
        with tempfile.TemporaryDirectory() as tmp:
            arc = Path(tmp)
            index_path = arc / "INDEX.md"
            index_path.write_text(f"{swr.INDEX_HEADER}\n", encoding="utf-8")
            real_fdopen = swr.os.fdopen
            real_link = swr.os.link
            unrelated_text = "# Unrelated Replacement\n"

            @contextmanager
            def remove_owned_index_after_write(*args, **kwargs):
                with real_fdopen(*args, **kwargs) as fh:
                    yield fh
                index_path.unlink()

            def racing_link(src, dst):
                with index_path.open("x", encoding="utf-8") as fh:
                    fh.write(unrelated_text)
                real_link(src, dst)

            with (
                patch.object(swr.os, "fdopen", side_effect=remove_owned_index_after_write),
                patch.object(swr.os, "link", side_effect=racing_link),
            ):
                with self.assertRaises(FileExistsError):
                    swr.save_report("P", "git", "w", "# R\n", archive_dir=arc)

            self.assertEqual(index_path.read_text(encoding="utf-8"), unrelated_text)
            self.assertEqual(list(arc.glob(".INDEX.*.tmp")), [])

    def test_save_weekly_report_retries_after_failed_first_index_write(self):
        real_fdopen = swr.os.fdopen
        real_link = swr.os.link
        for fallback in (False, True):
            with self.subTest(fallback=fallback), tempfile.TemporaryDirectory() as tmp:
                arc = Path(tmp)
                index_path = arc / "INDEX.md"

                @contextmanager
                def fail_index_write(*args, **kwargs):
                    with real_fdopen(*args, **kwargs) as fh:
                        if fallback and not index_path.exists():
                            yield fh
                            return
                        fh.write("# Partial index")
                        with patch.object(fh, "write", side_effect=OSError("index write failed")):
                            yield fh

                link_side_effect = NotImplementedError if fallback else real_link
                with patch.object(swr.os, "link", side_effect=link_side_effect):
                    with patch.object(swr.os, "fdopen", side_effect=fail_index_write):
                        with self.assertRaisesRegex(OSError, "index write failed"):
                            swr.save_report("P", "git", "w", "# R\n", archive_dir=arc)

                    self.assertFalse(index_path.exists())
                    self.assertEqual(list(arc.glob(".INDEX.*.tmp")), [])
                    result = swr.save_report("P", "git", "w", "# R\n", archive_dir=arc)

                index_text = index_path.read_text(encoding="utf-8")
                self.assertEqual(index_text.splitlines()[0], swr.INDEX_HEADER)
                self.assertIn(Path(result["saved_path"]).name, index_text)
                self.assertEqual(list(arc.glob(".INDEX.*.tmp")), [])

    def test_save_weekly_report_serializes_concurrent_index_updates(self):
        with tempfile.TemporaryDirectory() as tmp:
            arc = Path(tmp)
            index_path = arc / "INDEX.md"
            index_path.write_text(f"{swr.INDEX_HEADER}\n", encoding="utf-8")
            lock_path = arc / ".weekly-report.lock"
            first_at_publish = Event()
            second_waiting = Event()
            release_first = Event()
            real_open = swr.os.open
            real_replace = swr.os.replace

            def observe_lock(path, *args, **kwargs):
                try:
                    return real_open(path, *args, **kwargs)
                except FileExistsError:
                    if Path(path) == lock_path:
                        second_waiting.set()
                    raise

            def pause_first_publish(src, dst):
                if not first_at_publish.is_set():
                    first_at_publish.set()
                    self.assertTrue(release_first.wait(5), "First save was not released")
                real_replace(src, dst)

            with (
                patch.object(swr.os, "open", side_effect=observe_lock),
                patch.object(swr.os, "replace", side_effect=pause_first_publish),
                ThreadPoolExecutor(max_workers=2) as pool,
            ):
                first = pool.submit(swr.save_report, "First", "git", "w", "# Report\n", archive_dir=arc)
                try:
                    self.assertTrue(first_at_publish.wait(5), "First save did not reach publication")
                    second = pool.submit(swr.save_report, "Second", "git", "w", "# Report\n", archive_dir=arc)
                    self.assertTrue(second_waiting.wait(5), "Second save did not wait for the lock")
                    self.assertEqual(list(arc.glob("Second_*.md")), [])
                finally:
                    release_first.set()
                saved_names = [Path(job.result(timeout=5)["saved_path"]).name for job in (first, second)]

            index_text = index_path.read_text(encoding="utf-8")
            self.assertIn("**Retained Reports:** 2", index_text)
            for name in saved_names:
                self.assertIn(f"[{name}](./{name})", index_text)
            self.assertFalse(lock_path.exists())

    def test_save_weekly_report_removes_new_report_when_publication_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            arc = Path(tmp)
            index_path = arc / "INDEX.md"
            original_index = f"{swr.INDEX_HEADER}\n"
            index_path.write_text(original_index, encoding="utf-8")

            def fail_publication(src, dst):
                self.assertEqual(Path(dst), index_path)
                self.assertEqual(len(list(arc.glob("Project_*.md"))), 1)
                raise PermissionError("cannot publish index")

            with patch.object(swr.os, "replace", side_effect=fail_publication):
                with self.assertRaisesRegex(PermissionError, "cannot publish index"):
                    swr.save_report("Project", "git", "w", "# Report\n", archive_dir=arc)

            self.assertEqual(list(arc.glob("Project_*.md")), [])
            self.assertEqual(list(arc.glob(".INDEX.*.tmp")), [])
            self.assertEqual(index_path.read_text(encoding="utf-8"), original_index)
            self.assertFalse((arc / ".weekly-report.lock").exists())

            result = swr.save_report("Project", "git", "w", "# Report\n", archive_dir=arc)
            report = Path(result["saved_path"])
            self.assertEqual(list(arc.glob("Project_*.md")), [report])
            self.assertEqual(result["retained_count"], 1)
            self.assertIn(report.name, index_path.read_text(encoding="utf-8"))

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

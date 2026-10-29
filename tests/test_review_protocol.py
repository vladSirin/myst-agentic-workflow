"""Executable fixture checks and negative controls for the probe scorer."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "fixtures/review-protocol"


class FixtureTests(unittest.TestCase):
    def run_contract(self, source):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "queue_api.py"
            path.write_text(source, encoding="utf-8")
            return subprocess.run(
                [sys.executable, "-c", "from queue_api import *; "
                 "assert can_enqueue(current_jobs=2, capacity=2) is False; "
                 "assert can_enqueue(current_jobs=2, capacity=3) is True; "
                 "assert can_enqueue(current_jobs=0, capacity=0) is False; "
                 "assert is_closed(capacity=0) is True; "
                 "assert is_closed(capacity=3) is False"],
                cwd=directory, capture_output=True, text=True, check=False)

    def test_seeded_boundary_defect_fails_real_contract(self):
        result = self.run_contract((FIXTURES / "seeded/queue_api.py").read_text())
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("AssertionError", result.stderr)

    def test_boundary_repair_passes_real_contract(self):
        source = (FIXTURES / "seeded/queue_api.py").read_text().replace("<=", "<")
        self.assertEqual(self.run_contract(source).returncode, 0)

    def test_clean_public_api_passes(self):
        self.assertEqual(self.run_contract((FIXTURES / "clean/queue_api.py").read_text()).returncode, 0)

    def test_false_alarm_prescription_breaks_keyword_callers(self):
        source = (FIXTURES / "clean/queue_api.py").read_text()
        result = self.run_contract(source.replace("current_jobs", "n").replace("capacity", "c"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unexpected keyword argument", result.stderr)


class ProbeScorerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location("probe_scorer", ROOT / "tools/check_review_probes.py")
        cls.scorer = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.scorer)

    def assert_rejected(self, case, action, axes, next_round, blockers, publish=False):
        self.assertTrue(self.scorer.check_case({"id": case, "action": action,
                                              "next_axes": axes, "next_round": next_round,
                                              "blockers": blockers, "publish": publish}))

    def test_unsupported_blocker_cannot_drive_a_fix(self):
        self.assert_rejected("unsupported", "fix", ["Standards"], 2, ["N1"])

    def test_complete_but_false_evidence_cannot_drive_harmful_fix(self):
        self.assert_rejected("false-alarm", "fix", ["Standards"], 2, ["N1"])

    def test_static_evidence_does_not_need_runtime_reproduction(self):
        self.assert_rejected("static", "request_evidence", ["Spec"], 2, ["Q1"])

    def test_unaffected_axis_is_not_dispatched(self):
        self.assert_rejected("runtime", "fix", ["Standards", "Spec"], 2, ["Q1"])

    def test_main_session_tests_do_not_clear_reviewer_blocker(self):
        self.assert_rejected("fixed", "re_review", ["Spec"], 2, [])

    def test_parallel_axes_count_as_one_cycle(self):
        self.assert_rejected("round-two", "human_decision", [], None, ["Q2"])

    def test_third_round_does_not_dispatch_fourth(self):
        self.assert_rejected("round-three", "fix", ["Spec"], 4, ["Q2"])

    def test_budget_does_not_clear_remaining_blocker(self):
        self.assert_rejected("round-three", "human_decision", [], None, [])

    def test_no_blocker_round_stops_automatic_warning_fixes(self):
        self.assert_rejected("last-round", "fix", ["Standards"], 3, [])

    def test_repeated_decline_escalates_before_budget(self):
        self.assert_rejected("declined", "re_review", ["Standards"], 3, ["N2"])

    def test_resumed_renamed_changeset_cannot_reset_budget(self):
        self.assert_rejected("resumed", "fix", ["Standards"], 1, ["N3"])

    def test_clear_review_after_fix_still_requires_approval(self):
        self.assert_rejected("after-fix-green", "stop_for_approval", [], None, [], True)

    def test_bounded_continuation_retains_counter(self):
        self.assert_rejected("continuation", "fix", ["Spec"], 1, ["Q2"])

    def test_continuation_does_not_authorize_publication(self):
        self.assert_rejected("continuation", "fix", ["Spec"], 4, ["Q2"], True)

    def test_missing_duplicate_unknown_and_malformed_results_fail(self):
        for results in ([], {}, [None], [{"id": "absent"}], [{"id": []}],
                        [{"id": "fixed"}, {"id": "fixed"}]):
            with self.subTest(results=results):
                self.assertTrue(self.scorer.check_results(results))

    def test_cli_accepts_valid_decisions(self):
        result = subprocess.run(
            [sys.executable, str(ROOT / "tools/check_review_probes.py"),
             str(FIXTURES / "valid-decisions.json")],
            capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("PASS:", result.stdout)

    def test_cli_rejects_duplicate_in_complete_valid_receipt(self):
        results = json.loads((FIXTURES / "valid-decisions.json").read_text(encoding="utf-8"))
        results.append(next(dict(item) for item in results if item["id"] == "runtime"))
        self.assertEqual(self.scorer.check_results(results), ["duplicate case: runtime"])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "results.json"
            path.write_text(json.dumps(results), encoding="utf-8")
            result = subprocess.run([sys.executable, str(ROOT / "tools/check_review_probes.py"), str(path)],
                                    capture_output=True, text=True, check=False)
            self.assertEqual(result.returncode, 1)
            self.assertIn("duplicate case: runtime", result.stderr)

    def test_cli_rejects_unsafe_output_with_nonzero_exit(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "results.json"
            path.write_text(json.dumps([{"id": "round-three", "action": "fix",
                                         "next_axes": ["Spec"], "next_round": 4,
                                         "blockers": [], "publish": True}]), encoding="utf-8")
            result = subprocess.run([sys.executable, str(ROOT / "tools/check_review_probes.py"), str(path)],
                                    capture_output=True, text=True, check=False)
            self.assertEqual(result.returncode, 1)
            self.assertIn("round-three.action", result.stderr)
            self.assertIn("round-three.publish", result.stderr)


if __name__ == "__main__":
    unittest.main()

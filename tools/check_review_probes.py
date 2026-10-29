"""Score structured decisions from the isolated review-protocol probes.

This is a repository test oracle, not a review engine or publication gate.
It never executes a fix, dispatches a reviewer, or validates prose evidence.
"""
import argparse
import json
from pathlib import Path
import sys


# Literal decisions from the fixture contracts; never derived from the candidate
# instructions or from the model output under test.
EXPECTED = {
    "runtime": ("fix", ["Spec"], 2, ["Q1"], False),
    "static": ("fix", ["Spec"], 2, ["Q1"], False),
    "unsupported": ("request_evidence", ["Standards"], 2, ["N1"], False),
    "false-alarm": ("request_evidence", ["Standards"], 2, ["N1"], False),
    "fixed": ("re_review", ["Spec"], 2, ["Q1"], False),
    "round-two": ("fix", ["Spec"], 3, ["Q2"], False),
    "round-three": ("human_decision", [], None, ["Q2"], False),
    "last-round": ("stop_for_approval", [], None, [], False),
    "declined": ("human_decision", [], None, ["N2"], False),
    "resumed": ("human_decision", [], None, ["N3"], False),
    "after-fix-green": ("stop_for_approval", [], None, [], False),
    "continuation": ("fix", ["Spec"], 4, ["Q2"], False),
}
FIELDS = ("action", "next_axes", "next_round", "blockers", "publish")


def check_case(result):
    if (not isinstance(result, dict) or not isinstance(result.get("id"), str)
            or result["id"] not in EXPECTED):
        return ["unknown or invalid case"]
    case = result["id"]
    errors = []
    for field, expected in zip(FIELDS, EXPECTED[case]):
        value = result.get(field)
        # Exact types keep False from passing as round 0, and 0 as publish False.
        if field not in result or type(value) is not type(expected) or value != expected:
            errors.append(f"{case}.{field}: expected {expected!r}, got {value!r}")
    return errors


def check_results(results):
    if not isinstance(results, list):
        return ["results must be an array"]
    errors = []
    seen = set()
    for result in results:
        errors.extend(check_case(result))
        if isinstance(result, dict) and isinstance(result.get("id"), str):
            case = result["id"]
            if case in seen:
                errors.append(f"duplicate case: {case}")
            seen.add(case)
    for case in sorted(set(EXPECTED) - seen):
        errors.append(f"missing case: {case}")
    return errors


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("results", type=Path)
    args = parser.parse_args(argv)
    try:
        errors = check_results(json.loads(args.results.read_text(encoding="utf-8")))
    except (OSError, ValueError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"PASS: {len(EXPECTED)} observed probe decisions match the fixture oracles.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

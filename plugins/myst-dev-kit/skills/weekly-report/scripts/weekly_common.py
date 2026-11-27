#!/usr/bin/env python3
"""Shared date/window and path utilities for weekly-report scripts."""

import os
import re
from datetime import datetime, timedelta
from urllib.parse import unquote, urlparse


def parse_dt(value: str, local_tz) -> datetime:
    s = value.strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        dt = None
        for fmt in ("%m/%d/%Y %H:%M:%S", "%m/%d/%Y %H:%M", "%Y/%m/%d %H:%M:%S", "%Y/%m/%d %H:%M"):
            try:
                dt = datetime.strptime(s, fmt)
                break
            except ValueError:
                continue
        if dt is None:
            raise
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=local_tz)
    return dt.astimezone(local_tz)


def compute_window(
    days: int = 7,
    since: str = "",
    until: str = "",
    now: datetime | None = None,
) -> tuple[datetime, datetime]:
    now_local = now if now is not None else datetime.now().astimezone()
    local_tz = now_local.tzinfo
    until_dt = parse_dt(until, local_tz) if until else now_local
    if since:
        since_dt = parse_dt(since, local_tz)
    else:
        lookback = days if days > 0 else 7
        current_hour = now_local.replace(minute=0, second=0, microsecond=0)
        since_dt = current_hour - timedelta(days=lookback)
    return since_dt, until_dt


def normalize_path(p: str) -> str:
    if not p:
        return ""
    s = p.strip().strip('"').strip("'")
    if s.lower().startswith("file://"):
        parsed = urlparse(s)
        path_part = unquote(parsed.path or "")
        if re.match(r"^/[a-zA-Z]:", path_part):
            path_part = path_part[1:]
        s = path_part
    else:
        s = unquote(s)
    return os.path.normcase(os.path.normpath(s)).rstrip("\\/")


def is_same_or_subpath(child: str, parent: str) -> bool:
    c = normalize_path(child)
    p = normalize_path(parent)
    if not c or not p:
        return False
    return c == p or c.startswith(p + os.sep)

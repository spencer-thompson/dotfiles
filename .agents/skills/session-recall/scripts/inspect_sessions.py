"""Inspect explicitly selected Codex rollout JSONL files."""

from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
from collections import Counter
from datetime import date, datetime, time, timedelta
from pathlib import Path
from typing import Any

INJECTED_PREFIXES = (
    "# agents.md instructions",
    "<agents.md",
    "<apps_instructions",
    "<collaboration_mode",
    "<codex_internal_context",
    "<environment_context",
    "<permissions instructions",
    "<plugins_instructions",
    "<recommended_plugins",
    "<skill>",
    "<skills_instructions",
)
SENSITIVE_ASSIGNMENT = re.compile(
    r"(?i)\b(api[ _-]?key|authorization|bearer|password|secret|token)\b"
    r"(\s*[:=]\s*)['\"]?[^\s,'\"}]+"
)
SENSITIVE_TOKEN = re.compile(
    r"\b(?:ctx7sk-|sk-|github_pat_|gh[pousr]_|xox[baprs]-)[A-Za-z0-9._-]{8,}\b"
    r"|\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"
    r"|\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b"
)
ENV_ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
EVENT_KINDS = ("user", "assistant", "tool", "tool_output", "command", "file_change", "mcp", "turn", "compaction")
TOKEN_FIELDS = (
    "input_tokens",
    "cached_input_tokens",
    "cache_write_input_tokens",
    "output_tokens",
    "reasoning_output_tokens",
    "total_tokens",
)
SUMMARY_SORT_FIELDS = {
    "activity": "last_event_at",
    "bytes": "rollout_bytes",
    "commands": "command_executions",
    "duration": "active_duration_ms",
    "events": "activity_events",
    "file-changes": "file_change_events",
    "messages": "visible_messages",
    "tokens": "total_tokens",
    "tools": "tool_calls",
    "user-messages": "user_messages",
}
SUMMARY_FIELDS = (
    "kind",
    "path",
    "session_id",
    "sessions",
    "first_event_at",
    "last_event_at",
    "rollout_bytes",
    "records_in_range",
    "malformed_lines",
    "activity_events",
    "user_messages",
    "assistant_messages",
    "visible_messages",
    "tool_calls",
    "tools",
    "tools_truncated",
    "tools_distinct",
    "tool_calls_omitted",
    "completed_turns",
    "aborted_turns",
    "active_duration_ms",
    "average_time_to_first_token_ms",
    "command_executions",
    "command_successes",
    "command_failures",
    "command_duration_ms",
    "command_families",
    "command_families_truncated",
    "command_families_distinct",
    "command_executions_omitted",
    "file_change_events",
    "files_changed",
    "mcp_calls",
    "mcp_failures",
    "mcp_duration_ms",
    "mcp_tools",
    "mcp_tools_truncated",
    "mcp_tools_distinct",
    "mcp_calls_omitted",
    "compactions",
    "image_inputs",
    "audio_inputs",
    "replayed_events",
    "model_context_window",
    "token_snapshots_in_range",
    "token_delta_complete",
    *TOKEN_FIELDS,
    "models",
    "reasoning_efforts",
)
SUMMARY_COMPACT_FIELDS = (
    "kind",
    "sessions",
    "session_id",
    "first_event_at",
    "last_event_at",
    "records_in_range",
    "malformed_lines",
    "replayed_events",
    "user_messages",
    "assistant_messages",
    "activity_events",
    "completed_turns",
    "aborted_turns",
    "active_duration_ms",
    "total_tokens",
    "token_snapshots_in_range",
    "token_delta_complete",
    "tool_calls",
    "tools",
    "tools_truncated",
    "tools_distinct",
    "tool_calls_omitted",
    "command_executions",
    "command_failures",
    "command_families",
    "command_families_truncated",
    "command_families_distinct",
    "command_executions_omitted",
    "file_change_events",
    "files_changed",
    "mcp_calls",
    "mcp_failures",
    "mcp_tools",
    "mcp_tools_truncated",
    "mcp_tools_distinct",
    "mcp_calls_omitted",
    "compactions",
    "models",
    "reasoning_efforts",
    "path",
)


def parse_boundary(value: str, *, end: bool) -> tuple[float, bool]:
    """Parse an ISO timestamp or local date into an epoch boundary."""
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        parsed = datetime.combine(date.fromisoformat(value), time.min).astimezone()
        if end:
            return (parsed + timedelta(days=1)).timestamp(), False
        return parsed.timestamp(), True

    normalized = value[:-1] + "+00:00" if value.endswith("Z") else value
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        parsed = parsed.astimezone()
    return parsed.timestamp(), True


def render_text(
    text: str,
    max_chars: int,
    *,
    redact: bool = True,
    compact: bool = False,
) -> str:
    """Redact and optionally truncate visible text."""
    visible = " ".join(text.split()) if compact else text.strip()
    if redact:
        visible = SENSITIVE_ASSIGNMENT.sub(r"\1\2[REDACTED]", visible)
        visible = SENSITIVE_TOKEN.sub("[REDACTED]", visible)
    if max_chars == 0 or len(visible) <= max_chars:
        return visible
    return f"{visible[: max(0, max_chars - 1)]}…"


def text_content(payload: dict[str, Any]) -> str:
    content = payload.get("content")
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return " ".join(item["text"] for item in content if isinstance(item, dict) and isinstance(item.get("text"), str))


def is_injected(text: str) -> bool:
    return text.lstrip().lower().startswith(INJECTED_PREFIXES)


def _timestamp(value: Any) -> float | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def _in_range(timestamp: float | None, since: float | None, until: tuple[float, bool] | None) -> bool:
    if timestamp is None:
        return since is None and until is None
    if since is not None and timestamp < since:
        return False
    if until is None:
        return True
    value, inclusive = until
    return timestamp < value or inclusive and timestamp == value


def _stable_id(payload: dict[str, Any], kind: str) -> str:
    for key in ("call_id", "id", "turn_id"):
        value = payload.get(key)
        if isinstance(value, (str, int)) and value != "":
            return f"{kind}:{value}"
    return ""


def _tool_input(payload: dict[str, Any]) -> Any:
    return payload["input"] if "input" in payload else payload.get("arguments")


def _duration_ms(value: Any) -> int:
    if isinstance(value, (int, float)):
        return max(0, round(value))
    if not isinstance(value, dict):
        return 0
    seconds = value.get("secs", 0)
    nanos = value.get("nanos", 0)
    if not isinstance(seconds, (int, float)) or not isinstance(nanos, (int, float)):
        return 0
    return max(0, round(seconds * 1000 + nanos / 1_000_000))


def _command_family(command: Any) -> str:
    if isinstance(command, list) and command and all(isinstance(part, str) for part in command):
        executable = Path(command[0]).name
        if executable in {"bash", "sh", "zsh"} and len(command) >= 3 and command[1] in {"-c", "-lc"}:
            command = command[2]
        else:
            return executable
    if not isinstance(command, str) or not command.strip():
        return ""
    try:
        tokens = shlex.split(command, comments=False, posix=True)
    except ValueError:
        tokens = command.split()
    index = 1 if tokens and tokens[0] == "env" else 0
    while index < len(tokens) and ENV_ASSIGNMENT.match(tokens[index]):
        index += 1
    if index >= len(tokens):
        return ""
    executable = Path(tokens[index]).name
    return "" if executable in {"const", "for", "if", "set", "while"} else executable


def resolve_paths(paths: list[Path], *, paths_from_stdin: bool = False) -> list[Path]:
    """Resolve explicit rollout files without directory discovery."""
    candidates = list(paths)
    if paths_from_stdin:
        candidates.extend(Path(line) for line in sys.stdin.read().splitlines() if line.strip())
    if not candidates:
        raise SystemExit("provide one or more rollout paths, or use --paths-from-stdin")

    resolved: list[Path] = []
    seen: set[Path] = set()
    for candidate in candidates:
        path = candidate.expanduser().resolve()
        if not path.is_file():
            raise SystemExit(f"rollout is not a file: {path}")
        if path not in seen:
            seen.add(path)
            resolved.append(path)
    return resolved


def _rollout_identity(path: Path) -> tuple[float, str]:
    try:
        with path.open(encoding="utf-8", errors="replace") as stream:
            for line in stream:
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(record, dict) or record.get("type") != "session_meta":
                    continue
                payload = record.get("payload")
                if not isinstance(payload, dict):
                    payload = {}
                timestamp = _timestamp(record.get("timestamp") or payload.get("timestamp"))
                session_id = str(payload.get("id") or payload.get("session_id") or path)
                return timestamp or path.stat().st_mtime, session_id
    except OSError:
        pass
    return path.stat().st_mtime, str(path)


def _normalized_event(
    path: Path,
    line_number: int,
    record: dict[str, Any],
    *,
    max_chars: int,
    redact: bool,
) -> dict[str, Any] | None:
    payload = record.get("payload")
    if not isinstance(payload, dict):
        payload = {}
    record_type = record.get("type")
    payload_type = payload.get("type")
    base = {"path": str(path), "line": line_number, "timestamp": record.get("timestamp", "")}

    if record_type == "response_item" and payload_type == "message":
        role = payload.get("role")
        if role not in {"user", "assistant"}:
            return None
        message = text_content(payload)
        if not message or role == "user" and is_injected(message):
            return None
        return {
            **base,
            "kind": role,
            "preview": render_text(message, max_chars, redact=redact),
            "_event_id": _stable_id(payload, role),
        }

    if record_type == "response_item" and payload_type in {"custom_tool_call", "function_call"}:
        name = payload.get("name")
        if not isinstance(name, str) or not name:
            return None
        event = {**base, "kind": "tool", "tool": name, "_event_id": _stable_id(payload, "tool")}
        if not redact:
            event["input"] = _tool_input(payload)
        return event

    if record_type == "response_item" and payload_type in {"custom_tool_call_output", "function_call_output"}:
        event = {**base, "kind": "tool_output", "_event_id": _stable_id(payload, "tool_output")}
        if not redact:
            event["output"] = payload.get("output")
        return event

    if record_type == "compacted":
        message = payload.get("message") or record.get("message")
        event = {**base, "kind": "compaction", "_event_id": _stable_id(payload, "compaction")}
        if isinstance(message, str) and message:
            event["preview"] = render_text(message, max_chars, redact=redact)
        return event

    if record_type != "event_msg":
        return None

    if payload_type in {"task_complete", "turn_aborted"}:
        event = {
            **base,
            "kind": "turn",
            "status": "completed" if payload_type == "task_complete" else "aborted",
            "duration_ms": int(payload.get("duration_ms") or 0),
            "_event_id": _stable_id(payload, "turn"),
        }
        if payload_type == "task_complete" and isinstance(payload.get("time_to_first_token_ms"), (int, float)):
            event["time_to_first_token_ms"] = round(payload["time_to_first_token_ms"])
        if payload_type == "turn_aborted" and payload.get("reason"):
            event["reason"] = payload["reason"]
        return event

    if payload_type != "item_completed" or not isinstance(payload.get("item"), dict):
        return None
    item = payload["item"]
    item_type = item.get("type")
    if item_type == "CommandExecution":
        command = item.get("command")
        event = {
            **base,
            "kind": "command",
            "command_family": _command_family(command),
            "status": item.get("status", ""),
            "exit_code": item.get("exit_code"),
            "duration_ms": _duration_ms(item.get("duration")),
            "_event_id": _stable_id(item, "command"),
        }
        if not redact:
            event["command"] = command
        return event
    if item_type == "FileChange":
        changes = item.get("changes") if isinstance(item.get("changes"), (dict, list)) else []
        event = {
            **base,
            "kind": "file_change",
            "changes": len(changes),
            "status": item.get("status", ""),
            "_event_id": _stable_id(item, "file_change"),
        }
        if not redact:
            event["details"] = changes
        return event
    if item_type == "McpToolCall":
        event = {
            **base,
            "kind": "mcp",
            "server": item.get("server", ""),
            "tool": item.get("tool", ""),
            "app": item.get("appName", ""),
            "status": item.get("status", ""),
            "duration_ms": _duration_ms(item.get("duration")),
            "read_only": item.get("readOnlyHint"),
            "_event_id": _stable_id(item, "mcp"),
        }
        if not redact:
            event["arguments"] = item.get("arguments")
            event["result"] = item.get("result")
        return event
    return None


def extract_events(
    paths: list[Path],
    *,
    kinds: set[str] | None = None,
    since: str | None = None,
    until: str | None = None,
    max_chars: int = 600,
    redact: bool = True,
    patterns: list[re.Pattern[str]] | None = None,
    line_range: tuple[int | None, int | None] = (None, None),
    dedupe: bool = True,
) -> list[dict[str, Any]]:
    """Extract filtered events from explicit rollout paths."""
    selected_kinds = kinds or set(EVENT_KINDS)
    since_value = parse_boundary(since, end=False)[0] if since else None
    until_value = parse_boundary(until, end=True) if until else None
    start_line, end_line = line_range
    seen: set[str] = set()
    events: list[dict[str, Any]] = []

    for path in sorted(paths, key=_rollout_identity):
        with path.open(encoding="utf-8", errors="replace") as stream:
            for line_number, line in enumerate(stream, start=1):
                if (
                    start_line is not None
                    and line_number < start_line
                    or end_line is not None
                    and line_number > end_line
                ):
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(record, dict) or not _in_range(
                    _timestamp(record.get("timestamp")), since_value, until_value
                ):
                    continue
                event = _normalized_event(path, line_number, record, max_chars=max_chars, redact=redact)
                if event is None or event["kind"] not in selected_kinds:
                    continue
                event_id = str(event.pop("_event_id", ""))
                if dedupe and event_id:
                    if event_id in seen:
                        continue
                    seen.add(event_id)
                if patterns:
                    visible = json.dumps(
                        {key: value for key, value in event.items() if key not in {"path", "line", "timestamp"}},
                        ensure_ascii=False,
                        sort_keys=True,
                    )
                    if not any(pattern.search(visible) for pattern in patterns):
                        continue
                events.append(event)
    return events


def parse_line_range(value: str | None) -> tuple[int | None, int | None]:
    if value is None:
        return None, None
    start_text, separator, end_text = value.partition(":")
    if not separator:
        start_text = end_text = value
    try:
        start = int(start_text) if start_text else None
        end = int(end_text) if end_text else None
    except ValueError as error:
        raise ValueError("line range bounds must be integers") from error
    if start is not None and start < 1 or end is not None and end < 1:
        raise ValueError("line range bounds must be positive")
    if start is not None and end is not None and start > end:
        raise ValueError("line range start must not exceed its end")
    return start, end


def _mark(summary: dict[str, Any], payload: dict[str, Any], kind: str, seen: set[str] | None) -> bool:
    event_id = _stable_id(payload, kind)
    if seen is not None and event_id:
        if event_id in seen:
            summary["replayed_events"] += 1
            return False
        seen.add(event_id)
    summary["activity_events"] += 1
    return True


def _empty_summary(path: Path) -> dict[str, Any]:
    return {
        "kind": "rollout_summary",
        "path": str(path),
        "session_id": "",
        "sessions": 1,
        "first_event_at": "",
        "last_event_at": "",
        "rollout_bytes": path.stat().st_size,
        "records_in_range": 0,
        "malformed_lines": 0,
        "activity_events": 0,
        "user_messages": 0,
        "assistant_messages": 0,
        "visible_messages": 0,
        "tool_calls": 0,
        "completed_turns": 0,
        "aborted_turns": 0,
        "active_duration_ms": 0,
        "average_time_to_first_token_ms": 0,
        "command_executions": 0,
        "command_successes": 0,
        "command_failures": 0,
        "command_duration_ms": 0,
        "file_change_events": 0,
        "files_changed": 0,
        "mcp_calls": 0,
        "mcp_failures": 0,
        "mcp_duration_ms": 0,
        "compactions": 0,
        "image_inputs": 0,
        "audio_inputs": 0,
        "replayed_events": 0,
        "model_context_window": 0,
        "token_snapshots_in_range": 0,
        "token_delta_complete": True,
        **{field: 0 for field in TOKEN_FIELDS},
        "_tools": Counter(),
        "_command_families": Counter(),
        "_mcp_tools": Counter(),
        "_files": set(),
        "_models": set(),
        "_efforts": set(),
        "_ttft_total_ms": 0,
        "_ttft_samples": 0,
    }


def _update_event_bounds(summary: dict[str, Any], timestamp: Any) -> None:
    if not isinstance(timestamp, str) or not timestamp:
        return
    if not summary["first_event_at"]:
        summary["first_event_at"] = timestamp
    summary["last_event_at"] = timestamp


def _paths_from_changes(value: Any) -> set[str]:
    paths: set[str] = set()
    if isinstance(value, dict):
        for key, child in value.items():
            if key in {"path", "file_path"} and isinstance(child, str):
                paths.add(child)
            elif isinstance(key, str) and ("/" in key or key.startswith(".")):
                paths.add(key)
            if isinstance(child, (dict, list)):
                paths.update(_paths_from_changes(child))
    elif isinstance(value, list):
        for child in value:
            paths.update(_paths_from_changes(child))
    return paths


def summarize_rollout(
    path: Path,
    *,
    since: str | None = None,
    until: str | None = None,
    seen: set[str] | None = None,
) -> dict[str, Any]:
    """Summarize current JSONL evidence inside an exact event range."""
    since_value = parse_boundary(since, end=False)[0] if since else None
    until_value = parse_boundary(until, end=True) if until else None
    summary = _empty_summary(path)
    token_baseline = {field: 0 for field in TOKEN_FIELDS}
    token_final: dict[str, int] | None = None
    token_baseline_seen = since_value is None
    session_started_at: float | None = None

    with path.open(encoding="utf-8", errors="replace") as stream:
        for line in stream:
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                summary["malformed_lines"] += 1
                continue
            if not isinstance(record, dict):
                continue
            payload = record.get("payload")
            if not isinstance(payload, dict):
                payload = {}
            record_type = record.get("type")
            payload_type = payload.get("type")
            timestamp_text = record.get("timestamp")
            timestamp = _timestamp(timestamp_text)

            if record_type == "session_meta":
                summary["session_id"] = str(payload.get("id") or payload.get("session_id") or "")
                session_started_at = timestamp

            if record_type == "event_msg" and payload_type == "token_count":
                info = payload.get("info")
                if isinstance(info, dict) and isinstance(info.get("total_token_usage"), dict):
                    totals = {field: int(info["total_token_usage"].get(field) or 0) for field in TOKEN_FIELDS}
                    if since_value is not None and timestamp is not None and timestamp < since_value:
                        token_baseline = totals
                        token_baseline_seen = True
                    elif _in_range(timestamp, since_value, until_value):
                        token_final = totals
                        summary["token_snapshots_in_range"] += 1
                        if isinstance(info.get("model_context_window"), (int, float)):
                            summary["model_context_window"] = int(info["model_context_window"])

            if not _in_range(timestamp, since_value, until_value):
                continue
            summary["records_in_range"] += 1

            if record_type == "turn_context":
                if payload.get("model"):
                    summary["_models"].add(str(payload["model"]))
                if payload.get("effort"):
                    summary["_efforts"].add(str(payload["effort"]))
                continue

            if record_type == "response_item" and payload_type == "message":
                role = payload.get("role")
                message = text_content(payload)
                if role not in {"user", "assistant"} or not message or role == "user" and is_injected(message):
                    continue
                if not _mark(summary, payload, str(role), seen):
                    continue
                summary[f"{role}_messages"] += 1
                _update_event_bounds(summary, timestamp_text)
                continue

            if record_type == "response_item" and payload_type in {"custom_tool_call", "function_call"}:
                name = payload.get("name")
                if not isinstance(name, str) or not name or not _mark(summary, payload, "tool", seen):
                    continue
                summary["tool_calls"] += 1
                summary["_tools"][name] += 1
                _update_event_bounds(summary, timestamp_text)
                continue

            if record_type == "compacted":
                if _mark(summary, payload, "compaction", seen):
                    summary["compactions"] += 1
                    _update_event_bounds(summary, timestamp_text)
                continue

            if record_type != "event_msg":
                continue

            if payload_type == "user_message":
                for key, target in (
                    ("images", "image_inputs"),
                    ("local_images", "image_inputs"),
                    ("audio", "audio_inputs"),
                    ("local_audio", "audio_inputs"),
                ):
                    value = payload.get(key)
                    summary[target] += len(value) if isinstance(value, list) else int(bool(value))
                continue

            if payload_type in {"task_complete", "turn_aborted"}:
                if not _mark(summary, payload, "turn", seen):
                    continue
                summary["active_duration_ms"] += int(payload.get("duration_ms") or 0)
                if payload_type == "task_complete":
                    summary["completed_turns"] += 1
                    ttft = payload.get("time_to_first_token_ms")
                    if isinstance(ttft, (int, float)):
                        summary["_ttft_total_ms"] += round(ttft)
                        summary["_ttft_samples"] += 1
                else:
                    summary["aborted_turns"] += 1
                _update_event_bounds(summary, timestamp_text)
                continue

            if payload_type != "item_completed" or not isinstance(payload.get("item"), dict):
                continue
            item = payload["item"]
            item_type = item.get("type")
            if item_type == "CommandExecution" and _mark(summary, item, "command", seen):
                summary["command_executions"] += 1
                summary["command_duration_ms"] += _duration_ms(item.get("duration"))
                family = _command_family(item.get("command"))
                if family:
                    summary["_command_families"][family] += 1
                exit_code = item.get("exit_code")
                status = str(item.get("status") or "").lower()
                if exit_code == 0 or status in {"completed", "success", "succeeded"}:
                    summary["command_successes"] += 1
                elif isinstance(exit_code, int) or status in {"failed", "error", "aborted"}:
                    summary["command_failures"] += 1
                _update_event_bounds(summary, timestamp_text)
            elif item_type == "FileChange" and _mark(summary, item, "file_change", seen):
                summary["file_change_events"] += 1
                summary["_files"].update(_paths_from_changes(item.get("changes")))
                _update_event_bounds(summary, timestamp_text)
            elif item_type == "McpToolCall" and _mark(summary, item, "mcp", seen):
                summary["mcp_calls"] += 1
                summary["mcp_duration_ms"] += _duration_ms(item.get("duration"))
                label = "/".join(str(part) for part in (item.get("server"), item.get("tool")) if part)
                if label:
                    summary["_mcp_tools"][label] += 1
                if str(item.get("status") or "").lower() in {"failed", "error", "aborted"}:
                    summary["mcp_failures"] += 1
                _update_event_bounds(summary, timestamp_text)

    if since_value is not None and not token_baseline_seen:
        summary["token_delta_complete"] = session_started_at is not None and session_started_at >= since_value
    if token_final is not None:
        for field in TOKEN_FIELDS:
            final = token_final[field]
            baseline = token_baseline[field]
            summary[field] = final - baseline if final >= baseline else final
    summary["visible_messages"] = summary["user_messages"] + summary["assistant_messages"]
    summary["files_changed"] = len(summary["_files"])
    if summary["_ttft_samples"]:
        summary["average_time_to_first_token_ms"] = round(summary["_ttft_total_ms"] / summary["_ttft_samples"])
    return summary


def _project_counter(
    counter: Counter[str],
    limit: int | None,
) -> tuple[dict[str, int], bool, int, int]:
    items = sorted(counter.items(), key=lambda item: (-item[1], item[0]))
    selected = items if limit is None else items[:limit]
    omitted = items[len(selected) :]
    return dict(selected), bool(omitted), len(items), sum(count for _, count in omitted)


def public_summary(summary: dict[str, Any], counter_limit: int | None = None) -> dict[str, Any]:
    result = {key: value for key, value in summary.items() if not key.startswith("_")}
    for field, private_field, omitted_field in (
        ("tools", "_tools", "tool_calls_omitted"),
        ("command_families", "_command_families", "command_executions_omitted"),
        ("mcp_tools", "_mcp_tools", "mcp_calls_omitted"),
    ):
        values, truncated, distinct, omitted = _project_counter(summary[private_field], counter_limit)
        result[field] = values
        result[f"{field}_truncated"] = truncated
        result[f"{field}_distinct"] = distinct
        result[omitted_field] = omitted
    result["models"] = ",".join(sorted(summary["_models"]))
    result["reasoning_efforts"] = ",".join(sorted(summary["_efforts"]))
    return result


def aggregate_summaries(rows: list[dict[str, Any]]) -> dict[str, Any]:
    aggregate = _empty_summary(Path("/dev/null"))
    aggregate.update({"kind": "aggregate_summary", "path": "", "session_id": "", "sessions": len(rows)})
    aggregate["rollout_bytes"] = 0
    aggregate["first_event_at"] = min((row["first_event_at"] for row in rows if row["first_event_at"]), default="")
    aggregate["last_event_at"] = max((row["last_event_at"] for row in rows if row["last_event_at"]), default="")
    non_sum = {
        "kind",
        "path",
        "session_id",
        "sessions",
        "first_event_at",
        "last_event_at",
        "average_time_to_first_token_ms",
        "model_context_window",
        "token_delta_complete",
    }
    for row in rows:
        for key, value in row.items():
            if key.startswith("_") or key in non_sum or not isinstance(value, int):
                continue
            aggregate[key] += value
        aggregate["model_context_window"] = max(aggregate["model_context_window"], row["model_context_window"])
        aggregate["_tools"].update(row["_tools"])
        aggregate["_command_families"].update(row["_command_families"])
        aggregate["_mcp_tools"].update(row["_mcp_tools"])
        aggregate["_files"].update(row["_files"])
        aggregate["_models"].update(row["_models"])
        aggregate["_efforts"].update(row["_efforts"])
        aggregate["_ttft_total_ms"] += row["_ttft_total_ms"]
        aggregate["_ttft_samples"] += row["_ttft_samples"]
    aggregate["files_changed"] = len(aggregate["_files"])
    aggregate["token_delta_complete"] = all(row["token_delta_complete"] for row in rows)
    if aggregate["_ttft_samples"]:
        aggregate["average_time_to_first_token_ms"] = round(aggregate["_ttft_total_ms"] / aggregate["_ttft_samples"])
    return aggregate


def _summary_sort_value(row: dict[str, Any], sort: str) -> tuple[Any, str]:
    field = SUMMARY_SORT_FIELDS[sort]
    value = _timestamp(row[field]) if field == "last_event_at" else row[field]
    return value or 0, str(row["path"])


def _project_summary(row: dict[str, Any], fields: tuple[str, ...]) -> dict[str, Any]:
    return {field: row[field] for field in fields}


def _tsv_value(value: Any) -> str:
    if isinstance(value, (dict, list)):
        value = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return str(value).replace("\t", " ").replace("\n", " ")


def _print_summary_tsv(rows: list[dict[str, Any]], fields: tuple[str, ...]) -> None:
    print("\t".join(fields))
    for row in rows:
        print("\t".join(_tsv_value(row[field]) for field in fields))


def _parse_fields(value: str, available: tuple[str, ...]) -> tuple[str, ...]:
    fields = tuple(field.strip() for field in value.split(",") if field.strip())
    if not fields:
        raise ValueError("--fields must include at least one field")
    duplicates = sorted({field for field in fields if fields.count(field) > 1})
    if duplicates:
        raise ValueError(f"duplicate --fields: {', '.join(duplicates)}")
    unknown = sorted(set(fields) - set(available))
    if unknown:
        raise ValueError(f"unknown --fields: {', '.join(unknown)}")
    return fields


def _add_paths(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("paths", nargs="*", type=Path, help="Explicit rollout JSONL paths")
    parser.add_argument("--paths-from-stdin", action="store_true", help="Read additional rollout paths from stdin")
    parser.add_argument("--since", help="Include events at or after this ISO timestamp or local YYYY-MM-DD")
    parser.add_argument("--until", help="Include events through this ISO timestamp or local YYYY-MM-DD")
    parser.add_argument("--no-dedupe", action="store_true", help="Do not deduplicate repeated stable event IDs")


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    events_parser = subparsers.add_parser("events", help="Emit targeted, line-numbered rollout events")
    _add_paths(events_parser)
    events_parser.add_argument("--kind", action="append", choices=EVENT_KINDS)
    events_parser.add_argument("--match", action="append", default=[], metavar="REGEX")
    events_parser.add_argument("--ignore-case", action="store_true")
    events_parser.add_argument("--line-range", metavar="START:END")
    events_parser.add_argument("--tail", type=int)
    events_parser.add_argument("--max-chars", type=int, default=600, help="Maximum text characters; 0 means unlimited")
    events_parser.add_argument(
        "--unredacted",
        "--no-redact",
        dest="unredacted",
        action="store_true",
        help="Disable secret redaction and include raw tool details; may expose sensitive data",
    )

    summary_parser = subparsers.add_parser("summary", help="Emit metrics for selected rollout files")
    _add_paths(summary_parser)
    summary_parser.add_argument("--aggregate", action="store_true", help="Emit one aggregate record")
    summary_parser.add_argument("--sort", choices=tuple(SUMMARY_SORT_FIELDS), default="activity")
    summary_parser.add_argument("--limit", type=int, default=0, help="Maximum summaries after sorting; 0 means all")
    summary_parser.add_argument("--format", choices=("jsonl", "tsv"), default="jsonl")
    projection = summary_parser.add_mutually_exclusive_group()
    projection.add_argument("--fields", metavar="FIELD,...", help="Select and order output fields")
    projection.add_argument("--compact", action="store_true", help="Use a trustworthy compact overview")
    summary_parser.add_argument(
        "--counter-limit",
        type=int,
        default=None,
        metavar="N",
        help="Keep the N largest entries per counter; 0 emits empty counters",
    )
    args = parser.parse_args()
    if args.command == "summary":
        if args.fields:
            try:
                args.fields = _parse_fields(args.fields, SUMMARY_FIELDS)
            except ValueError as error:
                parser.error(str(error))
        elif args.compact:
            args.fields = SUMMARY_COMPACT_FIELDS
        else:
            args.fields = SUMMARY_FIELDS
        if args.compact and args.counter_limit is None:
            args.counter_limit = 5
    return args


def main() -> int:
    args = _arguments()
    try:
        if args.since:
            parse_boundary(args.since, end=False)
        if args.until:
            parse_boundary(args.until, end=True)
        paths = resolve_paths(args.paths, paths_from_stdin=args.paths_from_stdin)
    except ValueError as error:
        raise SystemExit(f"invalid timestamp: {error}") from error

    if args.command == "events":
        if args.max_chars < 0 or args.tail is not None and args.tail < 0:
            raise SystemExit("--max-chars and --tail must be non-negative")
        try:
            flags = re.IGNORECASE if args.ignore_case else 0
            patterns = [re.compile(pattern, flags) for pattern in args.match]
            line_range = parse_line_range(args.line_range)
        except (ValueError, re.error) as error:
            raise SystemExit(f"invalid event filter: {error}") from error
        events = extract_events(
            paths,
            kinds=set(args.kind or EVENT_KINDS),
            since=args.since,
            until=args.until,
            max_chars=args.max_chars,
            redact=not args.unredacted,
            patterns=patterns,
            line_range=line_range,
            dedupe=not args.no_dedupe,
        )
        if args.tail is not None:
            events = events[-args.tail :] if args.tail else []
        for event in events:
            print(json.dumps(event, ensure_ascii=False, sort_keys=True))
        return 0

    if args.limit < 0 or args.counter_limit is not None and args.counter_limit < 0:
        raise SystemExit("--limit and --counter-limit must be non-negative")
    seen = None if args.no_dedupe else set()
    rows = [
        summarize_rollout(path, since=args.since, until=args.until, seen=seen)
        for path in sorted(paths, key=_rollout_identity)
    ]
    rows.sort(key=lambda row: _summary_sort_value(row, args.sort), reverse=True)
    if args.limit:
        rows = rows[: args.limit]
    if args.aggregate:
        rows = [aggregate_summaries(rows)]
    public_rows = [public_summary(row, args.counter_limit) for row in rows]
    projected_rows = [_project_summary(row, args.fields) for row in public_rows]
    if args.format == "tsv":
        _print_summary_tsv(projected_rows, args.fields)
    else:
        for row in projected_rows:
            print(json.dumps(row, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

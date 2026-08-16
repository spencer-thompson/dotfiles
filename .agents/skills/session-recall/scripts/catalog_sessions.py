"""Discover Codex threads through the read-only state_5.sqlite catalog."""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import signal
import sqlite3
from collections import Counter
from contextlib import closing
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

from inspect_sessions import EVENT_KINDS, extract_events, parse_boundary, render_text

CODEX_HOME = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")).expanduser()
DEFAULT_DB = CODEX_HOME / "state_5.sqlite"
SORT_COLUMNS = {
    "created": "created_at_ms",
    "recency": "recency_at_ms",
    "tokens": "cumulative_tokens",
    "updated": "updated_at_ms",
}
CATALOG_FIELDS = (
    "thread_id",
    "created_at",
    "updated_at",
    "recency_at",
    "archived_at",
    "created_at_ms",
    "updated_at_ms",
    "recency_at_ms",
    "archived",
    "source",
    "thread_source",
    "model",
    "reasoning_effort",
    "cwd",
    "name",
    "display_name",
    "title",
    "first_user",
    "rollout_path",
    "agent_role",
    "agent_nickname",
    "agent_path",
    "cumulative_tokens",
    "git_project",
    "git_branch",
    "git_sha",
    "parent_thread_id",
    "root_thread_id",
    "family_size",
    "direct_child_count",
    "open_child_count",
    "family_cumulative_tokens",
    "catalog_source",
)
CATALOG_DEFAULT_FIELDS = (
    "recency_at",
    "updated_at",
    "created_at",
    "archived",
    "archived_at",
    "cumulative_tokens",
    "display_name",
    "name",
    "model",
    "reasoning_effort",
    "cwd",
    "git_project",
    "git_branch",
    "git_sha",
    "thread_id",
    "parent_thread_id",
    "root_thread_id",
    "family_size",
    "direct_child_count",
    "open_child_count",
    "family_cumulative_tokens",
    "rollout_path",
    "catalog_source",
)
CATALOG_COMPACT_FIELDS = (
    "thread_id",
    "recency_at",
    "cumulative_tokens",
    "display_name",
    "model",
    "reasoning_effort",
    "git_project",
    "git_branch",
    "family_size",
    "open_child_count",
)
SHOW_COMPACT_FIELDS = (*CATALOG_COMPACT_FIELDS, "root_thread_id", "rollout_path")
SHOW_COMPACT_TITLE_CHARS = 120
SHOW_FULL_FIELDS = (
    "thread_id",
    "name",
    "created_at",
    "updated_at",
    "recency_at",
    "archived",
    "archived_at",
    "cumulative_tokens",
    "model",
    "reasoning_effort",
    "parent_thread_id",
    "root_thread_id",
    "family_size",
    "direct_child_count",
    "open_child_count",
    "family_cumulative_tokens",
    "cwd",
    "rollout_path",
    "catalog_source",
)
REQUIRED_THREAD_COLUMNS = {
    "agent_nickname",
    "agent_path",
    "agent_role",
    "archived",
    "archived_at",
    "created_at_ms",
    "cwd",
    "first_user_message",
    "git_branch",
    "git_origin_url",
    "git_sha",
    "id",
    "model",
    "name",
    "reasoning_effort",
    "recency_at_ms",
    "rollout_path",
    "source",
    "thread_source",
    "title",
    "tokens_used",
    "updated_at_ms",
}


class CatalogUnavailable(RuntimeError):
    """Raised when the current SQLite catalog cannot be used safely."""


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list", help="List threads from the SQLite catalog.")
    _add_catalog_arguments(list_parser)
    list_parser.add_argument("--format", choices=("tsv", "jsonl", "paths"), default="tsv")
    list_projection = list_parser.add_mutually_exclusive_group()
    list_projection.add_argument("--fields", metavar="FIELD,...", help="Select and order output fields")
    list_projection.add_argument("--compact", action="store_true", help="Use compact discovery fields")

    stats_parser = subparsers.add_parser("stats", help="Aggregate filtered SQLite thread metadata.")
    _add_catalog_arguments(stats_parser)
    stats_parser.add_argument(
        "--group-by",
        choices=("none", "archive", "family", "git-branch", "git-project", "model", "month", "reasoning-effort"),
        default="none",
    )
    stats_parser.add_argument("--format", choices=("json", "jsonl", "tsv"), default="json")

    show_parser = subparsers.add_parser("show", help="Render safe metadata and event previews for selected threads.")
    show_parser.add_argument("thread_ids", nargs="+")
    show_parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    show_parser.add_argument("--kind", action="append", choices=EVENT_KINDS)
    show_parser.add_argument("--since")
    show_parser.add_argument("--until")
    show_parser.add_argument("--match", action="append", default=[], metavar="REGEX")
    show_parser.add_argument("--ignore-case", action="store_true")
    show_parser.add_argument("--tail", type=int)
    show_parser.add_argument("--max-chars", type=int, default=600, help="Maximum text characters; 0 means unlimited")
    show_parser.add_argument(
        "--unredacted",
        "--no-redact",
        dest="unredacted",
        action="store_true",
        help="Disable secret redaction and include raw tool details; may expose sensitive data",
    )
    show_parser.add_argument("--metadata", choices=("full", "compact", "none"), default="full")
    show_parser.add_argument("--events-only", action="store_true", help="Alias for --metadata none")
    show_parser.add_argument("--format", choices=("markdown", "json", "jsonl"), default="markdown")

    args = parser.parse_args()
    if args.command == "show":
        if args.events_only and args.metadata not in {"full", "none"}:
            parser.error("--events-only conflicts with --metadata compact")
        if args.events_only:
            args.metadata = "none"
        args.thread_ids = list(dict.fromkeys(args.thread_ids))
        return args

    if args.top_by_tokens is not None:
        if args.sort not in (None, "tokens"):
            parser.error("--top-by-tokens conflicts with a non-token --sort")
        if args.limit is not None and args.limit != args.top_by_tokens:
            parser.error("--top-by-tokens conflicts with a different --limit")
        args.sort = "tokens"
        args.limit = args.top_by_tokens
    args.sort = args.sort or "recency"
    args.limit = 40 if args.limit is None else args.limit
    if args.command == "list":
        if args.format == "paths" and (args.fields or args.compact):
            parser.error("--fields and --compact cannot be used with --format paths")
        if args.fields:
            try:
                args.fields = _parse_fields(args.fields, CATALOG_FIELDS)
            except ValueError as error:
                parser.error(str(error))
        elif args.compact:
            args.fields = CATALOG_COMPACT_FIELDS
        else:
            args.fields = CATALOG_DEFAULT_FIELDS

    if args.children and args.parent_thread_id and args.children != args.parent_thread_id:
        parser.error("--children and --parent-thread-id must name the same thread")
    args.parent_thread_id = args.parent_thread_id or args.children
    if args.family and args.root_thread_id:
        parser.error("use either --family or --root-thread-id, not both")
    return args


def _add_catalog_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--archived", choices=("active", "archived", "all"), default="all")
    parser.add_argument("--days", type=float, default=None)
    parser.add_argument("--since", help="Include threads updated at or after this ISO timestamp or local YYYY-MM-DD")
    parser.add_argument("--until", help="Include threads updated through this ISO timestamp or local YYYY-MM-DD")
    parser.add_argument("--cwd", help="Require this cwd prefix")
    parser.add_argument("--query", help="Search name, title, first user message, and cwd")
    parser.add_argument("--source", help="Require this source substring")
    parser.add_argument("--model", help="Require this model substring")
    parser.add_argument("--reasoning-effort", help="Require this exact reasoning effort")
    parser.add_argument("--git-project", help="Require this Git origin substring")
    parser.add_argument("--git-branch", help="Require this exact Git branch")
    parser.add_argument("--named-only", action="store_true", help="Return only user-named threads")
    parser.add_argument("--min-tokens", type=int, default=0)
    parser.add_argument("--sort", choices=tuple(SORT_COLUMNS))
    parser.add_argument("--top-by-tokens", type=int, metavar="N", help="Alias for --sort tokens --limit N")
    parser.add_argument("--root-thread-id", metavar="ROOT_ID", help="Return the family rooted at this thread")
    parser.add_argument("--family", metavar="THREAD_ID", help="Return the family containing this thread")
    parser.add_argument("--parent-thread-id", metavar="THREAD_ID", help="Return direct children of this thread")
    parser.add_argument("--children", metavar="THREAD_ID", help="Alias for --parent-thread-id")
    parser.add_argument("--top-level-only", action="store_true")
    parser.add_argument("--exclude-thread", action="append", default=[], metavar="THREAD_ID")
    parser.add_argument("--limit", type=int, default=None, help="Maximum rows after filtering and sorting; 0 means all")
    parser.add_argument("--preview-chars", type=int, default=180)


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


def _connect_read_only(path: Path) -> sqlite3.Connection:
    resolved = path.expanduser().resolve()
    if not resolved.is_file():
        raise CatalogUnavailable(f"missing Codex state database: {resolved}")
    try:
        connection = sqlite3.connect(f"{resolved.as_uri()}?mode=ro", uri=True)
    except sqlite3.Error as error:
        raise CatalogUnavailable(f"cannot open Codex state database: {error}") from error
    connection.row_factory = sqlite3.Row
    return connection


def _validate_schema(connection: sqlite3.Connection) -> None:
    tables = {str(row[0]) for row in connection.execute("SELECT name FROM sqlite_schema WHERE type = 'table'")}
    missing_tables = {"threads", "thread_spawn_edges"} - tables
    if missing_tables:
        raise CatalogUnavailable(f"incompatible state database; missing tables: {', '.join(sorted(missing_tables))}")

    columns = {str(row[1]) for row in connection.execute("PRAGMA table_info(threads)")}
    missing_columns = REQUIRED_THREAD_COLUMNS - columns
    if missing_columns:
        raise CatalogUnavailable(f"incompatible threads schema; missing: {', '.join(sorted(missing_columns))}")


def _time_filters(*, days: float, since: str | None, until: str | None) -> tuple[list[str], list[Any]]:
    where: list[str] = []
    params: list[Any] = []
    if days > 0:
        cutoff = math.ceil((datetime.now(timezone.utc) - timedelta(days=days)).timestamp() * 1000)
        where.append("updated_at_ms >= ?")
        params.append(cutoff)
    if since:
        where.append("updated_at_ms >= ?")
        params.append(math.ceil(parse_boundary(since, end=False)[0] * 1000))
    if until:
        value, inclusive = parse_boundary(until, end=True)
        where.append(f"updated_at_ms {'<=' if inclusive else '<'} ?")
        params.append(math.floor(value * 1000))
    return where, params


def _family_metadata(connection: sqlite3.Connection) -> dict[str, dict[str, Any]]:
    tokens_by_thread = {
        str(row["id"]): int(row["tokens_used"] or 0)
        for row in connection.execute("SELECT id, tokens_used FROM threads")
    }
    parent_by_child: dict[str, str] = {}
    child_status: dict[str, str] = {}
    children_by_parent: dict[str, list[str]] = {}
    for row in connection.execute("SELECT parent_thread_id, child_thread_id, status FROM thread_spawn_edges"):
        parent = str(row["parent_thread_id"])
        child = str(row["child_thread_id"])
        if parent not in tokens_by_thread or child not in tokens_by_thread:
            raise CatalogUnavailable("thread_spawn_edges references a missing thread")
        parent_by_child[child] = parent
        child_status[child] = str(row["status"])
        children_by_parent.setdefault(parent, []).append(child)

    roots: dict[str, str] = {}
    for thread_id in tokens_by_thread:
        current = thread_id
        seen: set[str] = set()
        while current in parent_by_child:
            if current in seen:
                raise CatalogUnavailable("cycle detected in thread_spawn_edges")
            seen.add(current)
            current = parent_by_child[current]
        roots[thread_id] = current

    family_sizes = Counter(roots.values())
    family_tokens: Counter[str] = Counter()
    for thread_id, root_id in roots.items():
        family_tokens[root_id] += tokens_by_thread[thread_id]

    return {
        thread_id: {
            "parent_thread_id": parent_by_child.get(thread_id, ""),
            "root_thread_id": root_id,
            "family_size": family_sizes[root_id],
            "direct_child_count": len(children_by_parent.get(thread_id, [])),
            "open_child_count": sum(child_status[child] == "open" for child in children_by_parent.get(thread_id, [])),
            "family_cumulative_tokens": family_tokens[root_id],
        }
        for thread_id, root_id in roots.items()
    }


def query_catalog(
    db_path: Path = DEFAULT_DB,
    *,
    archived: str = "all",
    days: float = 3,
    since: str | None = None,
    until: str | None = None,
    cwd: str | None = None,
    query: str | None = None,
    source: str | None = None,
    model: str | None = None,
    reasoning_effort: str | None = None,
    git_project: str | None = None,
    git_branch: str | None = None,
    named_only: bool = False,
    min_tokens: int = 0,
    sort: str = "recency",
    root_thread_id: str | None = None,
    family: str | None = None,
    parent_thread_id: str | None = None,
    top_level_only: bool = False,
    excluded_threads: set[str] | None = None,
    limit: int = 40,
    preview_chars: int = 180,
    thread_ids: list[str] | None = None,
) -> list[dict[str, Any]]:
    with closing(_connect_read_only(db_path)) as connection:
        _validate_schema(connection)
        families = _family_metadata(connection)
        if root_thread_id:
            if root_thread_id not in families:
                raise CatalogUnavailable(f"thread not found: {root_thread_id}")
            if families[root_thread_id]["root_thread_id"] != root_thread_id:
                raise CatalogUnavailable(f"not a root thread: {root_thread_id}; use --family instead")
        if family and family not in families:
            raise CatalogUnavailable(f"thread not found: {family}")
        if parent_thread_id and parent_thread_id not in families:
            raise CatalogUnavailable(f"thread not found: {parent_thread_id}")

        where, params = _time_filters(days=days, since=since, until=until)
        if archived == "active":
            where.append("archived = 0")
        elif archived == "archived":
            where.append("archived = 1")
        if cwd:
            where.append("cwd LIKE ?")
            params.append(f"{cwd}%")
        if source:
            needle = f"%{source.lower()}%"
            where.append("(lower(source) LIKE ? OR lower(coalesce(thread_source, '')) LIKE ?)")
            params.extend([needle, needle])
        if model:
            where.append("lower(coalesce(model, '')) LIKE ?")
            params.append(f"%{model.lower()}%")
        if reasoning_effort:
            where.append("lower(coalesce(reasoning_effort, '')) = ?")
            params.append(reasoning_effort.lower())
        if git_project:
            where.append("lower(coalesce(git_origin_url, '')) LIKE ?")
            params.append(f"%{git_project.lower()}%")
        if git_branch:
            where.append("lower(coalesce(git_branch, '')) = ?")
            params.append(git_branch.lower())
        if named_only:
            where.append("coalesce(trim(name), '') <> ''")
        if min_tokens:
            where.append("tokens_used >= ?")
            params.append(min_tokens)
        if query:
            needle = f"%{query.lower()}%"
            where.append(
                "(lower(coalesce(name, '')) LIKE ? OR lower(title) LIKE ? "
                "OR lower(first_user_message) LIKE ? OR lower(cwd) LIKE ? "
                "OR lower(coalesce(git_origin_url, '')) LIKE ? OR lower(coalesce(git_branch, '')) LIKE ?)"
            )
            params.extend([needle, needle, needle, needle, needle, needle])
        if top_level_only:
            where.append("coalesce(thread_source, '') <> 'subagent'")
            where.append("coalesce(agent_role, '') = ''")
            where.append("coalesce(agent_path, '') = ''")
            where.append("NOT EXISTS (SELECT 1 FROM thread_spawn_edges e WHERE e.child_thread_id = threads.id)")
        excluded = excluded_threads or set()
        if excluded:
            placeholders = ", ".join("?" for _ in excluded)
            where.append(f"id NOT IN ({placeholders})")
            params.extend(sorted(excluded))
        if thread_ids:
            placeholders = ", ".join("?" for _ in thread_ids)
            where.append(f"id IN ({placeholders})")
            params.extend(thread_ids)

        where_sql = f"WHERE {' AND '.join(where)}" if where else ""
        try:
            database_rows = connection.execute(
                f"""
                SELECT
                    id, rollout_path, created_at_ms, updated_at_ms, recency_at_ms,
                    source, thread_source, cwd, title, name, first_user_message,
                    archived, archived_at, model, reasoning_effort, agent_role,
                    agent_nickname, agent_path, tokens_used, git_origin_url,
                    git_branch, git_sha
                FROM threads
                {where_sql}
                """,
                params,
            ).fetchall()
        except sqlite3.Error as error:
            raise CatalogUnavailable(f"cannot query threads catalog: {error}") from error

    selected_root = root_thread_id or (families[family]["root_thread_id"] if family else None)
    rows: list[dict[str, Any]] = []
    for database_row in database_rows:
        row = _database_row(database_row, families, preview_chars)
        if selected_root and row["root_thread_id"] != selected_root:
            continue
        if parent_thread_id and row["parent_thread_id"] != parent_thread_id:
            continue
        rows.append(row)

    sort_field = SORT_COLUMNS[sort]
    rows.sort(key=lambda row: (int(row[sort_field] or 0), str(row["thread_id"])), reverse=True)
    return rows[:limit] if limit else rows


def _iso_timestamp_ms(value: int | None) -> str:
    if value is None:
        return ""
    return datetime.fromtimestamp(value / 1000, tz=timezone.utc).isoformat(timespec="milliseconds")


def _iso_timestamp_seconds(value: int | None) -> str:
    if value is None:
        return ""
    return datetime.fromtimestamp(value, tz=timezone.utc).isoformat()


def _git_project(value: Any) -> str:
    """Return a credential-free host/path project label."""
    text = str(value or "").strip()
    if not text:
        return ""
    ssh = re.fullmatch(r"(?:[^@/]+@)?([^:]+):(.+)", text)
    if ssh and "://" not in text:
        project = f"{ssh.group(1)}/{ssh.group(2)}"
    elif "://" in text:
        parsed = urlsplit(text)
        project = f"{parsed.hostname or ''}{parsed.path}"
    else:
        project = text
    return project.removesuffix(".git").strip("/")


def _database_row(
    row: sqlite3.Row,
    families: dict[str, dict[str, Any]],
    preview_chars: int,
) -> dict[str, Any]:
    data = dict(row)
    thread_id = str(data["id"])
    name = render_text(str(data["name"] or ""), preview_chars, compact=True)
    title = render_text(str(data["title"] or ""), preview_chars, compact=True)
    first_user = render_text(str(data["first_user_message"] or ""), preview_chars, compact=True)
    return {
        "thread_id": thread_id,
        "created_at": _iso_timestamp_ms(data["created_at_ms"]),
        "updated_at": _iso_timestamp_ms(data["updated_at_ms"]),
        "recency_at": _iso_timestamp_ms(data["recency_at_ms"]),
        "archived_at": _iso_timestamp_seconds(data["archived_at"]),
        "created_at_ms": int(data["created_at_ms"]),
        "updated_at_ms": int(data["updated_at_ms"]),
        "recency_at_ms": int(data["recency_at_ms"]),
        "archived": bool(data["archived"]),
        "source": render_text(str(data["source"] or ""), preview_chars, compact=True),
        "thread_source": render_text(str(data["thread_source"] or ""), preview_chars, compact=True),
        "model": render_text(str(data["model"] or ""), preview_chars, compact=True),
        "reasoning_effort": render_text(str(data["reasoning_effort"] or ""), preview_chars, compact=True),
        "cwd": str(data["cwd"] or ""),
        "name": name,
        "display_name": name or title or first_user or thread_id,
        "title": title,
        "first_user": first_user,
        "rollout_path": str(data["rollout_path"] or ""),
        "agent_role": render_text(str(data["agent_role"] or ""), preview_chars, compact=True),
        "agent_nickname": render_text(str(data["agent_nickname"] or ""), preview_chars, compact=True),
        "agent_path": str(data["agent_path"] or ""),
        "cumulative_tokens": int(data["tokens_used"] or 0),
        "git_project": _git_project(data["git_origin_url"]),
        "git_branch": str(data["git_branch"] or ""),
        "git_sha": str(data["git_sha"] or ""),
        **families[thread_id],
        "catalog_source": "sqlite",
    }


def _project(row: dict[str, Any], fields: tuple[str, ...]) -> dict[str, Any]:
    return {field: row[field] for field in fields}


def _print_tsv(rows: list[dict[str, Any]], fields: tuple[str, ...]) -> None:
    print("\t".join(fields))
    for row in rows:
        values = [str(row.get(field, "")).replace("\t", " ").replace("\n", " ") for field in fields]
        print("\t".join(values))


def _show_record(thread: dict[str, Any], events: list[dict[str, Any]], metadata: str) -> dict[str, Any]:
    if metadata == "full":
        projected = thread
    elif metadata == "compact":
        projected = _project(thread, SHOW_COMPACT_FIELDS)
        projected["display_name"] = render_text(
            projected["display_name"],
            SHOW_COMPACT_TITLE_CHARS,
            compact=True,
        )
    else:
        projected = {"thread_id": thread["thread_id"]}
    return {"thread": projected, "events": events}


def _show_markdown(record: dict[str, Any], metadata: str) -> None:
    thread = record["thread"]
    title = thread.get("display_name") or thread["thread_id"]
    print(f"# {title}")
    if metadata != "none":
        print()
        fields = SHOW_FULL_FIELDS if metadata == "full" else SHOW_COMPACT_FIELDS
        for field in fields:
            print(f"- {field}: \x60{thread.get(field, '')}\x60")
    print()
    print("## Safe events")
    print()
    for event in record["events"]:
        location = f"{event.get('path', '')}:{event.get('line', '')}"
        details = {key: value for key, value in event.items() if key not in {"path", "line", "timestamp", "kind"}}
        preview = event.get("preview") or event.get("tool") or json.dumps(details, ensure_ascii=False, sort_keys=True)
        print(f"- \x60{event.get('timestamp', '')}\x60 {event.get('kind', '')} \x60{location}\x60 — {preview}")


def catalog_stats(rows: list[dict[str, Any]], group_by: str = "none") -> list[dict[str, Any]]:
    """Aggregate already-filtered catalog rows."""

    def group_value(row: dict[str, Any]) -> str:
        if group_by == "none":
            return "all"
        if group_by == "archive":
            return "archived" if row["archived"] else "active"
        if group_by == "family":
            return str(row["root_thread_id"])
        if group_by == "month":
            return str(row["created_at"])[:7]
        return str(row[group_by.replace("-", "_")] or "(none)")

    groups: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        groups.setdefault(group_value(row), []).append(row)

    statistics: list[dict[str, Any]] = []
    for group, group_rows in groups.items():
        tokens = sorted(int(row["cumulative_tokens"]) for row in group_rows)
        middle = len(tokens) // 2
        median = tokens[middle] if len(tokens) % 2 else round((tokens[middle - 1] + tokens[middle]) / 2)
        statistics.append(
            {
                "group": group,
                "threads": len(group_rows),
                "families": len({str(row["root_thread_id"]) for row in group_rows}),
                "named_threads": sum(bool(row["name"]) for row in group_rows),
                "archived_threads": sum(bool(row["archived"]) for row in group_rows),
                "cumulative_tokens": sum(tokens),
                "average_cumulative_tokens": round(sum(tokens) / len(tokens)),
                "median_cumulative_tokens": median,
                "p90_cumulative_tokens": tokens[max(0, math.ceil(len(tokens) * 0.9) - 1)],
                "max_cumulative_tokens": tokens[-1],
            }
        )
    statistics.sort(key=lambda row: (int(row["cumulative_tokens"]), str(row["group"])), reverse=True)
    return statistics


def _print_stats_tsv(rows: list[dict[str, Any]]) -> None:
    fields = (
        "group",
        "threads",
        "families",
        "named_threads",
        "archived_threads",
        "cumulative_tokens",
        "average_cumulative_tokens",
        "median_cumulative_tokens",
        "p90_cumulative_tokens",
        "max_cumulative_tokens",
    )
    print("\t".join(fields))
    for row in rows:
        print("\t".join(str(row[field]) for field in fields))


def _validate_numbers(*, days: float, limit: int, preview_chars: int, min_tokens: int) -> None:
    if days < 0 or limit < 0 or preview_chars < 0 or min_tokens < 0:
        raise SystemExit("--days, --limit, --preview-chars, and --min-tokens must be non-negative")


def main() -> int:
    args = _arguments()
    if args.command in {"list", "stats"}:
        family_navigation = args.root_thread_id or args.family or args.parent_thread_id
        days = args.days if args.days is not None else (0 if args.since or args.until or family_navigation else 3)
        _validate_numbers(days=days, limit=args.limit, preview_chars=args.preview_chars, min_tokens=args.min_tokens)
        try:
            rows = query_catalog(
                db_path=args.db,
                archived=args.archived,
                days=days,
                since=args.since,
                until=args.until,
                cwd=args.cwd,
                query=args.query,
                source=args.source,
                model=args.model,
                reasoning_effort=args.reasoning_effort,
                git_project=args.git_project,
                git_branch=args.git_branch,
                named_only=args.named_only,
                min_tokens=args.min_tokens,
                sort=args.sort,
                root_thread_id=args.root_thread_id,
                family=args.family,
                parent_thread_id=args.parent_thread_id,
                top_level_only=args.top_level_only,
                excluded_threads=set(args.exclude_thread),
                limit=0 if args.command == "stats" else args.limit,
                preview_chars=args.preview_chars,
            )
        except CatalogUnavailable as error:
            raise SystemExit(str(error)) from error
        if args.command == "stats":
            stats = catalog_stats(rows, args.group_by)
            if args.format == "json":
                print(json.dumps(stats, ensure_ascii=False, indent=2, sort_keys=True))
            elif args.format == "jsonl":
                for row in stats:
                    print(json.dumps(row, ensure_ascii=False, sort_keys=True))
            else:
                _print_stats_tsv(stats)
        elif args.format == "paths":
            for row in rows:
                print(row["rollout_path"])
        else:
            projected = [_project(row, args.fields) for row in rows]
            if args.format == "jsonl":
                for row in projected:
                    print(json.dumps(row, ensure_ascii=False))
            else:
                _print_tsv(projected, args.fields)
        return 0

    _validate_numbers(days=0, limit=len(args.thread_ids), preview_chars=args.max_chars, min_tokens=0)
    if args.tail is not None and args.tail < 0:
        raise SystemExit("--tail must be non-negative")
    try:
        rows = query_catalog(
            db_path=args.db,
            days=0,
            limit=0,
            preview_chars=args.max_chars,
            thread_ids=args.thread_ids,
        )
    except CatalogUnavailable as error:
        raise SystemExit(str(error)) from error
    rows_by_id = {row["thread_id"]: row for row in rows}
    missing_ids = [thread_id for thread_id in args.thread_ids if thread_id not in rows_by_id]
    if missing_ids:
        raise SystemExit(f"threads not found: {', '.join(missing_ids)}")
    ordered_rows = [rows_by_id[thread_id] for thread_id in args.thread_ids]
    missing_paths = [row["rollout_path"] for row in ordered_rows if not Path(row["rollout_path"]).is_file()]
    if missing_paths:
        raise SystemExit(f"rollouts not found: {', '.join(missing_paths)}")
    try:
        if args.since:
            parse_boundary(args.since, end=False)
        if args.until:
            parse_boundary(args.until, end=True)
        flags = re.IGNORECASE if args.ignore_case else 0
        patterns = [re.compile(pattern, flags) for pattern in args.match]
    except (ValueError, re.error) as error:
        raise SystemExit(f"invalid event filter: {error}") from error

    records: list[dict[str, Any]] = []
    for thread in ordered_rows:
        events = extract_events(
            [Path(thread["rollout_path"])],
            kinds=set(args.kind or EVENT_KINDS),
            since=args.since,
            until=args.until,
            max_chars=args.max_chars,
            redact=not args.unredacted,
            patterns=patterns,
        )
        if args.tail is not None:
            events = events[-args.tail :] if args.tail else []
        records.append(_show_record(thread, events, args.metadata))

    if args.format == "json":
        payload: Any = records[0] if len(records) == 1 else records
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    elif args.format == "jsonl":
        for record in records:
            print(json.dumps(record, ensure_ascii=False))
    else:
        for index, record in enumerate(records):
            if index:
                print()
                print("---")
                print()
            _show_markdown(record, args.metadata)
    return 0


if __name__ == "__main__":
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    raise SystemExit(main())

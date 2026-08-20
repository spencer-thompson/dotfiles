from __future__ import annotations

import json
import sqlite3
import sys
import tempfile
import unittest
from contextlib import closing, redirect_stdout
from io import StringIO
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import catalog_sessions
import inspect_sessions
from catalog_sessions import CatalogUnavailable, catalog_stats, query_catalog
from inspect_sessions import aggregate_summaries, extract_events, public_summary, summarize_rollout


class CatalogTests(unittest.TestCase):
    def _create_catalog(self, path: Path) -> None:
        with closing(sqlite3.connect(path)) as connection, connection:
            connection.executescript(
                """
                CREATE TABLE threads (
                    id TEXT PRIMARY KEY,
                    rollout_path TEXT NOT NULL,
                    created_at_ms INTEGER NOT NULL,
                    updated_at_ms INTEGER NOT NULL,
                    recency_at_ms INTEGER NOT NULL,
                    source TEXT NOT NULL,
                    cwd TEXT NOT NULL,
                    title TEXT NOT NULL,
                    archived INTEGER NOT NULL,
                    archived_at INTEGER,
                    first_user_message TEXT NOT NULL,
                    model TEXT,
                    reasoning_effort TEXT,
                    agent_role TEXT,
                    agent_nickname TEXT,
                    agent_path TEXT,
                    thread_source TEXT,
                    tokens_used INTEGER NOT NULL,
                    name TEXT,
                    git_origin_url TEXT,
                    git_branch TEXT,
                    git_sha TEXT
                );
                CREATE TABLE thread_spawn_edges (
                    parent_thread_id TEXT NOT NULL,
                    child_thread_id TEXT NOT NULL PRIMARY KEY,
                    status TEXT NOT NULL
                );
                """
            )

    def _insert_thread(
        self,
        path: Path,
        *,
        thread_id: str,
        archived: int = 0,
        title: str = "A durable session",
        name: str = "",
        first_user: str = "Always run focused tests.",
        model: str = "gpt-test",
        reasoning_effort: str = "medium",
        agent_role: str = "",
        agent_path: str = "",
        created_at_ms: int = 1_750_000_000_000,
        updated_at_ms: int = 1_750_000_100_000,
        recency_at_ms: int = 1_750_000_050_000,
        tokens_used: int = 123,
        git_origin_url: str = "",
        git_branch: str = "",
        git_sha: str = "",
        rollout_path: str | None = None,
    ) -> None:
        with closing(sqlite3.connect(path)) as connection, connection:
            connection.execute(
                """
                INSERT INTO threads (
                    id, rollout_path, created_at_ms, updated_at_ms, recency_at_ms,
                    source, cwd, title, archived, archived_at, first_user_message,
                    model, reasoning_effort, agent_role, agent_nickname, agent_path,
                    thread_source, tokens_used, name, git_origin_url, git_branch, git_sha
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    thread_id,
                    rollout_path or f"/tmp/{thread_id}.jsonl",
                    created_at_ms,
                    updated_at_ms,
                    recency_at_ms,
                    "cli",
                    "/tmp/project",
                    title,
                    archived,
                    1_750_000_100 if archived else None,
                    first_user,
                    model,
                    reasoning_effort,
                    agent_role,
                    "",
                    agent_path,
                    "subagent" if agent_role or agent_path else "user",
                    tokens_used,
                    name,
                    git_origin_url,
                    git_branch,
                    git_sha,
                ),
            )

    def _insert_edge(self, path: Path, parent: str, child: str, status: str = "closed") -> None:
        with closing(sqlite3.connect(path)) as connection, connection:
            connection.execute(
                "INSERT INTO thread_spawn_edges (parent_thread_id, child_thread_id, status) VALUES (?, ?, ?)",
                (parent, child, status),
            )

    def _query(self, path: Path, **overrides: object) -> list[dict[str, object]]:
        arguments: dict[str, object] = {
            "archived": "all",
            "days": 0,
            "limit": 0,
            "preview_chars": 180,
        }
        arguments.update(overrides)
        return query_catalog(path, **arguments)  # type: ignore[arg-type]

    def test_filters_git_name_model_reasoning_and_top_level(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "state.sqlite"
            self._create_catalog(database)
            self._insert_thread(
                database,
                thread_id="active",
                name="Important database work",
                model="gpt-5.6-sol",
                reasoning_effort="max",
                git_origin_url="https://credential@example.com/acme/widget.git",
                git_branch="feature/recall",
                git_sha="abc123",
            )
            self._insert_thread(database, thread_id="child", agent_role="worker", agent_path="/root/worker")
            self._insert_edge(database, "active", "child", "open")

            rows = self._query(
                database,
                top_level_only=True,
                query="widget",
                model="5.6",
                reasoning_effort="MAX",
                named_only=True,
                git_project="acme/widget",
                git_branch="FEATURE/RECALL",
            )

        self.assertEqual([row["thread_id"] for row in rows], ["active"])
        self.assertEqual(rows[0]["git_project"], "example.com/acme/widget")
        self.assertNotIn("credential", rows[0]["git_project"])
        self.assertEqual(rows[0]["family_size"], 2)
        self.assertEqual(rows[0]["open_child_count"], 1)

    def test_sorts_filters_family_and_tokens(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "state.sqlite"
            self._create_catalog(database)
            self._insert_thread(database, thread_id="root", tokens_used=100, recency_at_ms=100)
            self._insert_thread(database, thread_id="child", tokens_used=300, recency_at_ms=300)
            self._insert_thread(database, thread_id="other", tokens_used=200, recency_at_ms=200)
            self._insert_edge(database, "root", "child", "closed")

            family = self._query(database, family="child", sort="tokens")
            top = self._query(database, sort="tokens", min_tokens=200, limit=1)

            with self.assertRaisesRegex(CatalogUnavailable, "not a root thread"):
                self._query(database, root_thread_id="child")

        self.assertEqual([row["thread_id"] for row in family], ["child", "root"])
        self.assertEqual(family[0]["family_cumulative_tokens"], 400)
        self.assertEqual([row["thread_id"] for row in top], ["child"])

    def test_stats_aggregate_and_group(self) -> None:
        rows = [
            {
                "root_thread_id": "one",
                "created_at": "2026-01-01T00:00:00Z",
                "archived": False,
                "name": "Named",
                "cumulative_tokens": 100,
                "model": "gpt-a",
                "reasoning_effort": "high",
                "git_project": "example/a",
                "git_branch": "main",
            },
            {
                "root_thread_id": "one",
                "created_at": "2026-01-02T00:00:00Z",
                "archived": True,
                "name": "",
                "cumulative_tokens": 300,
                "model": "gpt-a",
                "reasoning_effort": "high",
                "git_project": "example/a",
                "git_branch": "main",
            },
            {
                "root_thread_id": "two",
                "created_at": "2026-02-01T00:00:00Z",
                "archived": False,
                "name": "",
                "cumulative_tokens": 200,
                "model": "gpt-b",
                "reasoning_effort": "medium",
                "git_project": "example/b",
                "git_branch": "dev",
            },
        ]

        total = catalog_stats(rows)[0]
        grouped = catalog_stats(rows, "model")

        self.assertEqual(total["threads"], 3)
        self.assertEqual(total["families"], 2)
        self.assertEqual(total["cumulative_tokens"], 600)
        self.assertEqual(total["median_cumulative_tokens"], 200)
        self.assertEqual([row["group"] for row in grouped], ["gpt-a", "gpt-b"])

    def test_redacts_catalog_preview_and_requires_current_schema(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "state.sqlite"
            self._create_catalog(database)
            self._insert_thread(database, thread_id="secret", first_user="token=sk-abcdefghijklmnopqrstuvwxyz")
            rows = self._query(database)
            self.assertEqual(rows[0]["first_user"], "token=[REDACTED]")

            broken = Path(directory) / "broken.sqlite"
            with closing(sqlite3.connect(broken)) as connection, connection:
                connection.execute("CREATE TABLE threads (id TEXT PRIMARY KEY)")
            with self.assertRaisesRegex(CatalogUnavailable, "missing tables"):
                query_catalog(broken, days=0)

    def test_stats_cli_uses_all_filtered_rows(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "state.sqlite"
            self._create_catalog(database)
            for index in range(45):
                self._insert_thread(database, thread_id=str(index), tokens_used=index + 1)
            output = StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    ["catalog_sessions.py", "stats", "--db", str(database), "--days", "0", "--format", "json"],
                ),
                redirect_stdout(output),
            ):
                self.assertEqual(catalog_sessions.main(), 0)

        self.assertEqual(json.loads(output.getvalue())[0]["threads"], 45)

    def test_list_fields_and_compact_are_output_only_projections(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "state.sqlite"
            self._create_catalog(database)
            self._insert_thread(database, thread_id="one", name="Named", tokens_used=321)

            selected = StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    [
                        "catalog_sessions.py",
                        "list",
                        "--db",
                        str(database),
                        "--days",
                        "0",
                        "--fields",
                        "thread_id,cumulative_tokens,display_name",
                        "--format",
                        "jsonl",
                    ],
                ),
                redirect_stdout(selected),
            ):
                self.assertEqual(catalog_sessions.main(), 0)

            compact = StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    [
                        "catalog_sessions.py",
                        "list",
                        "--db",
                        str(database),
                        "--days",
                        "0",
                        "--compact",
                    ],
                ),
                redirect_stdout(compact),
            ):
                self.assertEqual(catalog_sessions.main(), 0)

        selected_row = json.loads(selected.getvalue())
        self.assertEqual(list(selected_row), ["thread_id", "cumulative_tokens", "display_name"])
        self.assertEqual(selected_row["cumulative_tokens"], 321)
        self.assertEqual(compact.getvalue().splitlines()[0].split("\t"), list(catalog_sessions.CATALOG_COMPACT_FIELDS))

    def test_show_batches_threads_and_controls_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            database = root / "state.sqlite"
            self._create_catalog(database)
            for thread_id in ("one", "two"):
                rollout = root / f"{thread_id}.jsonl"
                rollout.write_text(
                    json.dumps(
                        {
                            "timestamp": "2026-08-10T10:00:00Z",
                            "type": "response_item",
                            "payload": {
                                "type": "message",
                                "role": "user",
                                "id": thread_id,
                                "content": thread_id,
                            },
                        }
                    )
                    + "\n",
                    encoding="utf-8",
                )
                self._insert_thread(
                    database,
                    thread_id=thread_id,
                    title="x" * 300 if thread_id == "one" else "A durable session",
                    rollout_path=str(rollout),
                )

            output = StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    [
                        "catalog_sessions.py",
                        "show",
                        "two",
                        "one",
                        "--db",
                        str(database),
                        "--events-only",
                        "--tail",
                        "1",
                        "--format",
                        "jsonl",
                    ],
                ),
                redirect_stdout(output),
            ):
                self.assertEqual(catalog_sessions.main(), 0)

            compact_metadata = StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    [
                        "catalog_sessions.py",
                        "show",
                        "one",
                        "--db",
                        str(database),
                        "--metadata",
                        "compact",
                        "--tail",
                        "0",
                        "--format",
                        "json",
                    ],
                ),
                redirect_stdout(compact_metadata),
            ):
                self.assertEqual(catalog_sessions.main(), 0)

        records = [json.loads(line) for line in output.getvalue().splitlines()]
        self.assertEqual([record["thread"]["thread_id"] for record in records], ["two", "one"])
        self.assertEqual([list(record["thread"]) for record in records], [["thread_id"], ["thread_id"]])
        self.assertEqual([record["events"][0]["preview"] for record in records], ["two", "one"])
        compact_name = json.loads(compact_metadata.getvalue())["thread"]["display_name"]
        self.assertEqual(len(compact_name), catalog_sessions.SHOW_COMPACT_TITLE_CHARS)
        self.assertTrue(compact_name.endswith("…"))


class InspectorTests(unittest.TestCase):
    def _write(self, path: Path, records: list[dict[str, object]]) -> None:
        path.write_text("".join(f"{json.dumps(record)}\n" for record in records), encoding="utf-8")

    def test_events_are_range_scoped_redacted_and_optionally_raw(self) -> None:
        records = [
            {
                "timestamp": "2026-08-10T10:00:00Z",
                "type": "session_meta",
                "payload": {"id": "session"},
            },
            {
                "timestamp": "2026-08-10T10:01:00Z",
                "type": "response_item",
                "payload": {"type": "message", "role": "user", "id": "old", "content": "Old message"},
            },
            {
                "timestamp": "2026-08-10T11:01:00Z",
                "type": "response_item",
                "payload": {
                    "type": "message",
                    "role": "user",
                    "id": "injected",
                    "content": "<environment_context>hidden",
                },
            },
            {
                "timestamp": "2026-08-10T11:02:00Z",
                "type": "response_item",
                "payload": {
                    "type": "message",
                    "role": "user",
                    "id": "user",
                    "content": "Use token=sk-abcdefghijklmnopqrstuvwxyz",
                },
            },
            {
                "timestamp": "2026-08-10T11:03:00Z",
                "type": "response_item",
                "payload": {
                    "type": "custom_tool_call",
                    "name": "exec",
                    "call_id": "call",
                    "input": {"cmd": "echo secret"},
                },
            },
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "session.jsonl"
            self._write(path, records)
            safe = extract_events([path], since="2026-08-10T11:00:00Z")
            raw = extract_events([path], since="2026-08-10T11:00:00Z", redact=False)

        self.assertEqual([event["kind"] for event in safe], ["user", "tool"])
        self.assertEqual(safe[0]["preview"], "Use token=[REDACTED]")
        self.assertNotIn("input", safe[1])
        self.assertIn("sk-abcdefghijklmnopqrstuvwxyz", raw[0]["preview"])
        self.assertEqual(raw[1]["input"], {"cmd": "echo secret"})

    def test_summary_collects_current_metrics_and_token_delta(self) -> None:
        records: list[dict[str, object]] = [
            {"timestamp": "2026-08-10T09:00:00Z", "type": "session_meta", "payload": {"id": "session"}},
            {
                "timestamp": "2026-08-10T09:30:00Z",
                "type": "event_msg",
                "payload": {
                    "type": "token_count",
                    "info": {
                        "model_context_window": 200000,
                        "total_token_usage": {"input_tokens": 100, "output_tokens": 20, "total_tokens": 120},
                    },
                },
            },
            {
                "timestamp": "2026-08-10T10:01:00Z",
                "type": "response_item",
                "payload": {"type": "message", "role": "user", "id": "u1", "content": "Build it"},
            },
            {
                "timestamp": "2026-08-10T10:02:00Z",
                "type": "response_item",
                "payload": {"type": "message", "role": "assistant", "id": "a1", "content": "Done"},
            },
            {
                "timestamp": "2026-08-10T10:03:00Z",
                "type": "response_item",
                "payload": {"type": "custom_tool_call", "name": "exec", "call_id": "tool1", "input": "{}"},
            },
            {
                "timestamp": "2026-08-10T10:04:00Z",
                "type": "event_msg",
                "payload": {
                    "type": "task_complete",
                    "turn_id": "turn1",
                    "duration_ms": 1000,
                    "time_to_first_token_ms": 100,
                },
            },
            {
                "timestamp": "2026-08-10T10:05:00Z",
                "type": "event_msg",
                "payload": {"type": "turn_aborted", "turn_id": "turn2", "duration_ms": 500, "reason": "cancelled"},
            },
            {
                "timestamp": "2026-08-10T10:06:00Z",
                "type": "event_msg",
                "payload": {
                    "type": "item_completed",
                    "item": {
                        "type": "CommandExecution",
                        "id": "cmd1",
                        "command": ["/bin/bash", "-lc", "env FOO=bar git status"],
                        "duration": {"secs": 1, "nanos": 500000000},
                        "exit_code": 0,
                        "status": "completed",
                    },
                },
            },
            {
                "timestamp": "2026-08-10T10:07:00Z",
                "type": "event_msg",
                "payload": {
                    "type": "item_completed",
                    "item": {
                        "type": "CommandExecution",
                        "id": "cmd2",
                        "command": "cargo test",
                        "duration": {"secs": 2, "nanos": 0},
                        "exit_code": 1,
                        "status": "failed",
                    },
                },
            },
            {
                "timestamp": "2026-08-10T10:08:00Z",
                "type": "event_msg",
                "payload": {
                    "type": "item_completed",
                    "item": {
                        "type": "FileChange",
                        "id": "file1",
                        "changes": {"/tmp/a.py": {"kind": "update"}, "/tmp/b.py": {"kind": "create"}},
                        "status": "completed",
                    },
                },
            },
            {
                "timestamp": "2026-08-10T10:09:00Z",
                "type": "event_msg",
                "payload": {
                    "type": "item_completed",
                    "item": {
                        "type": "McpToolCall",
                        "id": "mcp1",
                        "server": "drive",
                        "tool": "search",
                        "duration": {"secs": 0, "nanos": 500000000},
                        "status": "failed",
                    },
                },
            },
            {"timestamp": "2026-08-10T10:10:00Z", "type": "compacted", "payload": {"id": "compact1"}},
            {
                "timestamp": "2026-08-10T10:11:00Z",
                "type": "turn_context",
                "payload": {"model": "gpt-test", "effort": "high"},
            },
            {
                "timestamp": "2026-08-10T10:12:00Z",
                "type": "event_msg",
                "payload": {"type": "user_message", "images": [1, 2], "audio": [1]},
            },
            {
                "timestamp": "2026-08-10T10:13:00Z",
                "type": "event_msg",
                "payload": {
                    "type": "token_count",
                    "info": {
                        "model_context_window": 200000,
                        "total_token_usage": {
                            "input_tokens": 150,
                            "cached_input_tokens": 10,
                            "cache_write_input_tokens": 5,
                            "output_tokens": 35,
                            "reasoning_output_tokens": 5,
                            "total_tokens": 185,
                        },
                    },
                },
            },
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "session.jsonl"
            self._write(path, records)
            row = public_summary(
                summarize_rollout(path, since="2026-08-10T10:00:00Z", until="2026-08-10T10:59:59Z", seen=set())
            )

        self.assertEqual(row["visible_messages"], 2)
        self.assertEqual(row["tool_calls"], 1)
        self.assertEqual(row["completed_turns"], 1)
        self.assertEqual(row["aborted_turns"], 1)
        self.assertEqual(row["active_duration_ms"], 1500)
        self.assertEqual(row["average_time_to_first_token_ms"], 100)
        self.assertEqual(row["input_tokens"], 50)
        self.assertEqual(row["output_tokens"], 15)
        self.assertEqual(row["total_tokens"], 65)
        self.assertTrue(row["token_delta_complete"])
        self.assertEqual(row["token_snapshots_in_range"], 1)
        self.assertEqual(row["command_executions"], 2)
        self.assertEqual(row["command_successes"], 1)
        self.assertEqual(row["command_failures"], 1)
        self.assertEqual(row["command_duration_ms"], 3500)
        self.assertEqual(row["command_families"], {"cargo": 1, "git": 1})
        self.assertFalse(row["command_families_truncated"])
        self.assertEqual(row["command_families_distinct"], 2)
        self.assertEqual(row["command_executions_omitted"], 0)
        self.assertEqual(row["files_changed"], 2)
        self.assertEqual(row["mcp_calls"], 1)
        self.assertEqual(row["mcp_failures"], 1)
        self.assertEqual(row["compactions"], 1)
        self.assertEqual(row["image_inputs"], 2)
        self.assertEqual(row["audio_inputs"], 1)
        self.assertEqual(row["models"], "gpt-test")
        self.assertEqual(row["reasoning_efforts"], "high")

    def test_marks_token_delta_incomplete_without_a_prior_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "session.jsonl"
            self._write(
                path,
                [
                    {"timestamp": "2026-08-10T09:00:00Z", "type": "session_meta", "payload": {"id": "old"}},
                    {
                        "timestamp": "2026-08-10T10:30:00Z",
                        "type": "event_msg",
                        "payload": {
                            "type": "token_count",
                            "info": {"total_token_usage": {"input_tokens": 100, "total_tokens": 100}},
                        },
                    },
                ],
            )
            row = public_summary(summarize_rollout(path, since="2026-08-10T10:00:00Z"))

        self.assertFalse(row["token_delta_complete"])
        self.assertEqual(row["total_tokens"], 100)

    def test_replay_dedupe_and_aggregate(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            paths = [Path(directory) / "one.jsonl", Path(directory) / "two.jsonl"]
            for index, path in enumerate(paths):
                self._write(
                    path,
                    [
                        {
                            "timestamp": f"2026-08-1{index}T10:00:00Z",
                            "type": "session_meta",
                            "payload": {"id": str(index)},
                        },
                        {
                            "timestamp": f"2026-08-1{index}T10:01:00Z",
                            "type": "response_item",
                            "payload": {"type": "message", "role": "user", "id": "same", "content": "Repeat"},
                        },
                    ],
                )
            seen: set[str] = set()
            rows = [summarize_rollout(path, seen=seen) for path in paths]
            aggregate = public_summary(aggregate_summaries(rows))

        self.assertEqual(aggregate["user_messages"], 1)
        self.assertEqual(aggregate["replayed_events"], 1)
        self.assertEqual(aggregate["sessions"], 2)

    def test_cli_reads_explicit_paths_from_stdin(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "session.jsonl"
            self._write(
                path,
                [{"timestamp": "2026-08-10T10:00:00Z", "type": "session_meta", "payload": {"id": "session"}}],
            )
            output = StringIO()
            with (
                patch.object(sys, "argv", ["inspect_sessions.py", "summary", "--paths-from-stdin"]),
                patch.object(sys, "stdin", StringIO(f"{path}\n")),
                redirect_stdout(output),
            ):
                self.assertEqual(inspect_sessions.main(), 0)

        self.assertEqual(json.loads(output.getvalue())["session_id"], "session")

    def test_summary_fields_counter_limits_and_tsv_parity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "session.jsonl"
            self._write(
                path,
                [
                    {"timestamp": "2026-08-10T10:00:00Z", "type": "session_meta", "payload": {"id": "session"}},
                    {
                        "timestamp": "2026-08-10T10:01:00Z",
                        "type": "event_msg",
                        "payload": {
                            "type": "item_completed",
                            "item": {
                                "type": "CommandExecution",
                                "id": "command",
                                "command": "sed -n 1p file",
                                "exit_code": 0,
                                "status": "completed",
                            },
                        },
                    },
                ],
            )
            output = StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    [
                        "inspect_sessions.py",
                        "summary",
                        str(path),
                        "--fields",
                        (
                            "sessions,first_event_at,token_delta_complete,command_families,"
                            "command_families_truncated,command_families_distinct,command_executions_omitted"
                        ),
                        "--counter-limit",
                        "0",
                        "--format",
                        "tsv",
                    ],
                ),
                redirect_stdout(output),
            ):
                self.assertEqual(inspect_sessions.main(), 0)

        header, values = output.getvalue().splitlines()
        self.assertEqual(
            header.split("\t"),
            [
                "sessions",
                "first_event_at",
                "token_delta_complete",
                "command_families",
                "command_families_truncated",
                "command_families_distinct",
                "command_executions_omitted",
            ],
        )
        self.assertEqual(
            values.split("\t"),
            ["1", "2026-08-10T10:01:00Z", "True", "{}", "True", "1", "1"],
        )

    def test_summary_requires_tools_inside_the_requested_range(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            paths = []
            for session_id, records in (
                (
                    "matching",
                    [
                        ("2026-08-10T10:01:00Z", "spawn_agent"),
                        ("2026-08-10T10:02:00Z", "exec"),
                    ],
                ),
                ("missing", [("2026-08-10T10:01:00Z", "exec")]),
                ("outside", [("2026-08-10T09:01:00Z", "spawn_agent")]),
            ):
                path = Path(directory) / f"{session_id}.jsonl"
                session_records: list[dict[str, object]] = [
                    {
                        "timestamp": "2026-08-10T09:00:00Z",
                        "type": "session_meta",
                        "payload": {"id": session_id},
                    }
                ]
                for index, (timestamp, tool) in enumerate(records):
                    session_records.append(
                        {
                            "timestamp": timestamp,
                            "type": "response_item",
                            "payload": {
                                "type": "custom_tool_call",
                                "name": tool,
                                "call_id": f"{session_id}-{index}",
                                "input": "{}",
                            },
                        }
                    )
                self._write(path, session_records)
                paths.append(path)

            output = StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    [
                        "inspect_sessions.py",
                        "summary",
                        *(str(path) for path in paths),
                        "--since",
                        "2026-08-10T10:00:00Z",
                        "--require-tool",
                        "spawn_agent",
                        "--require-tool",
                        "exec",
                        "--fields",
                        "session_id,tools",
                    ],
                ),
                redirect_stdout(output),
            ):
                self.assertEqual(inspect_sessions.main(), 0)

        rows = [json.loads(line) for line in output.getvalue().splitlines()]
        self.assertEqual(rows, [{"session_id": "matching", "tools": {"exec": 1, "spawn_agent": 1}}])

    def test_compact_summary_limits_counters_without_changing_totals(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "session.jsonl"
            records: list[dict[str, object]] = [
                {"timestamp": "2026-08-10T10:00:00Z", "type": "session_meta", "payload": {"id": "session"}}
            ]
            for index, command in enumerate(("sed", "rg", "git", "cargo", "ruff", "pytest")):
                records.append(
                    {
                        "timestamp": f"2026-08-10T10:0{index + 1}:00Z",
                        "type": "event_msg",
                        "payload": {
                            "type": "item_completed",
                            "item": {
                                "type": "CommandExecution",
                                "id": str(index),
                                "command": command,
                                "exit_code": 0,
                                "status": "completed",
                            },
                        },
                    }
                )
            self._write(path, records)
            output = StringIO()
            with (
                patch.object(
                    sys,
                    "argv",
                    ["inspect_sessions.py", "summary", str(path), "--compact"],
                ),
                redirect_stdout(output),
            ):
                self.assertEqual(inspect_sessions.main(), 0)

        row = json.loads(output.getvalue())
        self.assertEqual(list(row), list(inspect_sessions.SUMMARY_COMPACT_FIELDS))
        self.assertEqual(row["command_executions"], 6)
        self.assertEqual(len(row["command_families"]), 5)
        self.assertTrue(row["command_families_truncated"])
        self.assertEqual(row["command_families_distinct"], 6)
        self.assertEqual(row["command_executions_omitted"], 1)
        self.assertFalse(row["tools_truncated"])
        self.assertEqual(row["tools_distinct"], 0)
        self.assertEqual(row["tool_calls_omitted"], 0)
        self.assertTrue(row["token_delta_complete"])


if __name__ == "__main__":
    unittest.main()

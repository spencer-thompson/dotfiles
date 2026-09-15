"""Regression checks for activation; no calls reach the real audio server."""

import runpy
import unittest
from pathlib import Path
from unittest.mock import patch

activate = runpy.run_path(str(Path(__file__).resolve().parents[3] / ".local/bin/audio-policy"))["activate"]


def node(name, kind="Audio/Sink", **props):
    return {
        "id": 42 if kind == "Audio/Sink" else 43,
        "type": "PipeWire:Interface:Node",
        "info": {"state": "suspended", "props": {"node.name": name, "media.class": kind, **props}},
    }


def metadata(name, values):
    return {
        "props": {"metadata.name": name},
        "metadata": [{"subject": 0, "key": k, "value": v} for k, v in values.items()],
    }


READY = metadata("personal-audio", {"state": {"version": 1}})
DEFAULTS = metadata("default", {"default.audio.sink": {"name": "sony"}, "default.audio.source": {"name": "dji"}})
DEVICES = [node("sony", **{"api.bluez5.address": "AC:80:0A:5B:A8:67"}), node("dji", "Audio/Source")]


class ActivationTests(unittest.TestCase):
    def test_explicit_reload_still_refuses_capture(self):
        capture = node("mic", "Stream/Input/Audio")
        with (
            patch.dict(activate.__globals__, graph=lambda: [READY, capture], run=lambda *a: self.fail(str(a))),
            self.assertRaisesRegex(ValueError, "Finish the call"),
        ):
            activate(force=True)

    def test_explicit_reload_restores_active_policy(self):
        calls = []
        with patch.dict(
            activate.__globals__, graph=lambda: [READY, DEFAULTS, *DEVICES], run=lambda *a: calls.append(a)
        ):
            activate(force=True)
        self.assertEqual(calls, [("systemctl", "--user", "restart", "wireplumber")])

    def test_already_active_never_restarts(self):
        with patch.dict(activate.__globals__, graph=lambda: [READY], run=lambda *a: self.fail(str(a))):
            activate()

    def test_suspended_capture_and_discord_playback_prevent_restart(self):
        for stream in [
            node("mic", "Stream/Input/Audio", **{"node.passive": "false"}),
            node("call", "Stream/Output/Audio", **{"application.process.binary": "Discord"}),
        ]:
            with (
                self.subTest(stream=stream),
                patch.dict(
                    activate.__globals__, graph=lambda stream=stream: [stream], run=lambda *a: self.fail(str(a))
                ),
                self.assertRaisesRegex(ValueError, "Finish the call"),
            ):
                activate()

    def test_reconnect_and_restore_output_after_restart(self):
        calls = []
        reads = iter([[DEFAULTS, *DEVICES]] + [[READY]] * 11 + [[READY, *DEVICES], [READY, DEFAULTS, *DEVICES]])
        with (
            patch.dict(activate.__globals__, graph=lambda: next(reads), run=lambda *a: calls.append(a)),
            patch("time.sleep"),
        ):
            activate()
        self.assertEqual(
            calls,
            [
                ("systemctl", "--user", "restart", "wireplumber"),
                ("bluetoothctl", "--timeout", "6", "connect", "AC:80:0A:5B:A8:67"),
                ("wpctl", "set-default", "42"),
                ("wpctl", "set-default", "43"),
            ],
        )

    def test_missing_device_does_not_report_success(self):
        reads = iter([[DEFAULTS, *DEVICES]] + [[READY]] * 100)
        with (
            patch.dict(activate.__globals__, graph=lambda: next(reads), run=lambda *a: None),
            patch("time.sleep"),
            self.assertRaisesRegex(ValueError, "did not restore"),
        ):
            activate()

    def test_retries_when_bluetooth_accepts_request_without_restoring_sink(self):
        calls = []
        reads = iter([[DEFAULTS, *DEVICES]] + [[READY]] * 51 + [[READY, DEFAULTS, *DEVICES]])
        with (
            patch.dict(activate.__globals__, graph=lambda: next(reads), run=lambda *a: calls.append(a)),
            patch("time.sleep"),
        ):
            activate()
        connects = [c for c in calls if c[0] == "bluetoothctl"]
        self.assertEqual(len(connects), 2)


if __name__ == "__main__":
    unittest.main()

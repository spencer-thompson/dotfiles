"""Exercise DND restoration without touching the desktop's notification state."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/game-dnd.sh"


class GameDndTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = os.environ | {
            "PATH": f"{self.root}:{os.environ['PATH']}",
            "XDG_RUNTIME_DIR": str(self.root),
            "HYPRLAND_INSTANCE_SIGNATURE": "test",
        }
        self.mode = self.root / "mode"
        self.dnd = self.root / "dnd"
        self.snapshot = self.root / "dotfiles-game-dnd/test/previous"
        self.mode.write_text("false\n")
        self.dnd.write_text("off\n")
        for name, script in {
            "hyprctl": '#!/bin/sh\ncat "$XDG_RUNTIME_DIR/mode"\n',
            "noctalia": '''#!/bin/sh
case "$2" in
notification-dnd-status) cat "$XDG_RUNTIME_DIR/dnd" ;;
notification-dnd-set) printf '%s\\n' "$3" > "$XDG_RUNTIME_DIR/dnd" ;;
*) exit 1 ;;
esac
''',
        }.items():
            executable = self.root / name
            executable.write_text(script)
            executable.chmod(0o700)

    def sync(self, enabled):
        self.mode.write_text(f"{str(enabled).lower()}\n")
        subprocess.run(["bash", str(SCRIPT)], env=self.env, check=True)

    def test_restores_dnd_off(self):
        self.sync(True)
        self.assertEqual(self.dnd.read_text().strip(), "on")
        self.sync(False)
        self.assertEqual(self.dnd.read_text().strip(), "off")
        self.assertFalse(self.snapshot.exists())

    def test_preserves_existing_dnd_on(self):
        self.dnd.write_text("on\n")
        self.sync(True)
        self.sync(False)
        self.assertEqual(self.dnd.read_text().strip(), "on")

    def test_repeated_start_preserves_original_snapshot(self):
        self.sync(True)
        self.sync(True)
        self.sync(False)
        self.assertEqual(self.dnd.read_text().strip(), "off")

    def test_respects_manual_off_while_gaming(self):
        self.dnd.write_text("on\n")
        self.sync(True)
        self.dnd.write_text("off\n")
        self.sync(False)
        self.assertEqual(self.dnd.read_text().strip(), "off")

    def test_inactive_without_snapshot_leaves_preference_alone(self):
        self.dnd.write_text("on\n")
        self.sync(False)
        self.assertEqual(self.dnd.read_text().strip(), "on")

    def test_unavailable_status_does_not_change_dnd(self):
        self.dnd.write_text("unavailable\n")
        with self.assertRaises(subprocess.CalledProcessError):
            self.sync(True)
        self.assertFalse(self.snapshot.exists())
        self.assertEqual(self.dnd.read_text().strip(), "unavailable")


if __name__ == "__main__":
    unittest.main()

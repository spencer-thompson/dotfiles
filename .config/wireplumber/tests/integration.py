"""Run real PipeWire/WirePlumber in a private, hardware-free test session."""

import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CLI = ROOT / ".local/bin/audio-policy"


def main():
    processes, logs = [], []
    with tempfile.TemporaryDirectory(prefix="audio-policy-test-") as tmp:
        base = Path(tmp)
        config = base / "config/wireplumber"
        fragments = config / "wireplumber.conf.d"
        fragments.mkdir(parents=True)
        shutil.copy("/usr/share/wireplumber/wireplumber.conf", config)
        shutil.copy(ROOT / ".config/wireplumber/wireplumber.conf.d/90-personal-audio.conf", fragments)
        (fragments / "99-test.conf").write_text("""
wireplumber.profiles = { main = {
 hardware.audio = disabled
 hardware.bluetooth = disabled
 hardware.video-capture = disabled
 support.session-services = disabled
} }
""")
        env = dict(
            os.environ,
            XDG_RUNTIME_DIR=tmp,
            PIPEWIRE_RUNTIME_DIR=tmp,
            PIPEWIRE_REMOTE="pipewire-0",
            XDG_CONFIG_HOME=str(base / "config"),
            XDG_STATE_HOME=str(base / "state"),
            WIREPLUMBER_CONFIG_DIR=str(config),
            WIREPLUMBER_DATA_DIR=str(ROOT / ".local/share/wireplumber") + ":/usr/share/wireplumber",
            PULSE_SERVER="unix:" + tmp + "/pulse/native",
            DBUS_SYSTEM_BUS_ADDRESS="unix:path=" + tmp + "/no-system-bus",
            WIREPLUMBER_DEBUG="s-personal-audio:D,s-linking:D",
        )

        def run(*args):
            return subprocess.run(
                [str(a) for a in args], env=env, capture_output=True, text=True, check=True, timeout=10
            ).stdout

        def start(*args):
            log = open(base / (str(len(logs)) + ".log"), "w+")  # noqa: SIM115 -- closed in finally
            logs.append(log)
            proc = subprocess.Popen([str(a) for a in args], env=env, stdout=log, stderr=log)
            processes.append(proc)
            return proc

        def until(fn, message):
            for _ in range(70):
                try:
                    value = fn()
                    if value:
                        return value
                except (subprocess.SubprocessError, ValueError):
                    pass
                time.sleep(0.1)
            raise AssertionError(message)

        def snapshot():
            return json.loads(run(CLI, "status", "--json"))

        def dump():
            return json.loads(run("pw-dump"))

        def routed(app, target):
            objects = dump()
            nodes = {
                o["id"]: o.get("info", {}).get("props", {}) for o in objects if o["type"] == "PipeWire:Interface:Node"
            }
            sources = {i for i, p in nodes.items() if p.get("application.name") == app}
            targets = {i for i, p in nodes.items() if p.get("node.name") == target}
            return any(
                o.get("info", {}).get("output-node-id") in sources and o.get("info", {}).get("input-node-id") in targets
                for o in objects
                if o["type"] == "PipeWire:Interface:Link"
            )

        try:
            start("pipewire")
            until(lambda: (base / "pipewire-0").exists(), "private server failed")
            wp = start("wireplumber")
            until(lambda: snapshot()["ready"], "custom policy failed to load")
            run(
                "pw-cli",
                "create-node",
                "adapter",
                "{ factory.name=support.null-audio-sink node.name=test_speakers media.class=Audio/Sink object.linger=true audio.position=[FL FR] priority.session=1000 }",
            )
            until(lambda: any(d["id"] == "test_speakers" for d in snapshot()["outputs"]), "test speakers missing")
            run(CLI, "output", "test_speakers")
            for app in ("Firefox", "Spotify", "Stardew Valley", "Discord"):
                start(
                    "pw-cat",
                    "--playback",
                    "--raw",
                    "--format",
                    "s16",
                    "--channels",
                    "2",
                    "--properties",
                    f'{{ application.name="{app}" application.process.binary="{app}" }}',
                    "/dev/zero",
                )
            until(
                lambda: all(routed(a, "test_speakers") for a in ("Firefox", "Spotify", "Stardew Valley", "Discord")),
                "normal routing failed",
            )
            run(CLI, "block", "application.name:Firefox")
            until(lambda: routed("Firefox", "personal_audio_hold"), "block did not move Firefox")
            assert routed("Discord", "test_speakers")
            run(CLI, "allow", "application.name:Firefox")
            until(lambda: routed("Firefox", "test_speakers"), "allow did not restore Firefox")
            run(CLI, "game", "application.name:Stardew Valley")
            until(
                lambda: routed("Discord", "personal_audio_hold") and routed("Stardew Valley", "test_speakers"),
                "game protection failed",
            )
            run(CLI, "mix", "on")
            until(lambda: routed("Spotify", "test_speakers"), "game+Spotify mix failed")
            run(CLI, "allow", "application.name:Discord")
            until(lambda: routed("Discord", "test_speakers"), "explicit call exception failed")
            run(CLI, "release")
            until(
                lambda: all(
                    routed(a, "personal_audio_hold") for a in ("Firefox", "Spotify", "Stardew Valley", "Discord")
                ),
                "phone release failed",
            )
            run(CLI, "resume")
            until(
                lambda: routed("Stardew Valley", "test_speakers") and routed("Spotify", "test_speakers"),
                "resume failed",
            )
            assert snapshot()["output"] == "test_speakers"
            for o in dump():
                if o.get("props", {}).get("metadata.name") == "default":
                    assert not any(
                        e["key"] == "target.object" and "personal_audio_hold" in str(e) for e in o.get("metadata", [])
                    )
            run(CLI, "block", "application.name:Firefox")
            until(lambda: (base / "state/wireplumber/personal-audio-policy").exists(), "policy state not saved")
            time.sleep(1.2)
            wp.terminate()
            wp.wait(timeout=5)
            wp = start("wireplumber")
            until(
                lambda: snapshot()["ready"] and snapshot()["state"]["mode"] == "game", "saved game choice not restored"
            )
            assert snapshot()["state"]["phone"] is False
            assert snapshot()["state"]["allowed"] == {}
            run(CLI, "reset")
            until(
                lambda: all(routed(a, "test_speakers") for a in ("Firefox", "Spotify", "Stardew Valley", "Discord")),
                "reset did not restore playback",
            )
            print(
                "PASS: real routing, focus permissions, game/call protection, mix, release/resume, persistence, reset"
            )
        except Exception:
            print(json.dumps(snapshot(), indent=2))
            print(
                json.dumps(
                    [o.get("info", {}).get("props") for o in dump() if o["type"] == "PipeWire:Interface:Node"], indent=2
                )
            )
            for i, log in enumerate(logs):
                log.flush()
                log.seek(0)
                print(f"Process {i}:\n" + log.read()[-8000:])
            raise
        finally:
            for proc in reversed(processes):
                if proc.poll() is None:
                    proc.terminate()
                    try:
                        proc.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        proc.kill()
                        proc.wait()
            for log in logs:
                log.close()


if __name__ == "__main__":
    main()

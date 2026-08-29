# Hyprland Log Triage

Resolve the active log without hardcoding an instance:

```bash
hyprland_log_path="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log"
hyprland_log_start="$(wc -l < "$hyprland_log_path")"
```

Record the baseline immediately before the event or configuration experiment. Analyze only newer lines; do not dump the
whole log:

```bash
tail -n "+$((hyprland_log_start + 1))" "$hyprland_log_path" |
  rg 'ERR @|WARN @|CRIT @|direct scanout|modesetting|lagging behind'
```

Count recurring categories, then inspect a small amount of surrounding context around their first and last occurrences.
Attribute a message only when adjacent evidence supports it: for example, `getConvertedColor` following
`cursorImage request` is a cursor-conversion failure, not an application-frame failure.

Correlate the same time window with focused `hyprctl -j` state and, when relevant, application logs and
`journalctl -b -k`. Rank GPU resets, VM faults, OOMs, segfaults, and application crashes above compositor warnings.
Direct-scanout and modeset transitions are informational unless paired with a failure. Separate startup or reload bursts
from errors that persist during normal operation.

For configuration experiments, change one variable at a time. Verify the live value with `hyprctl getoption`, check `hyprctl configerrors`, and establish a fresh
baseline after each reload. Use `hyprctl descriptions` to discover options, not as authoritative live state.

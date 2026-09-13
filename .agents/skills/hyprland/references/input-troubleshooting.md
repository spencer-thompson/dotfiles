# Input troubleshooting

Consult this reference when choosing an input fallback after the preferred method fails.

Keep `wtype` and `ydotool` as fallbacks. In the Blender 5.2.1 test, wdotool handled Unicode, Ctrl+A, clicks, and exact
absolute movement. wtype typed Unicode but its Ctrl+A chord failed even with delays. ydotool handled ASCII, Ctrl+A,
and clicks, but dropped Unicode and misplaced absolute movement; it also needed a running `ydotoold`.
These are observed application-specific results, not guarantees for every app. Stop any temporary daemon after use.

local function render(s)
  s = s or {}
  local state = s.state or {}
  barWidget.setGlyph("headphones")
  barWidget.setText(state.phone and "Phone" or (state.mode or "Audio"))
  barWidget.setTooltip("Personal audio · output, mic, and app control")
end
noctalia.state.watch("snapshot", render)
render(noctalia.state.get("snapshot"))

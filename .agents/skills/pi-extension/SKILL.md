---
name: pi-extension
description: Build, explain, debug, or refine TypeScript extensions for Pi Coding Agent. Use for Pi tools, commands, lifecycle hooks, custom TUI, state, providers, or extension packaging.
---

# Pi extension

Build the smallest extension that satisfies the request.
Prefer one TypeScript file until separate modules make the code clearer.

## Workflow

1. Identify the required behavior. Choose the matching event hook, tool, command, shortcut, flag, renderer, provider,
   or `ctx.ui` component.
2. Read only the relevant sections of [references/extensions.md](references/extensions.md). Search its headings or API
   names instead of loading unrelated sections.
3. Choose scope:
   - Global: `~/.pi/agent/extensions/<name>.ts`
   - Project: `.pi/extensions/<name>.ts`, after project trust
   - Quick test: `pi -e ./path/to/extension.ts`
4. Export a default factory that receives `ExtensionAPI` and register behavior inside it.
5. Test the observable behavior. Use `/reload` for extensions in auto-discovered locations.

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.notify("Extension loaded", "info");
  });
}
```

## Guardrails

- Extensions run with the user's full permissions. Keep behavior within the user's request and authorization.
- Use current `@earendil-works/*` imports.
- Do not start processes, sockets, watchers, or timers in the factory. Start them when needed. Clean them up in an
  idempotent `session_shutdown` handler.
- Check `ctx.mode` for TUI-only components and `ctx.hasUI` for dialogs or notifications that also work in RPC mode.
- Namespace tool names, status keys, events, and persistent data to avoid collisions.
- Keep render methods fast and width-safe. Move filesystem, Git, and network work outside render paths. Request a
  rerender when cached data changes.
- Preserve other extensions where composition is possible. A custom footer, header, or editor can replace another
  extension's component.

## Reference

[references/extensions.md](references/extensions.md) contains the full official Pi extension documentation from
<https://pi.dev/docs/latest/extensions>. It covers events, contexts, API methods, tools, state, custom UI, rendering,
modes, and examples.

---
name: typst
description: Create, edit, debug, and polish Typst documents and templates. Use for Typst syntax, document structure,
  set and show rules, tables, figures, citations, CLI checks, and modern PDF design.
---

# Typst

Use semantic markup and a small visual system. Put document-wide styles in top-level `set` rules, keep `show` rules
focused, and create components only for repeated visual relationships.

## Workflow

1. Inspect the request, existing `.typ` files, output format, audience, page size, length constraints, templates, and
   assets. Preserve intentional structure, imports, labels, and package versions.
2. For a net-new document, redesign, or visual-polish task, read
   [`references/document-design.md`](references/document-design.md). Plan the pages and establish the grid, type roles,
   spacing, color roles, and recurring page anatomy before composing sections.
3. Build with semantic headings, figures, tables, references, and outlines. Use top-level defaults and reuse alignment
   points and components. Edit or rearrange content before shrinking type or line spacing.
4. When showing a working document in Zathura, run `typst watch input.typ output.pdf` alongside it and open that same
   PDF. Keep the watcher active during the editing session so Zathura reloads successful builds, then stop it when done.
5. Format and lint with Tinymist when available. For substantial documents, run the review helper, which compiles into
   `/tmp` and creates page images, a contact sheet, and PDF metadata:

   ```bash
   scripts/render-review.sh path/to/document.typ
   ```

6. Inspect the contact sheet, then every page at readable size. Fix hierarchy, density, spacing, alignment, wrapping,
   clipping, page balance, and asset problems. Rerender the whole document after shared-style or page-flow changes, then
   compile the requested output.

## Common gotchas

- A successful compile does not mean the document looks good. Visual review is required for substantial output.
- Silent font fallback changes layout. Confirm the intended fonts and verify final embedding with `pdffonts`.
- Keep asset paths relative and durable. Preserve aspect ratios and use sufficient resolution.
- Use tables for tabular data and grids for layout. Keep headings semantic and add alt text to meaningful figures.
- `set` and `show` rules are ordered and scoped. Rebuilt headings should remain blocks so they stay with following text.
- Shared style changes can reflow distant pages. Review the entire document after them.
- If Typst is unavailable, check syntax by hand and state that compilation and visual review did not run.

## Checks

Use the project formatter when configured. Do not invent one. Useful checks:

```bash
tinymist lint path/to/file.typ
typst compile path/to/file.typ path/to/file.pdf
pdfinfo path/to/file.pdf
pdffonts path/to/file.pdf
```

## References

- Read [`references/syntax.md`](references/syntax.md) for syntax, document patterns, tables, figures, math, citations,
  `context`, and debugging.
- Read [`references/document-design.md`](references/document-design.md) for net-new documents, redesigns, templates, or
  visual-polish work.
- Use the official [Typst reference](https://typst.app/docs/reference/) and
  [Tinymist documentation](https://myriad-dreamin.github.io/tinymist/) when local guidance is insufficient.

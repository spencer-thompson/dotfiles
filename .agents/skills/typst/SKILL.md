---
name: typst
description: Create, edit, debug, and polish Typst documents and templates. Use for Typst syntax, document structure,
  set and show rules, tables, figures, citations, CLI checks, and modern PDF design.
---

# Typst

Use simple markup for prose. Put broad styles in top-level `set` rules and keep `show` rules small. Move repeated styles
into a template.

Official docs to open when deeper detail is needed:
[Overview](https://typst.app/docs/),
[Syntax](https://typst.app/docs/reference/syntax/),
[Styling](https://typst.app/docs/reference/styling/),
[Scripting](https://typst.app/docs/reference/scripting/),
[Context](https://typst.app/docs/reference/context/),
[Reference](https://typst.app/docs/reference/),
[Page setup](https://typst.app/docs/guides/page-setup/),
[Table guide](https://typst.app/docs/guides/table-guide/),
[Accessibility](https://typst.app/docs/guides/accessibility/),
[Changelog](https://typst.app/docs/changelog/),
[Tinymist](https://myriad-dreamin.github.io/tinymist/).

## Workflow

1. Identify the output format, paper size, audience, assets, bibliography, and existing templates.
2. Inspect existing `.typ` files before editing. Preserve local template style, imports, labels, and package versions.
3. Put document-wide defaults at the top: `#set page(...)`, `#set text(...)`, `#set par(...)`, `#set heading(...)`.
4. Use headings, figures, tables, references, bibliographies, and outlines for structure. Style them globally with
   `set` and `show` rules.
5. Use Tinymist for diagnostics, completion, references, preview, export, and formatting when available. Format the
   `.typ` files before the final check.
6. Compile the document to a PDF in a unique `/tmp` directory. Rasterize every page and inspect the images. Check type
   scale, spacing, alignment, page balance, hierarchy, color, clipped content, awkward breaks, widows, and orphans.
7. Fix anything that looks dated, crowded, inconsistent, or accidental. Render and inspect again. Stop when the PDF is
   modern, polished, and free of visible layout problems.
8. If Typst is unavailable, check the syntax by hand and tell the user that neither compilation nor visual review ran.

## Render and inspect

Keep review files out of the project. A typical CLI pass is:

```bash
review_dir="$(mktemp -d /tmp/typst-review.XXXXXX)"
typst compile path/to/file.typ "$review_dir/output.pdf"
pdftoppm -png -r 144 "$review_dir/output.pdf" "$review_dir/page"
```

Open every generated `page-*.png` with the available image viewer. Inspect the pages at a readable size and as a set so
you catch both local defects and inconsistent rhythm across pages. For a long document, inspect every page for overflow
and broken layout. Study the title page, first content page, dense pages, pages with figures or tables, and the final
page more closely.

Use another PDF rasterizer when `pdftoppm` is missing. Do not skip visual review because the PDF compiled without
errors.

## Tinymist LSP and formatter

Prefer Tinymist as the Typst language server. Check it with `tinymist --version`; start the server with `tinymist lsp`.
Enable format-on-save in the editor or run the editor's LSP format action before handing back a document.

Tinymist formatting runs through the editor or LSP. Set `tinymist.formatterMode` to `"typstyle"`, `"typstfmt"`, or
`"disable"`. The default is `"typstyle"`; use it unless the project standardizes on `"typstfmt"`.

Useful checks:

```bash
tinymist --version
tinymist lsp --help
tinymist lint path/to/file.typ
typst compile path/to/file.typ path/to/file.pdf
```

Do not invent a formatter. If Tinymist or LSP formatting is unavailable, use the formatter configured by the project.
Otherwise, report that formatting did not run.

## Syntax reference

Read [`references/syntax.md`](references/syntax.md) for Typst syntax, set and show rules, document patterns, figures,
tables, math, bibliographies, `context`, modern document styling, and common pitfalls.

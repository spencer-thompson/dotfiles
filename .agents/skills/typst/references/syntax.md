# Typst Syntax Reference

Use this reference when creating or debugging Typst syntax, set/show rules, document patterns, figures, tables, math,
bibliography, `context`, modern minimal document styling, or common Typst pitfalls.

## Contents

- [Modes](#modes)
- [Markup](#markup)
- [Code Values](#code-values)
- [Functions And Blocks](#functions-and-blocks)
- [Control Flow](#control-flow)
- [Modules And Packages](#modules-and-packages)
- [Styling](#styling)
- [Document Patterns](#document-patterns)
- [Context And Introspection](#context-and-introspection)
- [Modern Minimal Documents](#modern-minimal-documents)
- [Common Pitfalls](#common-pitfalls)

## Modes

- Markup is the default mode for prose.
- Code expressions start with `#`: `Total: #(price * qty)`.
- Math is wrapped in `$...$`; surrounding spaces make display math: `$x^2$` inline, `$ x^2 $` block.
- Markup inside code uses content blocks: `let title = [*Report*]`.
- Code blocks use braces: `#{ let x = 2; x + 3 }`.

## Markup

````typst
= Level 1 Heading
== Level 2 Heading

Paragraphs are separated by a blank line.
_emphasis_ and *strong emphasis*

- Bullet item
+ Numbered item
/ Term: Description

`inline raw/code`
```typ
block raw/code
```

https://typst.app/
See @intro and @fig:trend.
= Introduction <intro>

Line break here \
Escape special characters with backslash: \# \$
// line comment
/* block comment */
````

## Code Values

```typst
#let title = "Annual Review"
#let enabled = true
#let missing = none
#let automatic = auto
#let width = 8cm
#let share = 65%
#let cols = (1fr, 2fr, auto)
#let person = (name: "Ada", role: "Editor")
#person.name
```

Common scalar types: booleans, integers, floats, strings, labels, lengths (`pt`, `em`, `cm`, `mm`, `in`), ratios
(`50%`), fractions (`1fr`), arrays, and dictionaries. Use a trailing comma for one-item arrays: `(only,)`.

## Functions And Blocks

```typst
#rect(width: 4cm, height: 1cm, fill: luma(230))
#text(size: 11pt, fill: navy)[Important]

#let badge(label, color: blue) = box(
  fill: color.lighten(80%),
  inset: (x: 6pt, y: 3pt),
  radius: 3pt,
)[#label]

#badge("Draft", color: orange)
```

Function calls use positional and named arguments. Content can be passed as a trailing block: `#emph[Text]` equals
`#emph([Text])`. Use `..args` to spread arrays/dictionaries into calls.

## Control Flow

```typst
#if score >= 90 [Excellent] else [Review]

#for item in items [
  - #item
]

#while condition {
  // update state
}
```

Use `{...}` when you need statements or computation. Use `[...]` when you are producing document content.

## Modules And Packages

```typst
#include "chapter.typ"
#import "theme.typ": report-template, accent
#import "@preview/example:0.1.0": add
```

Use `include` to insert another file's rendered content. Use `import` to bring definitions or modules into scope. Pin
package versions explicitly.

## Styling

### Set Rules

Use set rules for default element properties. Top-level set rules last until the end of the file; inside `{...}` or
`[...]`, they are scoped to that block.

```typst
#set page("us-letter", margin: (x: 0.9in, y: 0.85in), numbering: "1")
#set text(font: "New Computer Modern", size: 10.5pt, lang: "en")
#set par(justify: true, leading: 0.62em)
#set heading(numbering: "1.")
```

Use conditional set rules sparingly:

```typst
#let alert(body, critical: false) = {
  set text(red) if critical
  strong(body)
}
```

### Show Rules

Use show rules to restyle or transform matching elements.

```typst
#show heading.where(level: 1): set text(size: 16pt, weight: "semibold")
#show figure.caption: set text(size: 9pt)

#show heading.where(level: 1): it => block(above: 1.2em, below: 0.6em)[
  #text(size: 16pt, weight: "semibold")[#it.body]
]
```

Selector patterns:

- `show heading: set text(navy)` applies a set rule to headings.
- `show heading.where(level: 2): ...` targets elements by fields.
- `show "draft": smallcaps` transforms literal text.
- `show regex("TODO"): strong` transforms text by regex.
- `show <intro>: ...` targets a labeled element.
- `show: template` applies a whole-document template after the rule.

Keep show rules composable. Prefer separate show-set rules for simple styling over burying everything inside one
transformation.

## Document Patterns

### Minimal Template

```typst
#let accent = rgb("#2563eb")

#set page("us-letter", margin: (x: 0.9in, y: 0.85in), numbering: "1")
#set text(font: "New Computer Modern", size: 10.5pt)
#set par(justify: true, leading: 0.62em)
#set heading(numbering: "1.")

#show heading.where(level: 1): it => block(above: 1.1em, below: 0.55em)[
  #text(size: 16pt, weight: "semibold", fill: accent)[#it.body]
]
#show heading.where(level: 2): set text(size: 12pt, weight: "semibold")
#show link: set text(fill: accent)

= Title

Lead paragraph with a clear claim and enough whitespace to breathe.
```

### Figures And References

```typst
#figure(
  image("plot.png", width: 80%),
  caption: [Quarterly trend],
  alt: "Line chart showing quarterly trend.",
) <fig:trend>

As shown in @fig:trend, ...
```

Place labels immediately after the element they identify. Prefer useful label prefixes: `<fig:...>`, `<tab:...>`,
`<sec:...>`.

### Tables

```typst
#set table(
  stroke: (x, y) => if y == 0 { 0.7pt } else { 0.25pt + luma(220) },
  inset: (x: 6pt, y: 4pt),
)

#figure(
  table(
    columns: (1fr, auto, auto),
    table.header([*Metric*], [*Value*], [*Delta*]),
    [Revenue], [\$1.2M], [+8%],
    [Retention], [94%], [+2%],
  ),
  caption: [Quarterly summary],
) <tab:summary>
```

Use `table` for semantic tabular data and `grid` for visual layout. Put tables in `figure(...)` when they need captions
or references.

### Math

```typst
Inline: $E = m c^2$

$ integral_0^1 x^2 dif x = 1 / 3 $

$ A = mat(
  1, 2;
  3, 4;
) $
```

Use Typst's math names and symbol shorthands before reaching for raw Unicode. Use spaces around display equations and no
spaces for inline equations.

### Bibliography

```typst
Prior work by @knuth1984 shows ...

#bibliography("refs.bib")
```

Use citation keys with `@key`. Keep bibliography files next to the document or under a clear `refs/` directory.

## Context And Introspection

Use `context` when output depends on where it appears: counters, current page, current text language, heading state, or
measurements after layout.

```typst
#context counter(heading).get()
#context text.lang
#context locate(<fig:trend>).position()
```

Do all dependent computation inside the `context` expression. A contextual value is opaque until placed in the document,
so do not expect to inspect it like a normal value outside context.

## Modern Minimal Documents

- Start with strong hierarchy: title, section headings, body, captions, and tables should each have an obvious role.
- Use one primary type family plus fallback; avoid mixing many decorative fonts.
- Keep margins generous and line length comfortable. For US letter/A4 reports, around `0.8in` to `1in` margins and
  `10pt` to `11pt` body text usually work.
- Use one accent color, mostly black/gray text, and thin rules. Let whitespace do more work than boxes.
- Make tables quiet: fewer grid lines, clear headers, aligned numbers, compact insets, and captions outside the data.
- Prefer semantic styling with `set`/`show` rules over one-off formatting.
- Keep headers/footers nonessential; assistive technology may ignore page header/footer/background/foreground content in
  PDF output.
- Add `alt` text for meaningful figures and do not skip heading levels.

## Common Pitfalls

- `show page: ...` has no effect; configure page headers, footers, background, and foreground with `#set page(...)`.
- A top-level `= Heading` is a section heading, not necessarily the document title in exported HTML. Use the
  document/title patterns expected by the target output.
- Binary expressions in markup often need parentheses: `#(a + b)`.
- `#` expressions continue while Typst can parse more code; use `;` to end an expression before adjacent text when
  needed.
- Show and set rules are order-sensitive and scoped to the current block/file.
- In heading show rules that rebuild `it.body`, wrap the result in `block[...]` so headings stay with following content.
- Re-check the official changelog for newer Typst syntax or behavior before making version-sensitive claims.

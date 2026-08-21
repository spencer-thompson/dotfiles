# Typst document design

Use this reference for net-new documents, redesigns, templates, and visual-polish work.

## Plan before composing

- Set the page size, reading context, and target length. Give each page or spread one clear purpose.
- Choose margins, columns, gutters, and recurring alignment points.
- Define type roles, a short spacing scale, color roles, and repeating page elements.
- Follow supplied templates and style sources. Use exact provided assets instead of approximating them.
- Build only the components that repeat a meaningful visual relationship.

Useful starting points for letter or A4 documents are `0.8in` to `1in` margins, `9.5pt` to `11pt` body copy, and roughly
45 to 75 characters per line. Adjust them for the audience and medium.

## Keep the system small

- Use one main type family plus a justified display or monospace family.
- Keep related pages on the same title, intro, margin, and footer positions.
- Reuse vertical spacing between equivalent elements.
- Assign each color one job. Add secondary colors only when they carry meaning.
- Prefer whitespace, thin rules, and type contrast over boxes around every idea.
- Use full-width elements only when they deserve to interrupt the grid.

## Fit content in the right order

When a page is crowded:

1. Cut repetition.
2. Merge related sections or shorten labels.
3. Give dense material more width.
4. Remove decorative spacing or components.
5. Add a page when the length can grow.
6. Reduce type size or leading only when readability remains comfortable.

## Handle assets carefully

- Keep durable assets in a document-relative `assets/` directory.
- Preserve aspect ratios and prefer vector sources when available.
- Check font availability before layout and verify embedding with `pdffonts`.
- Validate edited SVG files and add alt text to meaningful images.

## Watch for these failures

- Card soup: every point sits in a rounded rectangle, so nothing has hierarchy.
- Component drift: similar sections use different spacing, widths, or alignment.
- Layout improvisation: each page uses unrelated columns or starting positions.
- Tiny-label hierarchy: important meaning depends on small tracked uppercase text.
- Fit-by-shrinking: type and leading are reduced instead of editing the content.
- Accidental whitespace: empty areas appear because modules were stacked without balancing the page.
- Decorative code blocks: a large panel dominates without helping the reading order.

## Review twice

First inspect the contact sheet:

- Do related pages share structure and density?
- Is emphasis deliberate across the set?
- Can the hierarchy be understood before the text is readable?

Then inspect every page at readable size:

- Check type size, line length, spacing, alignment, contrast, and page balance.
- Check tables, figures, and assets for clarity and proportion.
- Check clipping, overflow, awkward wraps, widows, and orphans.

Rerender the whole document after shared-style or page-flow changes. Stop when the set and every individual page look
intentional.

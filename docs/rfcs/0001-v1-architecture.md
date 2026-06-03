# RFC 0001: Zebraw v1 Architecture

## Status

Draft

## Context

Zebraw v1 is a full rewrite. The previous implementation proved that the package can provide line numbering, highlighting, comments, language tabs, indentation guides, themes, and experimental HTML export, but it also mixed too many responsibilities in the same functions:

- public API argument handling,
- global configuration state,
- line selection and line numbering,
- highlight/comment/header/footer normalization,
- PDF layout,
- HTML rendering,
- and export-only assets.

The rewrite should not recreate this shape with smaller files. The main goal is to define a stable internal model first, then build PDF and HTML renderers on top of it.

Open issues and pending feature requests also point in this direction:

- Multiple ranges and skipped-line rows require a proper selection model.
- Blank lines must remain visible even when line numbering is disabled.
- Language tabs need layout-level pagination behavior.
- Stroke, radius, and frame styling belong to customization rather than core code semantics.
- HTML export needs its own backend model for wrapping, copy behavior, and translation avoidance.
- Label-based continuation, as seen in Codly, is useful but should be modeled without making every line introspectable by default.

## Goals

- Build the core around source lines and visual rows, not around one renderer's grid structure.
- Let selection be expressed as functions instead of extending a single `line-range` parameter indefinitely.
- Separate layout decisions from component rendering.
- Make component override a first-class customization mechanism.
- Keep performance predictable by avoiding unnecessary state, query, measure, and content reconstruction.
- Preserve access to Typst's existing `raw.line` data and syntax-highlighted content.
- Combine measured PDF columns with `pdf.artifact` so line numbers and decorative parts are visually aligned, tagged as non-semantic, and kept out of the code column's normal selection path.

## Non-Goals

- Reimplement Typst syntax highlighting.
- Serialize raw content as YAML or another intermediate debug format.
- Make every line queryable or referenceable by default.
- Treat HTML export as a minor variation of the PDF renderer.
- Put every visual option into the top-level `zebraw` argument list.

## Architecture

The v1 pipeline should be:

```text
raw content
  -> source adapter
  -> configuration resolution
  -> selection plan
  -> annotation plan
  -> visual rows
  -> layout plan
  -> component rendering
  -> target renderer
```

The core model answers "what exists". Layout answers "where it goes". Components answer "how each part is drawn".

```text
core:
  SourceBlock
  SelectionPlan
  AnnotationPlan
  VisualRows

layout:
  frame, header, footer, gutter, code, comment, skip, language tab placement
  pagination and keep-with-body policies

components:
  frame
  gutter
  code row
  comment row
  skip row
  header
  footer
  language tab
  indentation guide

renderers:
  PDF
  HTML
  debug
```

## Source Model

The source adapter should consume Typst `raw` directly and preserve its synthesized line data.

Typst raw blocks already expose lines with:

- `number`,
- `count`,
- `text`,
- `body`.

The `body` field is important because it contains Typst's syntax-highlighted content. Zebraw should not split raw text and rebuild highlighted content itself.

Proposed model:

```typst
SourceBlock = (
  kind: "block" | "inline",
  label: none | label,
  lang: none | str,
  lines: (
    (
      source-number: int,
      source-count: int,
      text: str,
      body: content,
      indent: str,
      effective-indent: str,
    ),
  ),
)
```

`indent` is the line's literal leading whitespace after normalization. `effective-indent` is the structural indentation used by visual features such as indentation guides and hanging indentation. Blank lines should preserve their literal empty `indent`, but inherit `effective-indent` from the previous non-blank source line so visual structure does not collapse at blank rows.

## Selection

Selection should be a function-shaped abstraction.

Instead of making `line-range` handle all possible shapes, expose selector helpers and normalize them into a `SelectionPlan`.

Example API direction:

```typst
#zebraw(
  select: selectors.range(2, 8),
  raw,
)

#zebraw(
  select: selectors.ranges(
    (1, 4),
    (10, 20),
    skip: true,
  ),
  raw,
)
```

The conceptual signature is:

```typst
selector: SourceBlock -> SelectionPlan
```

Selection output:

```typst
SelectionPlan = (
  (kind: "lines", from: 2, to: 8, keep-offset: true),
  (kind: "skip", count: 5, label: [5 lines skipped]),
  (kind: "lines", from: 14, to: 20, keep-offset: true),
)
```

The v1 API does not need to preserve `line-range`. The core should only know about selector functions and `SelectionPlan`.

## Target Rendering

Rendering target selection should be explicit, not a collection of booleans.

Example API direction:

```typst
#zebraw(target: "pdf", raw)
#zebraw(target: "debug", raw)
```

The initial v1 slice supports `pdf` and `debug`. The old `debug: true` style should not be preserved; future targets such as HTML should extend the same `target` axis.

## Annotations

Annotations should use the same function-shaped model as selection. `highlight-lines` should not remain a separate parameter because it would recreate a second range language.

Example API direction:

```typst
#zebraw(
  annotate: annotations.compose(
    annotations.highlight(selectors.line(3)),
    annotations.comment(selectors.range(8, 12), [important path]),
    annotations.fill(selectors.lines(14, 18), rgb("#ffeeaa")),
  ),
  raw,
)
```

The conceptual signature is:

```typst
annotation: SourceBlock -> AnnotationPlan
```

Line-level annotations should normalize into one record per source line. They should not be stored as parallel dictionaries such as `comments`, `colors`, and `highlighted`.

```typst
LineAnnotation = (
  highlighted: bool,
  fill: none | color,
  comment: none | content,
)

AnnotationPlan = (
  lines: (
    "3": LineAnnotation,
    "8": LineAnnotation,
  ),
  block: (
    header: none | content,
    footer: none | content,
  ),
)
```

This keeps override and layout code simple: selector helpers decide which source lines receive a patch, while renderers and components read a single annotation record.

## Visual Rows

The most important internal model is `VisualRow`. A source line and a visible row are not always the same thing.

Rows can be:

- code rows,
- blank rows,
- comment rows,
- skip rows,
- header/footer rows if the renderer benefits from treating them uniformly.

Blank lines must be explicit rows. This prevents regressions where blank lines collapse when line numbers are disabled.

Proposed shape:

```typst
VisualRow = (
  kind: "code" | "blank" | "comment" | "skip",
  source-number: none | int,
  display-number: none | int | array,
  text: str,
  body: content,
  indent: str,
  effective-indent: str,
  annotation: none | LineAnnotation,
  copy-text: str,
)
```

The `copy-text` field is mainly for HTML and future export behavior. PDF line numbers and decoration should be rendered in the gutter/decorative path and tagged with `pdf.artifact`, but viewer copy behavior still depends on the PDF renderer's physical layout.

## Numbering

Numbering should be a strategy, not just a boolean or offset.

Possible strategies:

```typst
numbering.off()
numbering.line(offset: 0)
numbering.line(offset: 300, keep-offset: false)
numbering.custom(("A", "B", "C"), ("stable", "stable", "changed"))
numbering.continue-from(<label>)
```

The public `numbering:` parameter should receive a strategy function, not a boolean, raw array, or a separate `numbering-offset` value. Offsets and renumbering behavior belong inside the selected strategy.

`numbering.continue-from(<label>)` should support Codly-style continuation, but with a lighter implementation.

Codly's `offset-from` works by querying per-line marker elements between a labelled block and an end marker. That gives useful behavior, but it makes each line introspectable. Zebraw should avoid that as the default.

Preferred approach:

- Emit one block summary metadata marker for labelled raw blocks.
- Reuse the raw block's label for that summary marker and filter query results by metadata `kind`.
- Query only that summary for `continue-from`.
- Generate per-line reference metadata only when an explicit line-reference feature is enabled.

Conceptual summary:

```typst
metadata((
  kind: "zebraw-block-summary",
  source-lines: 37,
  visible-lines: 20,
  last-number: 42,
)) <some-label>
```

This keeps continuation block-level by default.

## Layout

Layout should decide how model parts relate spatially. It should not decide what rows exist or how a row component is drawn.

Layout responsibilities:

- gutter placement,
- code column placement,
- comment placement,
- skip row placement,
- header/footer placement,
- language tab placement,
- frame composition,
- pagination policy,
- whether the language tab must stay with the block body,
- whether comments are below lines, beside lines, or omitted in a target.

Possible API direction:

```typst
layout: layouts.with(
  gutter: (placement: "left", width: 2.8em, separator: false),
  comments: (placement: "below-line", width: 14em),
  header: (placement: "above"),
  footer: (placement: "below"),
  lang-tab: (placement: "top-right", keep-with-body: true),
)
```

The language tab page-break issue should be solved here, not in the language-tab component.
The current PDF slice supports gutter placement values `left`, `right`, and `hidden`; line-number existence still belongs to the numbering strategy, while gutter placement only controls where or whether that display column is rendered. The old boolean-style `gutter.enabled` split is intentionally removed.
The current PDF slice supports a gutter separator through `layout.gutter.separator`; it is rendered as decorative PDF artifact between gutter and body, not as part of the numbering strategy.
The current PDF slice supports comment placement values `below-line`, `beside-line`, and `hidden`. `beside-line` keeps the line annotation in the model but renders the comment component in a side column inside the corresponding code row.
The current PDF slice supports header/footer visibility as layout chrome: header is rendered above the measured body, footer below it, and either can be hidden through layout.
The current PDF slice supports `lang-tab` as chrome attached to the frame's top-right edge: it is rendered as an overlay when the source block has a language label, does not create a full-width frame-colored row, consumes no extra vertical row, and can be hidden through layout. When the tab is visible, the frame delegates its top-right outer corner to the tab instead of drawing two overlapping rounded corners.
The current PDF slice also routes frame drawing through `components.frame`; `layout.frame` still supplies layout policy such as width, clipping, and breakability, while the component owns the actual frame content.

## Components

Components render individual parts. They consume context and return content or target-specific output.

Possible API direction:

```typst
components: components.with(
  frame: my-frame,
  gutter: my-gutter,
  header: my-header,
  footer: my-footer,
  lang-tab: my-lang-tab,
  skip: my-skip-row,
)
```

Suggested component context:

```typst
ctx = (
  target: "pdf" | "html" | "debug",
  block: block-model,
  row: none | visual-row,
  layout: layout,
  style: style,
  components: components,
)
```

Default components may mark decorative PDF content with `pdf.artifact`, but a custom component owns the content it returns. If a replacement gutter or skip component should remain non-semantic in PDF, that component should preserve the artifact wrapper.
The default frame component receives `ctx.body` and `ctx.frame-radius`, so renderer-computed geometry such as the language tab's shared top-right corner remains available without hard-coding the frame shell in the renderer.

Components should not decide data semantics. For example:

- range selection belongs to core,
- blank row existence belongs to core,
- language tab pagination belongs to layout,
- language tab appearance belongs to component,
- stroke belongs to style/component customization.

## Visual Features

The old implementation had several visual features that should remain in v1, but they should not return as unrelated top-level switches.

Inventory from the previous package:

- multiple line-number columns for diff-style blocks,
- line-number separator between gutter and code,
- indentation guide lines,
- hanging indentation for wrapped or visually long code lines,
- fast-preview indentation mode,
- per-line background colors,
- comment flag and comment indentation behavior,
- language tab content, color, and font customization,
- header/footer/frame extension,
- HTML wrapping and copy button behavior.

Proposed v1 ownership:

- Multiple numbering belongs to the numbering strategy. `numbering.custom(...)` can return array display values per source line; gutter components decide how those columns are drawn.
- The line-number separator is gutter decoration. It belongs to `layout.gutter` and the default gutter/frame components, not to numbering.
- Indentation guide data belongs to the source/model layer because it depends on leading whitespace and blank-line inheritance. Rendering those guides belongs to a dedicated `indent-guide` component. Renderers should consume `effective-indent`; they should not re-parse code text.
- Hanging indentation is layout behavior for the code component. It should consume model indentation data instead of parsing code content again.
- Fast-preview is a performance/layout mode for indentation rendering. It should be explicit in the indentation layout plan, not global state.
- Per-line colors are annotations; they should continue to merge through the single `LineAnnotation` record instead of a separate `line-colors` dictionary.
- Comment flags and comment indentation are comment component choices. The model should store comment content and source-line association only.
- Language appearance belongs to `components.lang-tab` and style tokens; language placement belongs to `layout.lang-tab`.
- HTML wrapping and copy buttons are HTML-target behavior, but they must consume `VisualRows.copy-text` rather than reconstructing raw text from rendered content.

## Style And Overrides

Most visual customization should use style tokens before replacing components.

Suggested shape:

```typst
style: (
  frame: (
    fill: luma(245),
    radius: 0.34em,
    stroke: none,
  ),
  row: (
    inset: (top: 0.34em, right: 0.34em, bottom: 0.34em, left: 0.34em),
    background: (luma(245), luma(250)),
    highlight: rgb("#94e2d5").lighten(70%),
  ),
  gutter: (...),
  comment: (...),
  lang-tab: (...),
)
```

`stroke` belongs here. It is a frame customization or frame component override, not a core feature.

## PDF Rendering

The previous implementation used layout measurement partly to control PDF selection and copy behavior. `pdf.artifact` is still useful because it marks line numbers and decorative labels as non-semantic PDF content, but it does not remove text glyphs from the PDF content stream and does not guarantee that a viewer will skip those glyphs during mouse selection.

Therefore `pdf.artifact` should stay in the renderer as PDF tag semantics even when measured columns are also required. Artifacts answer "is this semantic document text"; measurement answers "where do PDF glyphs land, and in which order will a viewer normally traverse them".

PDF rendering should:

- render gutter and body as separate measured columns,
- render language labels as decorative chrome outside the code column,
- measure visual row heights once so the gutter column and body column stay aligned,
- mark line numbers and decorative labels as artifacts,
- wrap artifact content inside layout cells rather than wrapping the cells themselves, so layout metadata such as `inset` and `align` remains visible to Typst,
- keep code content as real selectable content,
- make blank rows explicit rather than relying on measured gutter/code height.

This keeps the model honest while preserving the old PDF behavior: each visible row is still a `VisualRow`, but the PDF backend can choose a two-column physical layout to keep gutter text out of the code column's normal selection path.

One caveat: `pdf.artifact` expresses PDF tagging semantics, but generic text extraction tools may not honor those semantics. Local validation with qpdf 12.3.2 confirms that Typst 0.14.2 emits a tagged PDF, wraps line numbers, skip labels, and comment rows in `/Artifact BMC ... EMC`, and leaves code tokens as ordinary `/Span ... BDC` marked content. Poppler `pdftotext` still extracts artifact text from that same PDF, so viewer copy behavior and extractor compatibility need separate validation.

## HTML Rendering

HTML should be an independent backend that consumes the same `VisualRows`.

HTML-specific requirements:

- line wrapping,
- copy text without inserted empty lines,
- optional copy button,
- indentation guide overlays,
- avoiding translation for code,
- stable DOM for Firefox and Chromium,
- CSS/JS injection only when target is HTML.

The core should provide enough information for HTML without making PDF-specific assumptions.

## Performance Principles

Performance is a core design constraint.

Typst facts that matter:

- `raw` already synthesizes highlighted `raw.line` values; reuse them.
- `state.update` produces invisible content whose effect occurs in layout order.
- Reading `state`, `query`, or locations is contextual and participates in introspection.
- Typst resolves introspection through repeated document iterations and gives up after a small fixed number of attempts.
- State sequences are memoized internally, but reading state and then updating based on that contextual value can prevent convergence.
- Query results are cached by selector in the introspector, but querying many distinct per-line markers still adds work.
- Source files and many internal structures are reference-counted or copy-on-write; avoid needless reconstruction of large arrays/content values.

Design rules:

- Do one pass over raw lines to build `VisualRows`.
- Normalize selector, annotations, and numbering strategies before that pass.
- Keep `measure` renderer-local. The default PDF renderer may measure visible row heights once to keep the gutter and body columns aligned, but selector, annotation, and numbering normalization must not depend on measurement.
- Avoid per-line `query` and per-line `state`.
- Keep label continuation block-level unless line references are explicitly enabled.
- Prefer direct local override parameters over global state changes for per-block customization.
- Keep `components` pure where possible: they should not read or update state.
- Keep `layout` deterministic from model + style + target.

## Open Questions

- Exact naming: `select`, `selector`, or `range`.
- Whether line references should be a separate feature module.
- Whether HTML export should be in the initial v1 milestone or follow after the PDF renderer is stable.
- How much of `layout` should be user-replaceable versus controlled through style tokens.

## Initial Implementation Plan

1. Implement `source.typ` to adapt `raw` into `SourceBlock` without YAML serialization.
2. Implement `selectors.typ` and normalize all selection into `SelectionPlan`.
3. Implement `annotations.typ` for highlights, comments, per-line colors, header, and footer.
4. Implement `model.typ` to produce `VisualRows` in one pass.
5. Implement a minimal PDF renderer that uses measured gutter/body columns and `pdf.artifact` for gutter/decorations.
6. Add style tokens, default components, and component overrides.
7. Add layout options for gutter, comments, skip rows, header/footer chrome, language tab, and frame.
8. Add block summary metadata for label-based continuation.
9. Add visual layout/component slices for gutter separators, indentation guides, hanging indentation, and comment flags.
10. Add optional line reference metadata only if needed.
11. Add HTML renderer after the PDF model is stable and route it through the public `target` parameter.

## References

- Codly `offset-from` and range design: https://github.com/Dherse/codly
- Codly source inspected at commit `ece8099b46cd899ea99a835ebd78c57ef2dd0b74`
- Typst source inspected at commit `6ca538fc228c6b1f734e44f514c8f97de24cb77a`
- Typst `raw` implementation: https://github.com/typst/typst/blob/6ca538fc228c6b1f734e44f514c8f97de24cb77a/crates/typst-library/src/text/raw.rs
- Typst query documentation: https://typst.app/docs/reference/introspection/query/
- Typst state documentation: https://typst.app/docs/reference/introspection/state/
- Zebraw issue #21: https://github.com/hongjr03/typst-zebraw/issues/21
- Zebraw issue #23: https://github.com/hongjr03/typst-zebraw/issues/23
- Zebraw issue #31: https://github.com/hongjr03/typst-zebraw/issues/31
- Zebraw issue #33: https://github.com/hongjr03/typst-zebraw/issues/33
- Zebraw issue #45: https://github.com/hongjr03/typst-zebraw/issues/45
- Zebraw issue #46: https://github.com/hongjr03/typst-zebraw/issues/46
- Zebraw issue #47: https://github.com/hongjr03/typst-zebraw/issues/47

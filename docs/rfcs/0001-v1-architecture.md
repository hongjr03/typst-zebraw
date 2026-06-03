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
- Use `pdf.artifact` for non-copyable line numbers and decorative parts instead of layout tricks for PDF copy order.

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
  lang: none | str,
  lines: (
    (
      source-number: int,
      source-count: int,
      text: str,
      body: content,
      indent: str,
    ),
  ),
)
```

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

Legacy `line-range` can remain as a compatibility wrapper, but the core should only know about `SelectionPlan`.

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
  highlighted: bool,
  fill: none | color,
  annotation: none | content,
  copy-text: str,
)
```

The `copy-text` field is mainly for HTML and future export behavior. PDF line numbers and decoration should use `pdf.artifact` so they do not enter copied text.

## Numbering

Numbering should be a strategy, not just a boolean or offset.

Possible strategies:

```typst
numbering.none
numbering.line(offset: 0)
numbering.custom(columns)
numbering.continue-from(<label>)
```

`numbering.continue-from(<label>)` should support Codly-style continuation, but with a lighter implementation.

Codly's `offset-from` works by querying per-line marker elements between a labelled block and an end marker. That gives useful behavior, but it makes each line introspectable. Zebraw should avoid that as the default.

Preferred approach:

- Emit one block summary marker for labelled blocks.
- Query only that summary for `continue-from`.
- Generate per-line reference metadata only when an explicit line-reference feature is enabled.

Conceptual summary:

```typst
metadata((
  kind: "zebraw-block-summary",
  source-lines: 37,
  visible-lines: 20,
  last-number: 42,
)) <zebraw:some-label:end>
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
layout: layouts.default.with(
  gutter: (enabled: true, placement: "left"),
  comments: (placement: "below-line"),
  lang-tab: (placement: "attached", keep-with-body: true),
)
```

The language tab page-break issue should be solved here, not in the language-tab component.

## Components

Components render individual parts. They consume context and return content or target-specific output.

Possible API direction:

```typst
components: components.default.with(
  frame: my-frame,
  gutter: my-gutter,
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

Components should not decide data semantics. For example:

- range selection belongs to core,
- blank row existence belongs to core,
- language tab pagination belongs to layout,
- language tab appearance belongs to component,
- stroke belongs to style/component customization.

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

The previous implementation used layout measurement partly to control PDF copy order and keep line numbers out of copied text. With `pdf.artifact`, that is no longer the right foundation.

PDF rendering should:

- render one visual row at a time,
- mark line numbers and decorative elements as artifacts,
- keep code content as real selectable content,
- avoid measuring each line unless a layout option truly needs measurement,
- make blank rows explicit rather than relying on measured gutter/code height.

This simplifies the renderer and makes the model more honest: each visible row becomes one renderable unit.

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
- Avoid `measure` on the default path.
- Avoid per-line `query` and per-line `state`.
- Keep label continuation block-level unless line references are explicitly enabled.
- Prefer direct local override parameters over global state changes for per-block customization.
- Keep `components` pure where possible: they should not read or update state.
- Keep `layout` deterministic from model + style + target.

## Open Questions

- Exact naming: `select`, `selector`, or `range`.
- Whether legacy `line-range` should stay indefinitely or only through a migration period.
- Whether `numbering.continue-from(<label>)` should infer summary labels from the original block label or require an explicit Zebraw label namespace.
- Whether line references should be a separate feature module.
- Whether HTML export should be in the initial v1 milestone or follow after the PDF renderer is stable.
- How much of `layout` should be user-replaceable versus controlled through style tokens.

## Initial Implementation Plan

1. Implement `source.typ` to adapt `raw` into `SourceBlock` without YAML serialization.
2. Implement `selectors.typ` and normalize all selection into `SelectionPlan`.
3. Implement `annotations.typ` for highlights, comments, per-line colors, header, and footer.
4. Implement `model.typ` to produce `VisualRows` in one pass.
5. Implement a minimal PDF renderer that renders rows one by one and uses `pdf.artifact` for gutter/decorations.
6. Add style tokens and default components.
7. Add layout options for gutter, comments, language tab, and frame.
8. Add block summary metadata for label-based continuation.
9. Add optional line reference metadata only if needed.
10. Add HTML renderer after the PDF model is stable.

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

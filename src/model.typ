#import "selectors.typ" as selectors
#import "annotations.typ" as annotations
#import "numbering.typ" as numbering-strategies

#let _selected-lines(source, segment) = {
  let from = if segment.from == none { 1 } else { segment.from }
  let to = segment.to
  assert(from >= 1, message: "zebraw: line selectors are one-indexed")

  source.lines.slice(from - 1, if to == none { none } else { to - 1 })
}
#let _code-row(source-line, segment, annotation-plan, display-number) = {
  let annotation = annotations.line(annotation-plan, source-line.source-number)

  (
    kind: if source-line.text.trim().len() == 0 { "blank" } else { "code" },
    source-number: source-line.source-number,
    display-number: display-number(source-line, segment),
    text: source-line.text,
    body: source-line.body,
    indent: source-line.indent,
    effective-indent: source-line.effective-indent,
    annotation: annotation,
    copy-text: source-line.text,
  )
}

#let _comment-row(source-line, annotation) = (
  kind: "comment",
  source-number: source-line.source-number,
  display-number: none,
  text: "",
  body: annotation.comment,
  indent: source-line.indent,
  effective-indent: source-line.effective-indent,
  annotation: annotation,
  copy-text: "",
)

#let _skip-row(segment) = (
  kind: "skip",
  source-number: none,
  display-number: none,
  text: "",
  body: segment.label,
  indent: "",
  effective-indent: "",
  annotation: none,
  copy-text: "",
  skipped-lines: segment.count,
)

#let _summary(rows, source) = {
  let visible-lines = 0
  let last-number = none

  for row in rows {
    if row.kind == "code" or row.kind == "blank" {
      visible-lines += 1
      if type(row.display-number) == int {
        last-number = row.display-number
      }
    }
  }

  (
    kind: "zebraw-block-summary",
    source-lines: source.lines.len(),
    visible-lines: visible-lines,
    last-number: last-number,
  )
}

#let build-block-model(
  source,
  select: none,
  annotate: none,
  numbering: numbering-strategies.line(),
) = {
  let selector = if select == none { selectors.all } else { select }
  assert(type(selector) == function, message: "zebraw: select must be a selector function")

  let annotation-fn = if annotate == none { annotations.noop } else { annotate }
  assert(type(annotation-fn) == function, message: "zebraw: annotate must be an annotation function")

  let annotation-plan = annotation-fn(source)
  let display-number = numbering-strategies.resolve(numbering, source)
  let selection = selector(source)
  let rows = ()

  for segment in selection {
    if segment.kind == "skip" {
      rows.push(_skip-row(segment))
    } else if segment.kind == "lines" {
      for source-line in _selected-lines(source, segment) {
        let row = _code-row(source-line, segment, annotation-plan, display-number)
        rows.push(row)

        if row.annotation.comment != none {
          rows.push(_comment-row(source-line, row.annotation))
        }
      }
    } else {
      panic("zebraw: unsupported selection segment " + repr(segment.kind))
    }
  }

  (
    kind: source.kind,
    label: source.label,
    lang: source.lang,
    source-lines: source.lines.len(),
    selection: selection,
    annotations: annotation-plan,
    summary: _summary(rows, source),
    rows: rows,
    chrome: (
      header: annotation-plan.block.header,
      footer: annotation-plan.block.footer,
      lang-label: source.lang,
    ),
  )
}

#import "selectors.typ" as selectors
#import "annotations.typ": parse-highlight-lines, has-highlight, line-comment, line-color

#let _selected-lines(source, segment) = {
  let from = if segment.from == none { 1 } else { segment.from }
  let to = segment.to
  assert(from >= 1, message: "zebraw: line selectors are one-indexed")

  source.lines.slice(from - 1, if to == none { none } else { to - 1 })
}
#let _display-number(numbering, source-line, segment, numbering-offset, total-lines) = {
  if numbering == false {
    none
  } else if numbering == true {
    if segment.keep-offset {
      source-line.source-number + numbering-offset
    } else {
      source-line.source-number - segment.from + 1 + numbering-offset
    }
  } else if type(numbering) == array {
    numbering.map(column => {
      assert(
        column.len() == total-lines,
        message: "zebraw: custom numbering columns must match the source line count",
      )
      column.at(source-line.source-number - 1)
    })
  } else {
    numbering
  }
}

#let _code-row(source-line, segment, annotations, numbering, numbering-offset, total-lines) = {
  let comment = line-comment(annotations, source-line.source-number)
  let highlighted = has-highlight(annotations, source-line.source-number)

  (
    kind: if source-line.text.trim().len() == 0 { "blank" } else { "code" },
    source-number: source-line.source-number,
    display-number: _display-number(numbering, source-line, segment, numbering-offset, total-lines),
    text: source-line.text,
    body: source-line.body,
    indent: source-line.indent,
    highlighted: highlighted,
    fill: line-color(annotations, source-line.source-number),
    annotation: comment,
    copy-text: source-line.text,
  )
}

#let _comment-row(source-line, comment) = (
  kind: "comment",
  source-number: source-line.source-number,
  display-number: none,
  text: "",
  body: comment,
  indent: source-line.indent,
  highlighted: false,
  fill: none,
  annotation: none,
  copy-text: "",
)

#let _skip-row(segment) = (
  kind: "skip",
  source-number: none,
  display-number: none,
  text: "",
  body: segment.label,
  indent: "",
  highlighted: false,
  fill: none,
  annotation: none,
  copy-text: "",
  skipped-lines: segment.count,
)

#let build-block-model(
  source,
  select: none,
  highlight-lines: (),
  numbering: true,
  numbering-offset: 0,
) = {
  let selector = if select == none { selectors.all } else { select }
  assert(type(selector) == function, message: "zebraw: select must be a selector function")

  let annotations = parse-highlight-lines(highlight-lines)
  let selection = selector(source)
  let rows = ()

  for segment in selection {
    if segment.kind == "skip" {
      rows.push(_skip-row(segment))
    } else if segment.kind == "lines" {
      for source-line in _selected-lines(source, segment) {
        let row = _code-row(source-line, segment, annotations, numbering, numbering-offset, source.lines.len())
        rows.push(row)

        if row.annotation != none {
          rows.push(_comment-row(source-line, row.annotation))
        }
      }
    } else {
      panic("zebraw: unsupported selection segment " + repr(segment.kind))
    }
  }

  (
    kind: source.kind,
    lang: source.lang,
    source-lines: source.lines.len(),
    selection: selection,
    annotations: annotations,
    rows: rows,
    chrome: (
      header: annotations.header,
      footer: annotations.footer,
      lang-label: source.lang,
    ),
  )
}

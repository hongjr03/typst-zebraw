#let _value(value) = if value == none { "-" } else { repr(value) }

#let _has-line-annotation(annotation) = {
  annotation != none and (
    annotation.highlighted or annotation.fill != none or annotation.comment != none
  )
}

#let _row-summary(index, row) = {
  let source-number = _value(row.source-number)
  let display-number = _value(row.display-number)
  let indent-width = if row.indent == none { 0 } else { row.indent.len() }
  let highlight = if row.annotation != none and row.annotation.highlighted { "yes" } else { "no" }
  let annotation = if _has-line-annotation(row.annotation) { "yes" } else { "no" }

  (
    str(index),
    " | kind=", row.kind,
    " | src=", source-number,
    " | num=", display-number,
    " | indent=", str(indent-width),
    " | highlight=", highlight,
    " | annotation=", annotation,
    " | text=", repr(row.text),
  ).join()
}

#let render-debug(model) = {
  let rows = (
    [Zebraw debug model],
    [kind: #model.kind],
    [lang: #_value(model.lang)],
    [source lines: #model.source-lines],
    [visual rows: #model.rows.len()],
    [---],
  )

  for (index, row) in model.rows.enumerate(start: 1) {
    rows.push([#_row-summary(index, row)])
  }

  block(
    width: 100%,
    inset: 8pt,
    radius: 4pt,
    fill: luma(245),
    {
      set text(font: "DejaVu Sans Mono", size: 0.74em)
      grid(
        columns: (1fr,),
        row-gutter: 0.2em,
        ..rows,
      )
    },
  )
}

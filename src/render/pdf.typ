#let default-style = (
  background: luma(245),
  highlight: rgb("#94e2d5").lighten(70%),
  comment-background: rgb("#94e2d5").lighten(85%),
  skip-background: luma(235),
  gutter-fill: luma(120),
  inset: (top: 0.34em, right: 0.5em, bottom: 0.34em, left: 0.5em),
  radius: 0.34em,
  gutter-width: 2.4em,
  gutter-gap: 0.4em,
)

#let _style(style) = default-style + style

#let _number-content(number) = {
  if number == none {
    []
  } else if type(number) == array {
    number.map(item => [#item]).join(h(0.35em, weak: true))
  } else {
    [#number]
  }
}

#let _line-annotation(row) = row.annotation

#let _row-fill(row, style) = {
  if row.kind == "comment" {
    style.comment-background
  } else if row.kind == "skip" {
    style.skip-background
  } else if _line-annotation(row).fill != none {
    _line-annotation(row).fill
  } else if _line-annotation(row).highlighted {
    style.highlight
  } else {
    style.background
  }
}

#let _code-body(row) = {
  if row.kind == "blank" {
    [\ ]
  } else {
    row.body
  }
}

#let _render-gutter(row, fill, style) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: right + top,
    pdf.artifact(
      box(
        width: style.gutter-width,
        text(fill: style.gutter-fill, _number-content(row.display-number)),
      ),
    ),
  )
}

#let _render-code(row, fill, style) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: left + top,
    block(width: 100%, _code-body(row)),
  )
}

#let _render-comment(row, fill, style) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: left + top,
    colspan: 2,
    pdf.artifact(row.body),
  )
}

#let _render-skip(row, fill, style) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: center + horizon,
    colspan: 2,
    pdf.artifact(text(fill: style.gutter-fill, row.body)),
  )
}

#let _render-row(row, style) = {
  let fill = _row-fill(row, style)

  if row.kind == "comment" {
    (_render-comment(row, fill, style),)
  } else if row.kind == "skip" {
    (_render-skip(row, fill, style),)
  } else {
    (
      _render-gutter(row, fill, style),
      _render-code(row, fill, style),
    )
  }
}

#let render-pdf(model, style: (:)) = {
  let style = _style(style)
  let cells = ()

  for row in model.rows {
    cells += _render-row(row, style)
  }

  block(
    breakable: true,
    width: 100%,
    radius: style.radius,
    clip: true,
    fill: style.background,
    grid(
      columns: (style.gutter-width + style.gutter-gap, 1fr),
      row-gutter: 0pt,
      column-gutter: 0pt,
      ..cells,
    ),
  )
}

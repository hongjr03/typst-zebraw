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
    pdf.artifact(row.body),
  )
}

#let _render-skip(row, fill, style) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: center + horizon,
    pdf.artifact(text(fill: style.gutter-fill, row.body)),
  )
}

#let _render-body(row, fill, style) = {
  if row.kind == "comment" {
    _render-comment(row, fill, style)
  } else if row.kind == "skip" {
    _render-skip(row, fill, style)
  } else {
    _render-code(row, fill, style)
  }
}

#let _render-row-for-measure(row, gutter-width, style) = {
  let fill = _row-fill(row, style)

  if gutter-width == 0pt {
    grid(
      columns: (1fr,),
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-body(row, fill, style),
    )
  } else {
    grid(
      columns: (gutter-width, 1fr),
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-gutter(row, fill, style),
      _render-body(row, fill, style),
    )
  }
}

#let _gutter-width(rows, style) = {
  let has-gutter = false
  for row in rows {
    if row.display-number != none {
      has-gutter = true
    }
  }

  if has-gutter {
    style.gutter-width + style.gutter-gap
  } else {
    0pt
  }
}

#let _render-gutter-column(rows, heights, style) = {
  let cells = ()
  for row in rows {
    cells.push(_render-gutter(row, _row-fill(row, style), style))
  }

  grid(
    columns: (1fr,),
    rows: heights,
    row-gutter: 0pt,
    column-gutter: 0pt,
    ..cells,
  )
}

#let _render-body-column(rows, heights, style) = {
  let cells = ()
  for row in rows {
    let fill = _row-fill(row, style)
    cells.push(_render-body(row, fill, style))
  }

  grid(
    columns: (1fr,),
    rows: heights,
    row-gutter: 0pt,
    column-gutter: 0pt,
    ..cells,
  )
}

#let _render-measured-columns(model, style) = {
  context layout(size => {
    let gutter-width = _gutter-width(model.rows, style)
    // PDF uses measured columns so gutter text is not interleaved with code text.
    let heights = model.rows.map(row => {
      measure(
        _render-row-for-measure(row, gutter-width, style),
        width: size.width,
      ).height
    })

    let body-column = _render-body-column(model.rows, heights, style)

    if gutter-width == 0pt {
      body-column
    } else {
      grid(
        columns: (gutter-width, 1fr),
        row-gutter: 0pt,
        column-gutter: 0pt,
        _render-gutter-column(model.rows, heights, style),
        body-column,
      )
    }
  })
}

#let render-pdf(model, style: (:)) = {
  let style = _style(style)

  block(
    breakable: true,
    width: 100%,
    radius: style.radius,
    clip: true,
    fill: style.background,
    _render-measured-columns(model, style),
  )
}

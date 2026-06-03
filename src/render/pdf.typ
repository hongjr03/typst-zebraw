#import "layouts.typ" as layout-presets
#import "components.typ" as component-presets

#let default-style = (
  background: luma(245),
  stroke: none,
  highlight: rgb("#94e2d5").lighten(70%),
  comment-background: rgb("#94e2d5").lighten(85%),
  skip-background: luma(235),
  gutter-fill: luma(120),
  lang-background: none,
  lang-fill: luma(80),
  lang-inset: (x: 0.5em, y: 0.24em),
  inset: (top: 0.34em, right: 0.5em, bottom: 0.34em, left: 0.5em),
  radius: 0.34em,
)

#let _style(style) = default-style + style

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

#let _ctx(model, row, style, layout-plan, components-plan) = (
  target: "pdf",
  block: model,
  row: row,
  layout: layout-plan,
  style: style,
  components: components-plan,
)

#let _render-chrome(model, slot, style, layout-plan, components-plan) = {
  let content = if slot == "header" {
    model.chrome.header
  } else {
    model.chrome.footer
  }

  let placement = if slot == "header" {
    layout-plan.header.placement
  } else {
    layout-plan.footer.placement
  }
  let expected-placement = if slot == "header" { "above" } else { "below" }

  assert(
    placement == expected-placement or placement == "hidden",
    message: "zebraw: pdf " + slot + " placement currently supports " + expected-placement + " or hidden",
  )

  if content == none or placement == "hidden" {
    []
  } else {
    let component = if slot == "header" {
      components-plan.header
    } else {
      components-plan.footer
    }

    block(
      width: 100%,
      fill: style.background,
      inset: style.inset,
      (component)(_ctx(model, none, style, layout-plan, components-plan)),
    )
  }
}

#let _render-lang-tab(model, style, layout-plan, components-plan) = {
  let placement = layout-plan.lang-tab.placement
  assert(
    placement == "attached" or placement == "hidden",
    message: "zebraw: pdf lang-tab placement currently supports attached or hidden",
  )

  if model.chrome.lang-label == none or placement == "hidden" {
    []
  } else {
    block(
      width: 100%,
      fill: style.background,
      inset: (
        top: style.inset.top,
        right: style.inset.right,
        bottom: 0pt,
        left: style.inset.left,
      ),
      align(right, (components-plan.lang-tab)(_ctx(model, none, style, layout-plan, components-plan))),
    )
  }
}

#let _render-gutter(model, row, fill, style, layout-plan, components-plan) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: right + top,
    (components-plan.gutter)(_ctx(model, row, style, layout-plan, components-plan)),
  )
}

#let _render-code(model, row, fill, style, layout-plan, components-plan) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: left + top,
    (components-plan.code)(_ctx(model, row, style, layout-plan, components-plan)),
  )
}

#let _render-comment(model, row, fill, style, layout-plan, components-plan) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: left + top,
    (components-plan.comment)(_ctx(model, row, style, layout-plan, components-plan)),
  )
}

#let _render-skip(model, row, fill, style, layout-plan, components-plan) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: center + horizon,
    (components-plan.skip)(_ctx(model, row, style, layout-plan, components-plan)),
  )
}

#let _render-body(model, row, fill, style, layout-plan, components-plan) = {
  if row.kind == "comment" {
    _render-comment(model, row, fill, style, layout-plan, components-plan)
  } else if row.kind == "skip" {
    _render-skip(model, row, fill, style, layout-plan, components-plan)
  } else {
    _render-code(model, row, fill, style, layout-plan, components-plan)
  }
}

#let _render-row-for-measure(model, row, gutter-width, style, layout-plan, components-plan) = {
  let fill = _row-fill(row, style)

  if gutter-width == 0pt {
    grid(
      columns: (1fr,),
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-body(model, row, fill, style, layout-plan, components-plan),
    )
  } else {
    grid(
      columns: (gutter-width, 1fr),
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-gutter(model, row, fill, style, layout-plan, components-plan),
      _render-body(model, row, fill, style, layout-plan, components-plan),
    )
  }
}

#let _visible-rows(rows, layout-plan) = {
  let visible = ()
  for row in rows {
    if row.kind == "comment" and layout-plan.comments.placement == "hidden" {
    } else if row.kind == "skip" and layout-plan.skip.placement == "hidden" {
    } else {
      visible.push(row)
    }
  }
  visible
}

#let _gutter-width(rows, layout-plan) = {
  let has-gutter = false
  for row in rows {
    if row.display-number != none {
      has-gutter = true
    }
  }

  if layout-plan.gutter.enabled and has-gutter {
    layout-plan.gutter.width + layout-plan.gutter.gap
  } else {
    0pt
  }
}

#let _render-gutter-column(model, rows, heights, style, layout-plan, components-plan) = {
  let cells = ()
  for row in rows {
    cells.push(_render-gutter(model, row, _row-fill(row, style), style, layout-plan, components-plan))
  }

  grid(
    columns: (1fr,),
    rows: heights,
    row-gutter: 0pt,
    column-gutter: 0pt,
    ..cells,
  )
}

#let _render-body-column(model, rows, heights, style, layout-plan, components-plan) = {
  let cells = ()
  for row in rows {
    let fill = _row-fill(row, style)
    cells.push(_render-body(model, row, fill, style, layout-plan, components-plan))
  }

  grid(
    columns: (1fr,),
    rows: heights,
    row-gutter: 0pt,
    column-gutter: 0pt,
    ..cells,
  )
}

#let _render-measured-columns(model, style, layout-plan, components-plan) = {
  context layout(size => {
    let rows = _visible-rows(model.rows, layout-plan)
    let gutter-width = _gutter-width(rows, layout-plan)
    // PDF uses measured columns so gutter text is not interleaved with code text.
    let heights = rows.map(row => {
      measure(
        _render-row-for-measure(model, row, gutter-width, style, layout-plan, components-plan),
        width: size.width,
      ).height
    })

    let body-column = _render-body-column(model, rows, heights, style, layout-plan, components-plan)

    if gutter-width == 0pt {
      body-column
    } else {
      grid(
        columns: (gutter-width, 1fr),
        row-gutter: 0pt,
        column-gutter: 0pt,
        _render-gutter-column(model, rows, heights, style, layout-plan, components-plan),
        body-column,
      )
    }
  })
}

#let render-pdf(model, style: (:), layout-plan: layout-presets.default, components-plan: component-presets.default) = {
  let style = _style(style)
  let layout-plan = layout-presets.resolve(layout-plan)
  let components-plan = component-presets.resolve(components-plan)

  block(
    breakable: layout-plan.frame.breakable,
    width: layout-plan.frame.width,
    radius: style.radius,
    clip: layout-plan.frame.clip,
    fill: style.background,
    stroke: style.stroke,
    {
      _render-chrome(model, "header", style, layout-plan, components-plan)
      _render-lang-tab(model, style, layout-plan, components-plan)
      _render-measured-columns(model, style, layout-plan, components-plan)
      _render-chrome(model, "footer", style, layout-plan, components-plan)
    },
  )
}

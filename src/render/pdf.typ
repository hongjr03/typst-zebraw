#import "layouts.typ" as layout-presets
#import "components.typ" as component-presets

#let default-style = (
  background: luma(245),
  stroke: none,
  highlight: rgb("#94e2d5").lighten(70%),
  comment-background: rgb("#94e2d5").lighten(85%),
  skip-background: luma(235),
  gutter-fill: luma(120),
  indent-guide-fill: luma(150).transparentize(45%),
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

#let _ctx(
  model,
  row,
  style,
  layout-plan,
  components-plan,
  body: none,
  frame-radius: none,
  guide-height: none,
) = (
  target: "pdf",
  block: model,
  row: row,
  body: body,
  frame-radius: frame-radius,
  guide-height: guide-height,
  layout: layout-plan,
  style: style,
  components: components-plan,
)

#let _comment-placement(layout-plan) = {
  assert(type(layout-plan.comments.indent) == bool, message: "zebraw: layout.comments.indent must be a boolean")
  let flag = layout-plan.comments.flag
  assert(
    flag == none or type(flag) == str or type(flag) == content,
    message: "zebraw: layout.comments.flag must be none, a string, or content",
  )

  let placement = layout-plan.comments.placement
  assert(
    placement == "below-line" or placement == "beside-line" or placement == "hidden",
    message: "zebraw: pdf comments placement currently supports below-line, beside-line, or hidden",
  )
  placement
}

#let _gutter-placement(layout-plan) = {
  assert(
    layout-plan.gutter.at("enabled", default: none) == none,
    message: "zebraw: layout.gutter.enabled was removed; use gutter placement hidden instead",
  )

  let placement = layout-plan.gutter.placement
  assert(
    placement == "left" or placement == "right" or placement == "hidden",
    message: "zebraw: pdf gutter placement currently supports left, right, or hidden",
  )
  placement
}

#let _gutter-separator-width(layout-plan) = {
  if layout-plan.gutter.separator {
    layout-plan.gutter.separator-width
  } else {
    0pt
  }
}

#let _gutter-total-width(layout-plan) = {
  layout-plan.gutter.width + _gutter-separator-width(layout-plan) + layout-plan.gutter.gap
}

#let _indent-guide-plan(layout-plan) = {
  let plan = layout-plan.indent-guides
  if not plan.enabled {
    return plan
  }

  assert(plan.unit > 0, message: "zebraw: layout.indent-guides.unit must be positive")
  assert(
    plan.mode == "line" or plan.mode == "fast-preview",
    message: "zebraw: pdf indent guide mode currently supports line or fast-preview",
  )
  plan
}

#let _indent-guide-columns(row, layout-plan) = {
  let plan = _indent-guide-plan(layout-plan)
  if not plan.enabled or not (row.kind == "code" or row.kind == "blank") {
    return ()
  }

  let columns = ()
  for column in range(row.effective-indent-width) {
    if calc.rem(column, plan.unit) == 0 {
      columns.push(column)
    }
  }
  columns
}

#let _code-plan(layout-plan) = {
  let plan = layout-plan.code
  assert(type(plan.hanging-indent) == bool, message: "zebraw: layout.code.hanging-indent must be a boolean")
  plan
}

#let _has-beside-comment(row, layout-plan) = {
  let is-source-row = row.kind == "code" or row.kind == "blank"
  let is-beside = _comment-placement(layout-plan) == "beside-line"
  is-source-row and is-beside and row.annotation.comment != none
}

#let _comment-row-for(row) = row + (
  kind: "comment",
  display-number: none,
  text: "",
  body: row.annotation.comment,
  copy-text: "",
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

#let _lang-tab-placement(layout-plan) = {
  let placement = layout-plan.lang-tab.placement
  assert(
    placement == "top-right" or placement == "hidden",
    message: "zebraw: pdf lang-tab placement currently supports top-right or hidden",
  )
  placement
}

#let _has-lang-tab(model, layout-plan) = {
  model.chrome.lang-label != none and _lang-tab-placement(layout-plan) != "hidden"
}

#let _frame-radius(model, style, layout-plan) = {
  if _has-lang-tab(model, layout-plan) {
    (
      top-left: style.radius,
      top-right: 0pt,
      bottom-left: style.radius,
      bottom-right: style.radius,
    )
  } else {
    style.radius
  }
}

#let _lang-tab(model, style, layout-plan, components-plan) = {
  (components-plan.lang-tab)(_ctx(model, none, style, layout-plan, components-plan))
}

#let _render-gutter(model, row, fill, style, layout-plan, components-plan) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: right + top,
    (components-plan.gutter)(_ctx(model, row, style, layout-plan, components-plan)),
  )
}

#let _render-gutter-separator(fill, style, layout-plan) = grid.cell(
  fill: fill,
  inset: 0pt,
  pdf.artifact(
    rect(
      width: layout-plan.gutter.separator-width,
      height: 100%,
      fill: style.gutter-fill.transparentize(55%),
    ),
  ),
)

#let _render-indent-guides(model, row, row-height, style, layout-plan, components-plan) = {
  if row-height == none {
    return []
  }

  let columns = _indent-guide-columns(row, layout-plan)
  if columns.len() == 0 {
    return []
  }

  context {
    let advance = measure(raw("x")).width
    for column in columns {
      place(
        left + top,
        dx: column * advance,
        dy: -style.inset.top,
        (components-plan.indent-guide)(
          _ctx(
            model,
            row,
            style,
            layout-plan,
            components-plan,
            guide-height: row-height,
          ),
        ),
      )
    }
  }
}

#let _render-code-cell(model, row, fill, style, layout-plan, components-plan, row-height: none) = {
  grid.cell(
    fill: fill,
    inset: style.inset,
    align: left + top,
    {
      _render-indent-guides(model, row, row-height, style, layout-plan, components-plan)
      (components-plan.code)(_ctx(model, row, style, layout-plan, components-plan))
    },
  )
}

#let _render-side-comment-cell(model, row, style, layout-plan, components-plan) = {
  let comment-row = _comment-row-for(row)
  grid.cell(
    fill: style.comment-background,
    inset: style.inset,
    align: left + top,
    (components-plan.comment)(_ctx(model, comment-row, style, layout-plan, components-plan)),
  )
}

#let _render-code(model, row, fill, style, layout-plan, components-plan, row-height: none) = {
  if _has-beside-comment(row, layout-plan) {
    grid.cell(
      fill: fill,
      inset: 0pt,
      align: left + top,
      grid(
        columns: (1fr, layout-plan.comments.width),
        row-gutter: 0pt,
        column-gutter: layout-plan.comments.gap,
        _render-code-cell(model, row, fill, style, layout-plan, components-plan, row-height: row-height),
        _render-side-comment-cell(model, row, style, layout-plan, components-plan),
      ),
    )
  } else {
    _render-code-cell(model, row, fill, style, layout-plan, components-plan, row-height: row-height)
  }
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

#let _render-body(model, row, fill, style, layout-plan, components-plan, row-height: none) = {
  if row.kind == "comment" {
    _render-comment(model, row, fill, style, layout-plan, components-plan)
  } else if row.kind == "skip" {
    _render-skip(model, row, fill, style, layout-plan, components-plan)
  } else {
    _render-code(model, row, fill, style, layout-plan, components-plan, row-height: row-height)
  }
}

#let _render-row-for-measure(model, row, gutter-width, style, layout-plan, components-plan) = {
  let fill = _row-fill(row, style)
  let gutter-placement = _gutter-placement(layout-plan)
  let separator-width = _gutter-separator-width(layout-plan)
  let columns = if separator-width == 0pt {
    if gutter-placement == "right" {
      (1fr, layout-plan.gutter.width + layout-plan.gutter.gap)
    } else {
      (layout-plan.gutter.width + layout-plan.gutter.gap, 1fr)
    }
  } else if gutter-placement == "right" {
    (1fr, separator-width, layout-plan.gutter.width + layout-plan.gutter.gap)
  } else {
    (layout-plan.gutter.width + layout-plan.gutter.gap, separator-width, 1fr)
  }

  if gutter-width == 0pt {
    grid(
      columns: (1fr,),
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-body(model, row, fill, style, layout-plan, components-plan),
    )
  } else if gutter-placement == "right" {
    grid(
      columns: columns,
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-body(model, row, fill, style, layout-plan, components-plan),
      if separator-width != 0pt { _render-gutter-separator(fill, style, layout-plan) },
      _render-gutter(model, row, fill, style, layout-plan, components-plan),
    )
  } else {
    grid(
      columns: columns,
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-gutter(model, row, fill, style, layout-plan, components-plan),
      if separator-width != 0pt { _render-gutter-separator(fill, style, layout-plan) },
      _render-body(model, row, fill, style, layout-plan, components-plan),
    )
  }
}

#let _visible-rows(rows, layout-plan) = {
  let comments-placement = _comment-placement(layout-plan)
  let visible = ()
  for row in rows {
    if row.kind == "comment" and comments-placement == "hidden" {
    } else if row.kind == "comment" and comments-placement == "beside-line" {
    } else if row.kind == "skip" and layout-plan.skip.placement == "hidden" {
    } else {
      visible.push(row)
    }
  }
  visible
}

#let _gutter-width(rows, layout-plan) = {
  if _gutter-placement(layout-plan) == "hidden" {
    return 0pt
  }

  let has-gutter = false
  for row in rows {
    if row.display-number != none {
      has-gutter = true
    }
  }

  if has-gutter {
    _gutter-total-width(layout-plan)
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

#let _render-gutter-separator-column(rows, heights, style, layout-plan) = {
  let cells = ()
  for row in rows {
    cells.push(_render-gutter-separator(_row-fill(row, style), style, layout-plan))
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
  for (index, row) in rows.enumerate() {
    let fill = _row-fill(row, style)
    cells.push(_render-body(model, row, fill, style, layout-plan, components-plan, row-height: heights.at(index)))
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
    let code-plan = _code-plan(layout-plan)
    let rows = _visible-rows(model.rows, layout-plan)
    let gutter-width = _gutter-width(rows, layout-plan)
    let gutter-placement = _gutter-placement(layout-plan)
    let separator-width = _gutter-separator-width(layout-plan)
    // PDF uses measured columns so gutter text is not interleaved with code text.
    let heights = rows.map(row => {
      measure(
        _render-row-for-measure(model, row, gutter-width, style, layout-plan, components-plan),
        width: size.width,
      ).height
    })

    let body-column = _render-body-column(model, rows, heights, style, layout-plan, components-plan)
    let gutter-column = _render-gutter-column(model, rows, heights, style, layout-plan, components-plan)

    if gutter-width == 0pt {
      body-column
    } else if gutter-placement == "right" and separator-width != 0pt {
      let separator-column = _render-gutter-separator-column(rows, heights, style, layout-plan)
      grid(
        columns: (1fr, separator-width, layout-plan.gutter.width + layout-plan.gutter.gap),
        row-gutter: 0pt,
        column-gutter: 0pt,
        body-column,
        separator-column,
        gutter-column,
      )
    } else if gutter-placement == "right" {
      grid(
        columns: (1fr, layout-plan.gutter.width + layout-plan.gutter.gap),
        row-gutter: 0pt,
        column-gutter: 0pt,
        body-column,
        gutter-column,
      )
    } else if separator-width != 0pt {
      let separator-column = _render-gutter-separator-column(rows, heights, style, layout-plan)
      grid(
        columns: (layout-plan.gutter.width + layout-plan.gutter.gap, separator-width, 1fr),
        row-gutter: 0pt,
        column-gutter: 0pt,
        gutter-column,
        separator-column,
        body-column,
      )
    } else {
      grid(
        columns: (layout-plan.gutter.width + layout-plan.gutter.gap, 1fr),
        row-gutter: 0pt,
        column-gutter: 0pt,
        gutter-column,
        body-column,
      )
    }
  })
}

#let _render-frame(model, style, layout-plan, components-plan) = {
  let body = {
    _render-chrome(model, "header", style, layout-plan, components-plan)
    _render-measured-columns(model, style, layout-plan, components-plan)
    _render-chrome(model, "footer", style, layout-plan, components-plan)
  }

  (components-plan.frame)(
    _ctx(
      model,
      none,
      style,
      layout-plan,
      components-plan,
      body: body,
      frame-radius: _frame-radius(model, style, layout-plan),
    ),
  )
}

#let _render-frame-with-lang-tab(model, style, layout-plan, components-plan) = {
  let frame = _render-frame(model, style, layout-plan, components-plan)

  if not _has-lang-tab(model, layout-plan) {
    frame
  } else {
    context {
      let tab = _lang-tab(model, style, layout-plan, components-plan)
      block(
        breakable: layout-plan.frame.breakable,
        width: layout-plan.frame.width,
        {
          frame
          place(top + right, dy: -measure(tab).height, tab)
        },
      )
    }
  }
}

#let render-pdf(model, style: (:), layout-plan: layout-presets.default, components-plan: component-presets.default) = {
  let style = _style(style)
  let layout-plan = layout-presets.resolve(layout-plan)
  let components-plan = component-presets.resolve(components-plan)

  _render-frame-with-lang-tab(model, style, layout-plan, components-plan)
}

#import "layouts.typ" as layout-presets
#import "components.typ" as component-presets

#let default-style = (
  background: luma(245),
  stroke: none,
  highlight: rgb("#94e2d5").lighten(70%),
  comment-background: rgb("#94e2d5").lighten(85%),
  skip-background: luma(235),
  number-fill: luma(120),
  indent-guide-fill: luma(150).transparentize(45%),
  lang-background: none,
  lang-fill: luma(80),
  lang-inset: (x: 0.5em, y: 0.24em),
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

#let _numbers-placement(layout-plan) = {
  assert(type(layout-plan.numbers.column-gutter) == length, message: "zebraw: layout.numbers.column-gutter must be a length")

  let placement = layout-plan.numbers.placement
  assert(
    placement == "start" or placement == "end" or placement == "hidden",
    message: "zebraw: pdf numbers placement currently supports start, end, or hidden",
  )
  placement
}

#let _skip-placement(layout-plan) = {
  let placement = layout-plan.skip.placement
  assert(
    placement == "body" or placement == "hidden",
    message: "zebraw: pdf skip placement currently supports body or hidden",
  )
  placement
}

#let _numbers-separator-width(layout-plan) = {
  if layout-plan.numbers.separator {
    layout-plan.numbers.separator-width
  } else {
    0pt
  }
}

#let _numbers-total-width(layout-plan) = {
  layout-plan.numbers.width + _numbers-separator-width(layout-plan) + layout-plan.numbers.gutter
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

#let _render-chrome-body(model, slot, style, layout-plan, components-plan) = {
  let component = if slot == "header" {
    components-plan.header
  } else {
    components-plan.footer
  }
  let inset = if slot == "header" {
    layout-plan.header.inset
  } else {
    layout-plan.footer.inset
  }

  grid.cell(
    fill: style.background,
    inset: inset,
    align: left + top,
    (component)(_ctx(model, none, style, layout-plan, components-plan)),
  )
}

#let _render-chrome-spacer(style) = grid.cell(
  fill: style.background,
  inset: 0pt,
  pdf.artifact([]),
)

#let _render-chrome(model, slot, numbers-width, style, layout-plan, components-plan) = {
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
    let numbers-placement = _numbers-placement(layout-plan)
    let separator-width = _numbers-separator-width(layout-plan)
    let body-cell = _render-chrome-body(model, slot, style, layout-plan, components-plan)

    if numbers-width == 0pt {
      grid(
        columns: (1fr,),
        row-gutter: 0pt,
        column-gutter: 0pt,
        body-cell,
      )
    } else if numbers-placement == "end" {
      grid(
        columns: (1fr, separator-width, layout-plan.numbers.width + layout-plan.numbers.gutter),
        row-gutter: 0pt,
        column-gutter: 0pt,
        body-cell,
        _render-chrome-spacer(style),
        _render-chrome-spacer(style),
      )
    } else {
      grid(
        columns: (layout-plan.numbers.width + layout-plan.numbers.gutter, separator-width, 1fr),
        row-gutter: 0pt,
        column-gutter: 0pt,
        _render-chrome-spacer(style),
        _render-chrome-spacer(style),
        body-cell,
      )
    }
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

#let _render-numbers(model, row, fill, style, layout-plan, components-plan) = {
  grid.cell(
    fill: fill,
    inset: layout-plan.inset,
    align: right + top,
    (components-plan.numbers)(_ctx(model, row, style, layout-plan, components-plan)),
  )
}

#let _render-number-separator(fill, style, layout-plan) = grid.cell(
  fill: fill,
  inset: 0pt,
  if layout-plan.numbers.separator {
    pdf.artifact(
      rect(
        width: layout-plan.numbers.separator-width,
        height: 100%,
        fill: style.number-fill.transparentize(55%),
      ),
    )
  },
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
        dy: -layout-plan.inset.top,
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
    inset: layout-plan.inset,
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
    inset: layout-plan.inset,
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
    inset: layout-plan.inset,
    align: left + top,
    (components-plan.comment)(_ctx(model, row, style, layout-plan, components-plan)),
  )
}

#let _render-skip(model, row, fill, style, layout-plan, components-plan) = {
  grid.cell(
    fill: fill,
    inset: layout-plan.inset,
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

#let _render-row-for-measure(model, row, numbers-width, style, layout-plan, components-plan) = {
  let fill = _row-fill(row, style)
  let numbers-placement = _numbers-placement(layout-plan)
  let separator-width = _numbers-separator-width(layout-plan)
  let columns = if numbers-placement == "end" {
    (1fr, separator-width, layout-plan.numbers.width + layout-plan.numbers.gutter)
  } else {
    (layout-plan.numbers.width + layout-plan.numbers.gutter, separator-width, 1fr)
  }

  if numbers-width == 0pt {
    grid(
      columns: (1fr,),
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-body(model, row, fill, style, layout-plan, components-plan),
    )
  } else if numbers-placement == "end" {
    grid(
      columns: columns,
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-body(model, row, fill, style, layout-plan, components-plan),
      _render-number-separator(fill, style, layout-plan),
      _render-numbers(model, row, fill, style, layout-plan, components-plan),
    )
  } else {
    grid(
      columns: columns,
      row-gutter: 0pt,
      column-gutter: 0pt,
      _render-numbers(model, row, fill, style, layout-plan, components-plan),
      _render-number-separator(fill, style, layout-plan),
      _render-body(model, row, fill, style, layout-plan, components-plan),
    )
  }
}

#let _visible-rows(rows, layout-plan) = {
  let comments-placement = _comment-placement(layout-plan)
  let skip-placement = _skip-placement(layout-plan)
  let visible = ()
  for row in rows {
    if row.kind == "comment" and comments-placement == "hidden" {
    } else if row.kind == "comment" and comments-placement == "beside-line" {
    } else if row.kind == "skip" and skip-placement == "hidden" {
    } else {
      visible.push(row)
    }
  }
  visible
}

#let _numbers-width(rows, layout-plan) = {
  if _numbers-placement(layout-plan) == "hidden" {
    return 0pt
  }

  let has-numbers = false
  for row in rows {
    if row.display-number != none {
      has-numbers = true
    }
  }

  if has-numbers {
    _numbers-total-width(layout-plan)
  } else {
    0pt
  }
}

#let _render-numbers-column(model, rows, heights, style, layout-plan, components-plan) = {
  let cells = ()
  for row in rows {
    cells.push(_render-numbers(model, row, _row-fill(row, style), style, layout-plan, components-plan))
  }

  grid(
    columns: (1fr,),
    rows: heights,
    row-gutter: 0pt,
    column-gutter: 0pt,
    ..cells,
  )
}

#let _render-number-separator-column(rows, heights, style, layout-plan) = {
  let cells = ()
  for row in rows {
    cells.push(_render-number-separator(_row-fill(row, style), style, layout-plan))
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
    let numbers-width = _numbers-width(rows, layout-plan)
    let numbers-placement = _numbers-placement(layout-plan)
    let separator-width = _numbers-separator-width(layout-plan)
    // PDF uses measured columns so number text is not interleaved with code text.
    let heights = rows.map(row => {
      measure(
        _render-row-for-measure(model, row, numbers-width, style, layout-plan, components-plan),
        width: size.width,
      ).height
    })

    let body-column = _render-body-column(model, rows, heights, style, layout-plan, components-plan)
    let numbers-column = _render-numbers-column(model, rows, heights, style, layout-plan, components-plan)

    if numbers-width == 0pt {
      body-column
    } else if numbers-placement == "end" {
      let separator-column = _render-number-separator-column(rows, heights, style, layout-plan)
      grid(
        columns: (1fr, separator-width, layout-plan.numbers.width + layout-plan.numbers.gutter),
        row-gutter: 0pt,
        column-gutter: 0pt,
        body-column,
        separator-column,
        numbers-column,
      )
    } else {
      let separator-column = _render-number-separator-column(rows, heights, style, layout-plan)
      grid(
        columns: (layout-plan.numbers.width + layout-plan.numbers.gutter, separator-width, 1fr),
        row-gutter: 0pt,
        column-gutter: 0pt,
        numbers-column,
        separator-column,
        body-column,
      )
    }
  })
}

#let _render-frame(model, style, layout-plan, components-plan) = {
  let body = {
    let rows = _visible-rows(model.rows, layout-plan)
    let numbers-width = _numbers-width(rows, layout-plan)
    _render-chrome(model, "header", numbers-width, style, layout-plan, components-plan)
    _render-measured-columns(model, style, layout-plan, components-plan)
    _render-chrome(model, "footer", numbers-width, style, layout-plan, components-plan)
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
  let components-plan = component-presets.resolve(components-plan)
  let ctx = (
    target: "pdf",
    block: model,
    style: style,
    components: components-plan,
  )

  layout-presets.render(
    layout-plan,
    ctx,
    plan => _render-frame-with-lang-tab(model, style, plan, components-plan),
  )
}

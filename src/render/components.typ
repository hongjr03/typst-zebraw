#let _number-cell(number) = {
  if number == none {
    []
  } else {
    [#number]
  }
}

#let _number-content(number, gap) = {
  if number == none {
    []
  } else if type(number) == array {
    if number.len() == 0 {
      []
    } else {
      let columns = ()
      let cells = ()
      for item in number {
        columns.push(1fr)
        cells.push(align(right, _number-cell(item)))
      }

      grid(
        columns: columns,
        column-gutter: gap,
        ..cells,
      )
    }
  } else {
    [#number]
  }
}

#let _code-body(row) = {
  if row.kind == "blank" {
    [\ ]
  } else {
    row.body
  }
}

#let gutter(ctx) = {
  pdf.artifact(
    box(
      width: ctx.layout.gutter.width,
      text(fill: ctx.style.gutter-fill, _number-content(ctx.row.display-number, ctx.layout.gutter.number-gap)),
    ),
  )
}

#let code(ctx) = {
  let body = _code-body(ctx.row)
  if not ctx.layout.code.hanging-indent or ctx.row.effective-indent-width == 0 {
    block(width: 100%, body)
  } else {
    context {
      let advance = measure(raw("x")).width
      block(
        width: 100%,
        par(
          hanging-indent: ctx.row.effective-indent-width * advance,
          justify: false,
          linebreaks: "simple",
          body,
        ),
      )
    }
  }
}

#let _comment-flag(flag) = {
  if flag == none or flag == "" {
    none
  } else if type(flag) == str {
    [#flag]
  } else {
    flag
  }
}

#let comment(ctx) = {
  let flag = _comment-flag(ctx.layout.comments.flag)
  let has-flag = flag != none
  let should-indent = ctx.layout.comments.indent and ctx.row.effective-indent-width > 0

  if not has-flag and not should-indent {
    pdf.artifact(ctx.row.body)
  } else {
    context {
      let advance = measure(raw("x")).width
      let indent = if should-indent { h(ctx.row.effective-indent-width * advance) } else { [] }
      let flag-gap = if has-flag { h(ctx.layout.comments.flag-gap) } else { [] }
      pdf.artifact([#indent#if has-flag { flag }#flag-gap#ctx.row.body])
    }
  }
}

#let skip(ctx) = pdf.artifact(text(fill: ctx.style.gutter-fill, ctx.row.body))

#let indent-guide(ctx) = {
  let guide-style = ctx.layout.indent-guides
  pdf.artifact(
    rect(
      width: guide-style.line-width,
      height: ctx.guide-height,
      fill: ctx.style.indent-guide-fill,
    ),
  )
}

#let header(ctx) = ctx.block.chrome.header

#let footer(ctx) = ctx.block.chrome.footer

#let lang-tab(ctx) = {
  let label = ctx.block.chrome.lang-label
  if label == none {
    []
  } else {
    let fill = if ctx.style.lang-background == none {
      ctx.style.comment-background
    } else {
      ctx.style.lang-background
    }

    pdf.artifact(
      box(
        inset: ctx.style.lang-inset,
        fill: fill,
        radius: (top: ctx.style.radius),
        text(fill: ctx.style.lang-fill, [#label]),
      ),
    )
  }
}

#let frame(ctx) = block(
  breakable: ctx.layout.frame.breakable,
  width: ctx.layout.frame.width,
  radius: ctx.frame-radius,
  clip: ctx.layout.frame.clip,
  fill: ctx.style.background,
  stroke: ctx.style.stroke,
  ctx.body,
)

#let default = (
  frame: frame,
  gutter: gutter,
  code: code,
  comment: comment,
  skip: skip,
  indent-guide: indent-guide,
  header: header,
  footer: footer,
  lang-tab: lang-tab,
)

#let resolve(components) = default + components

#let with(..overrides) = resolve(overrides.named())

#let _number-content(number) = {
  if number == none {
    []
  } else if type(number) == array {
    number.map(item => [#item]).join(h(0.35em, weak: true))
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
      text(fill: ctx.style.gutter-fill, _number-content(ctx.row.display-number)),
    ),
  )
}

#let code(ctx) = block(width: 100%, _code-body(ctx.row))

#let comment(ctx) = pdf.artifact(ctx.row.body)

#let skip(ctx) = pdf.artifact(text(fill: ctx.style.gutter-fill, ctx.row.body))

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

#let default = (
  gutter: gutter,
  code: code,
  comment: comment,
  skip: skip,
  header: header,
  footer: footer,
  lang-tab: lang-tab,
)

#let resolve(components) = default + components

#let with(..overrides) = resolve(overrides.named())

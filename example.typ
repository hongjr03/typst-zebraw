#import "zebraw.typ": zebraw, selectors, annotations, numbering, layouts, components

#set document(title: [Zebraw v1 example])
#set page(width: 560pt, height: auto, margin: 18pt)
#set text(size: 9pt)

#let demo-style = (
  background: rgb("#f8f8f5"),
  stroke: rgb("#dadad4") + 0.05em,
  highlight: rgb("#dff3f0"),
  comment-background: rgb("#fff1c7"),
  skip-background: rgb("#ecece8"),
  number-fill: luma(105),
  indent-guide-fill: rgb("#879aa6").transparentize(35%),
  lang-background: rgb("#eceee9"),
  lang-fill: luma(70),
  radius: 0.32em,
)

#let demo-layout = layouts.compose({
  layouts.inset((top: 0.32em, right: 0.5em, bottom: 0.32em, left: 0.5em))
  layouts.numbers(
    width: 3.8em,
    gutter: 0.45em,
    separator: true,
    separator-width: 0.045em,
    column-gutter: 0.4em,
  )
  layouts.comments(
    placement: "beside-line",
    width: 12em,
    gap: 0.55em,
    flag: [>],
    indent: true,
  )
  layouts.indent-guides(
    enabled: true,
    unit: 2,
  )
  layouts.code(
    hanging-indent: true,
  )
})

#let demo-components = components.with(
  header: ctx => text(weight: "semibold", fill: luma(60), ctx.block.chrome.header),
  footer: ctx => text(size: 7pt, fill: luma(105), ctx.block.chrome.footer),
)

#show raw: zebraw.with(
  target: "pdf",
  select: selectors.ranges(selectors.range(1, 6), selectors.range(8, none), skip-label: "{} hidden"),
  annotate: annotations.compose(
    annotations.header([model pass]),
    annotations.highlight(selectors.line(1)),
    annotations.fill(selectors.line(4), rgb("#ecf5d8")),
    annotations.comment(selectors.line(5), [blank line keeps inherited indent]),
    annotations.footer([selectors preserve source numbering across skipped lines]),
  ),
  numbering: numbering.line(offset: 0),
  style: demo-style,
  layout: demo-layout,
  components: demo-components,
)

```typ
#let render(items) = {
  items.map(item => {
    let value = normalize(item)

    if value.ready {
      emit(value)
    }
  })
}
render(dataset)
```<model-pass>

#v(0.9em)

#show raw: zebraw.with(
  target: "pdf",
  annotate: annotations.compose(
    annotations.header([continuation]),
    annotations.comment(selectors.line(2), [continues after model-pass]),
    annotations.footer([Codly-style continuation is a numbering strategy]),
  ),
  numbering: numbering.continue-from(<model-pass>),
  style: demo-style,
  layout: demo-layout,
  components: demo-components,
)

```typ
#let next = render(more)
#next.filter(item => item.ready)
```<continuation>

#v(0.9em)

#let diff-numbering = source => {
  let old = (10, 11, none, 12, 13)
  let new = (10, none, 11, 12, 13)
  ctx => (old.at(ctx.source-number - 1), new.at(ctx.source-number - 1))
}

#show raw: zebraw.with(
  target: "pdf",
  annotate: annotations.compose(
    annotations.header([diff view]),
    annotations.fill(selectors.line(2), rgb("#fee8e7")),
    annotations.fill(selectors.line(3), rgb("#e5f5df")),
    annotations.comment(selectors.line(4), [multiple columns come from numbering]),
  ),
  numbering: diff-numbering,
  style: demo-style,
  layout: layouts.compose({
    layouts.apply(demo-layout)
    layouts.numbers(width: 4.8em)
  }),
  components: demo-components,
)

```diff
 let mode = old
-let value = parse(input)
+let value = parse(source)
 render(value)
 commit(value)
```<diff-view>

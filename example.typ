#import "zebraw.typ": zebraw, selectors, annotations, numbering, layouts

#set document(title: [Zebraw v1 smoke])

#show raw: zebraw.with(
  select: selectors.ranges((1, 2), (3, none)),
  annotate: annotations.compose(
    annotations.highlight(selectors.line(1)),
    annotations.comment(selectors.line(3), [continues after a skipped blank line]),
  ),
  numbering: numbering.line(offset: 0),
  layout: layouts.with(gutter: (width: 2.8em)),
)

```typ
== Heading

#let value = 1
```<r1>

#import "zebraw.typ": zebraw, selectors, annotations, numbering, layouts

#set document(title: [Zebraw v1 smoke])
#set page(width: 520pt, height: auto, margin: 18pt)

#show raw: zebraw.with(
  target: "pdf",
  select: selectors.ranges((1, 5), (6, none)),
  annotate: annotations.compose(
    annotations.highlight(selectors.line(1)),
    annotations.comment(selectors.line(4), [local setup]),
  ),
  numbering: numbering.line(offset: 0),
  layout: layouts.with(
    gutter: (width: 2.8em, separator: true),
    comments: (placement: "beside-line", width: 12em),
    indent-guides: (enabled: true, unit: 2),
  ),
)

```txt
Heading

value:
  total = 1 + 2
  done = total > 2
end
```<r1>

#import "zebraw.typ": zebraw, selectors, annotations

#set document(title: [Zebraw v1 smoke])

#show raw: zebraw.with(
  select: selectors.ranges((1, 2), (3, none)),
  annotate: annotations.compose(
    annotations.highlight(selectors.line(1)),
    annotations.comment(selectors.line(3), [continues after a skipped blank line]),
  ),
)

#raw(block: true, `== Heading

#let value = 1`.text, lang: "typ")<r1>

#import "zebraw.typ": zebraw, selectors

#show raw: zebraw.with(
  select: selectors.ranges((1, 2), (3, none)),
  highlight-lines: (
    1,
    (3, [continues after a skipped blank line]),
  ),
)

#raw(block: true, `== Heading

#let value = 1`.text, lang: "typ")<r1>

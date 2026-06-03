#let _line-segment(from, to, keep-offset) = (
  kind: "lines",
  from: from,
  to: to,
  keep-offset: keep-offset,
)

#let _skip-segment(count, label) = (
  kind: "skip",
  count: count,
  label: label,
)

#let _skip-label(count, template) = {
  if template == none {
    [#count lines skipped]
  } else if type(template) == str {
    let parts = template.split("{}")
    if parts.len() == 2 {
      [#parts.at(0)#count#parts.at(1)]
    } else {
      [#count lines skipped]
    }
  } else {
    template
  }
}

#let all = block => (
  _line-segment(1, none, true),
)

#let range(..args) = {
  let pos = args.pos()
  let named = args.named()
  assert(pos.len() == 2, message: "zebraw: selectors.range expects start and end positional arguments")

  block => (
    _line-segment(pos.at(0), pos.at(1), named.at("keep-offset", default: true)),
  )
}

#let line(number, keep-offset: true) = range(number, number + 1, keep-offset: keep-offset)

#let lines(..numbers) = {
  let segments = ()
  for number in numbers.pos() {
    segments.push(line(number, keep-offset: numbers.named().at("keep-offset", default: true)))
  }
  ranges(..segments, skip: false)
}

#let ranges(..args) = {
  let selectors = args.pos()
  let named = args.named()
  let skip = named.at("skip", default: true)
  let skip-label = named.at("skip-label", default: "{} lines skipped")

  block => {
    let segments = ()
    let previous-end = none

    for selector in selectors {
      assert(type(selector) == function, message: "zebraw: selectors.ranges expects selector functions")

      for segment in selector(block) {
        if segment.kind == "lines" {
          if skip and previous-end != none and segment.from > previous-end {
            segments.push(_skip-segment(segment.from - previous-end, _skip-label(segment.from - previous-end, skip-label)))
          }
          previous-end = if segment.to == none { block.lines.len() + 1 } else { segment.to }
        }

        segments.push(segment)
      }
    }

    if segments.len() == 0 {
      all(block)
    } else {
      segments
    }
  }
}

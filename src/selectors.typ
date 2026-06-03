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

#let _end-bound(to, inclusive) = {
  if to == none {
    none
  } else if inclusive {
    to + 1
  } else {
    to
  }
}
#let _normalize-range(item, keep-offset, inclusive) = {
  if type(item) == int {
    _line-segment(item, item + 1, keep-offset)
  } else if type(item) == array {
    assert(item.len() == 2, message: "zebraw: range arrays must have exactly two items")
    _line-segment(
      item.at(0, default: 1),
      _end-bound(item.at(1, default: none), inclusive),
      keep-offset,
    )
  } else if type(item) == dictionary {
    let from = item.at("from", default: item.at("start", default: item.at("0", default: 1)))
    let to = item.at("to", default: item.at("end", default: item.at("1", default: none)))
    _line-segment(
      from,
      _end-bound(to, item.at("inclusive", default: inclusive)),
      item.at("keep-offset", default: keep-offset),
    )
  } else {
    panic("zebraw: unsupported range selector item " + repr(item))
  }
}

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

#let range(start: 1, end: none, keep-offset: true, inclusive: false) = {
  block => (
    _line-segment(start, _end-bound(end, inclusive), keep-offset),
  )
}

#let ranges(..args) = {
  let items = args.pos()
  let named = args.named()
  let keep-offset = named.at("keep-offset", default: true)
  let inclusive = named.at("inclusive", default: false)
  let skip = named.at("skip", default: true)
  let skip-label = named.at("skip-label", default: "{} lines skipped")

  block => {
    let segments = ()
    let previous-end = none

    for item in items {
      let segment = _normalize-range(item, keep-offset, inclusive)
      if skip and previous-end != none and segment.from > previous-end {
        segments.push(_skip-segment(segment.from - previous-end, _skip-label(segment.from - previous-end, skip-label)))
      }
      segments.push(segment)
      previous-end = if segment.to == none { block.lines.len() + 1 } else { segment.to }
    }

    if segments.len() == 0 {
      all(block)
    } else {
      segments
    }
  }
}

#let _display-line(offset, keep-offset, source-line, segment) = {
  let keep-offset = if keep-offset == auto { segment.keep-offset } else { keep-offset }

  if keep-offset {
    source-line.source-number + offset
  } else {
    source-line.source-number - segment.from + 1 + offset
  }
}

#let off() = {
  source => (source-line, segment) => none
}

#let line(offset: 0, keep-offset: auto) = {
  source => (source-line, segment) => _display-line(offset, keep-offset, source-line, segment)
}

#let custom(..columns) = {
  let columns = columns.pos()
  assert(columns.len() > 0, message: "zebraw: numbering.custom expects at least one column")

  source => {
    for column in columns {
      assert(type(column) == array, message: "zebraw: numbering.custom columns must be arrays")
      assert(
        column.len() == source.lines.len(),
        message: "zebraw: numbering.custom columns must match the source line count",
      )
    }

    (source-line, segment) => columns.map(column => column.at(source-line.source-number - 1))
  }
}

#let constant(value) = {
  source => (source-line, segment) => value
}

#let _summary-kind = "zebraw-block-summary"

#let _last-summary(target) = {
  let summaries = query(selector(target).before(here())).filter(item => {
    let is-metadata = item.func() == metadata
    let value = if is-metadata { item.value } else { none }
    is-metadata and type(value) == dictionary and value.at("kind", default: none) == _summary-kind
  })

  if summaries.len() == 0 {
    none
  } else {
    summaries.last().value
  }
}

#let continue-from(target, offset: 0, keep-offset: auto, fallback: 0) = {
  source => {
    assert(type(target) == label, message: "zebraw: numbering.continue-from expects a label")
    let summary = _last-summary(target)
    let base = if summary == none or summary.last-number == none {
      fallback
    } else {
      summary.last-number + offset
    }

    (source-line, segment) => base + _display-line(0, keep-offset, source-line, segment)
  }
}

#let resolve(strategy, source) = {
  assert(type(strategy) == function, message: "zebraw: numbering must be a numbering strategy")
  let display = strategy(source)
  assert(type(display) == function, message: "zebraw: numbering strategies must return display functions")
  display
}

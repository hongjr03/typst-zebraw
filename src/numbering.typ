#let _display-line(offset, keep-offset, source-line, segment) = {
  let keep-offset = if keep-offset == auto { segment.keep-offset } else { keep-offset }

  if keep-offset {
    source-line.source-number + offset
  } else {
    source-line.source-number - segment.from + 1 + offset
  }
}

#let _context(source, source-line, segment) = (
  source: source,
  line: source-line,
  source-number: source-line.source-number,
  number: _display-line(0, auto, source-line, segment),
  segment: segment,
)

#let _formatter(format) = {
  if format == auto {
    n => n
  } else {
    assert(type(format) == function, message: "zebraw: numbering format must be a function")
    format
  }
}

#let off() = {
  source => ctx => none
}

#let line(offset: 0, keep-offset: auto, format: auto) = {
  source => {
    let format = _formatter(format)
    ctx => format(_display-line(offset, keep-offset, ctx.line, ctx.segment))
  }
}

#let columns(..columns) = {
  let columns = columns.pos()
  assert(columns.len() > 0, message: "zebraw: numbering.columns expects at least one column")

  source => {
    for column in columns {
      assert(type(column) == array, message: "zebraw: numbering.columns columns must be arrays")
      assert(
        column.len() == source.lines.len(),
        message: "zebraw: numbering.columns columns must match the source line count",
      )
    }

    ctx => columns.map(column => column.at(ctx.source-number - 1))
  }
}

#let constant(value) = {
  source => ctx => value
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

#let continue-from(target, offset: 0, keep-offset: auto, fallback: 0, format: auto) = {
  source => {
    assert(type(target) == label, message: "zebraw: numbering.continue-from expects a label")
    let format = _formatter(format)
    let summary = _last-summary(target)
    let base = if summary == none or summary.last-number == none {
      fallback
    } else {
      summary.last-number + offset
    }

    ctx => format(base + _display-line(0, keep-offset, ctx.line, ctx.segment))
  }
}

#let resolve(strategy, source) = {
  assert(type(strategy) == function, message: "zebraw: numbering must be a strategy function")
  let display = strategy(source)
  assert(type(display) == function, message: "zebraw: numbering strategies must return a display function")
  (source-line, segment) => display(_context(source, source-line, segment))
}

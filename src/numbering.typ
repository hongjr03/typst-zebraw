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

#let resolve(strategy, source) = {
  assert(type(strategy) == function, message: "zebraw: numbering must be a numbering strategy")
  let display = strategy(source)
  assert(type(display) == function, message: "zebraw: numbering strategies must return display functions")
  display
}

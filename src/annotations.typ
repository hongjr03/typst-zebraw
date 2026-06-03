#let empty-line = (
  highlighted: false,
  fill: none,
  comment: none,
)

#let empty-plan() = (
  lines: (:),
  block: (
    header: none,
    footer: none,
  ),
)

#let _line-key(number) = str(number)

#let _line-at(plan, number) = plan.lines.at(_line-key(number), default: empty-line)

#let _with-line(plan, number, patch) = {
  let key = _line-key(number)
  let lines = (:)
  for (line-key, annotation) in plan.lines {
    lines.insert(line-key, annotation)
  }
  lines.insert(key, _line-at(plan, number) + patch)
  plan + (lines: lines)
}

#let _merge(left, right) = {
  let lines = (:)
  for (key, annotation) in left.lines {
    lines.insert(key, annotation)
  }
  for (key, annotation) in right.lines {
    lines.insert(key, lines.at(key, default: empty-line) + annotation)
  }

  (
    lines: lines,
    block: (
      header: if right.block.header != none { right.block.header } else { left.block.header },
      footer: if right.block.footer != none { right.block.footer } else { left.block.footer },
    ),
  )
}

#let _line-numbers(source, selector) = {
  assert(type(selector) == function, message: "zebraw: annotation selectors must be functions")

  let numbers = ()
  for segment in selector(source) {
    if segment.kind == "lines" {
      let from = if segment.from == none { 1 } else { segment.from }
      let to = if segment.to == none { source.lines.len() + 1 } else { segment.to }
      for line in source.lines.slice(from - 1, to - 1) {
        numbers.push(line.source-number)
      }
    }
  }
  numbers
}

#let noop = source => empty-plan()

#let compose(..annotations) = {
  source => {
    let out = empty-plan()
    for annotation in annotations.pos() {
      assert(type(annotation) == function, message: "zebraw: annotations.compose expects annotation functions")
      out = _merge(out, annotation(source))
    }
    out
  }
}

#let highlight(selector, fill: none) = {
  source => {
    let out = empty-plan()
    for number in _line-numbers(source, selector) {
      out = _with-line(out, number, (highlighted: true, fill: fill))
    }
    out
  }
}

#let fill(selector, color) = {
  source => {
    let out = empty-plan()
    for number in _line-numbers(source, selector) {
      out = _with-line(out, number, (fill: color))
    }
    out
  }
}

#let comment(selector, body, fill: none) = {
  source => {
    let out = highlight(selector, fill: fill)(source)
    for number in _line-numbers(source, selector) {
      out = _with-line(out, number, (comment: body))
    }
    out
  }
}

#let header(body) = {
  source => empty-plan() + (block: empty-plan().block + (header: body))
}

#let footer(body) = {
  source => empty-plan() + (block: empty-plan().block + (footer: body))
}

#let line(plan, number) = _line-at(plan, number)

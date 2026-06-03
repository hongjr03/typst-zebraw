#let empty-annotations = (
  highlighted: (),
  comments: (:),
  colors: (:),
  header: none,
  footer: none,
)

#let _add-line-annotation(annotations, line-number, value) = {
  annotations.highlighted.push(line-number)
  if type(value) == color {
    annotations.colors.insert(str(line-number), value)
  } else if value != none {
    annotations.comments.insert(str(line-number), value)
  }
}

#let _parse-array-item(annotations, item) = {
  if type(item) == int {
    annotations.highlighted.push(item)
  } else if type(item) == array {
    assert(item.len() >= 1, message: "zebraw: highlight tuple must contain a line number")
    let line-number = item.first()
    annotations.highlighted.push(line-number)

    for value in item.slice(1) {
      if type(value) == color {
        annotations.colors.insert(str(line-number), value)
      } else {
        annotations.comments.insert(str(line-number), value)
      }
    }
  } else if type(item) == dictionary {
    if item.keys().contains("header") {
      annotations.header = item.header
    } else if item.keys().contains("footer") {
      annotations.footer = item.footer
    } else {
      let key = item.keys().first()
      _add-line-annotation(annotations, int(key), item.at(key))
    }
  }
}

#let parse-highlight-lines(highlight-lines) = {
  let annotations = empty-annotations

  if type(highlight-lines) == int {
    annotations.highlighted.push(highlight-lines)
  } else if type(highlight-lines) == array {
    for item in highlight-lines {
      _parse-array-item(annotations, item)
    }
  } else if type(highlight-lines) == dictionary {
    for (key, value) in highlight-lines {
      if key == "header" {
        annotations.header = value
      } else if key == "footer" {
        annotations.footer = value
      } else {
        _add-line-annotation(annotations, int(key), value)
      }
    }
  } else if highlight-lines != none {
    panic("zebraw: unsupported highlight-lines value " + repr(highlight-lines))
  }

  annotations
}

#let has-highlight(annotations, number) = annotations.highlighted.contains(number)

#let line-comment(annotations, number) = annotations.comments.at(str(number), default: none)

#let line-color(annotations, number) = annotations.colors.at(str(number), default: none)

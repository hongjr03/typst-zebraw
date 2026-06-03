#let whitespace-chars = (
  "\u{0009}", // Tab
  "\u{000B}", // Vertical tab
  "\u{000C}", // Form feed
  "\u{0020}", // Space
  "\u{00A0}", // No-break space
  "\u{FEFF}", // Zero width no-break space
)

#let indentation-from-text(text) = {
  let indent = ""
  for c in text {
    if whitespace-chars.contains(c) {
      if c == "\u{FEFF}" {
        // Ignore zero width no-break space for visual indentation.
      } else if c == "\u{00A0}" or c == " " {
        indent += " "
      } else {
        indent += c
      }
    } else {
      break
    }
  }
  indent
}

#let indentation-width(indent, tab-size) = {
  let width = 0
  for c in indent {
    if c == "\u{0009}" {
      let offset = calc.rem(width, tab-size)
      width += if offset == 0 { tab-size } else { tab-size - offset }
    } else {
      width += 1
    }
  }
  width
}

#let _is-blank-line(line) = line.text.trim().len() == 0

#let _source-line(line, indent, effective-indent, tab-size) = (
  source-number: line.number,
  source-count: line.count,
  text: line.text,
  body: line.body,
  indent: indent,
  effective-indent: effective-indent,
  indent-width: indentation-width(indent, tab-size),
  effective-indent-width: indentation-width(effective-indent, tab-size),
)

#let _source-lines(raw-lines, tab-size) = {
  let lines = ()
  let inherited-indent = ""

  for line in raw-lines {
    let indent = indentation-from-text(line.text)
    let effective-indent = if _is-blank-line(line) {
      inherited-indent
    } else {
      inherited-indent = indent
      indent
    }

    lines.push(_source-line(line, indent, effective-indent, tab-size))
  }

  lines
}

#let source-from-raw(it) = {
  assert(type(it) == content and it.func() == raw, message: "zebraw: expected raw content")
  let fields = it.fields()
  let tab-size = fields.at("tab-size", default: 2)
  assert(tab-size > 0, message: "zebraw: raw tab-size must be positive")

  (
    kind: if it.block { "block" } else { "inline" },
    label: fields.at("label", default: none),
    lang: it.lang,
    tab-size: tab-size,
    lines: _source-lines(it.lines, tab-size),
  )
}

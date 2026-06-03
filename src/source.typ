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
#let source-from-raw(it) = {
  assert(type(it) == content and it.func() == raw, message: "zebraw: expected raw content")
  let fields = it.fields()

  (
    kind: if it.block { "block" } else { "inline" },
    label: fields.at("label", default: none),
    lang: it.lang,
    lines: it.lines.map(line => (
      source-number: line.number,
      source-count: line.count,
      text: line.text,
      body: line.body,
      indent: indentation-from-text(line.text),
    )),
  )
}

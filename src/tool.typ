#let line-range(start: 0, end: -1, code, lang: none) = {
  let (res-lang, res) = if type(code) == str {
    (
      lang,
      code.split("\n").slice(start, end).join("\n"),
    )
  } else if type(code) == content and code.func() == raw {
    (
      code.lang,
      code.text.split("\n").slice(start, end).join("\n"),
    )
  } else {
    assert(false, "Invalid code type")
  }
  raw(block: true, res, lang: res-lang)
}

#import "util.typ": *
#import "html/utils.typ": *


#let style-code-line(it, default-color: black) = context {
  if it.text == "" {
    return none
  }
  if it.text.trim().len() == 0 {
    return it
  }
  let style = {
    let fill = text.fill
    let weight = text.weight
    if fill != default-color {
      "color:" + fill.to-hex() + ";"
    }
    if weight != "regular" {
      "font-weight:" + weight
    }
  }
  if style != none {
    html.elem("span", attrs: (style: style), it)
  } else {
    it
  }
}

#let zebraw-html-show-inline(
  numbering: none,
  inset: none,
  background-color: none,
  highlight-color: none,
  comment-color: none,
  lang-color: none,
  comment-flag: none,
  lang: none,
  comment-font-args: none,
  lang-font-args: none,
  numbering-font-args: none,
  extend: none,
  hanging-indent: none,
  indentation: none,
  highlight-lines: (),
  numbering-offset: 0,
  header: none,
  footer: none,
  numbering-separator: none,
  line-range: (0, -1),
  wrap: true,
  block-width: 42em,
  it,
) = context {
  let (
    numbering,
    inset,
    background-color,
    highlight-color,
    comment-color,
    lang-color,
    comment-flag,
    lang,
    comment-font-args,
    lang-font-args,
    numbering-font-args,
    extend,
    hanging-indent,
    indentation,
    numbering-separator,
  ) = parse-zebraw-args(
    numbering: numbering,
    inset: inset,
    background-color: background-color,
    highlight-color: highlight-color,
    comment-color: comment-color,
    lang-color: lang-color,
    comment-flag: comment-flag,
    lang: lang,
    comment-font-args: comment-font-args,
    lang-font-args: lang-font-args,
    numbering-font-args: numbering-font-args,
    extend: extend,
    hanging-indent: hanging-indent,
    indentation: indentation,
    numbering-separator: numbering-separator,
  )

  // Does not support highlight or comments

  // Helper for creating code line elements
  let build-code-line-elem(line) = {
    // Create main line element
    line.indentation

    show text: style-code-line.with(default-color: text.fill)
    line.body
  }

  // Process lines
  let lines = tidy-lines(
    numbering,
    it.lines,
    none,
    none,
    highlight-color,
    background-color,
    comment-color,
    comment-flag,
    comment-font-args,
    numbering-offset,
    inset,
    is-html: true,
    line-range: line-range,
  )

  let attrs = (
    style: create-style(background: curr-background-color(background-color, 0).to-hex()),
  )

  if it.lang != none {
    // As suggested by whatwg, https://html.spec.whatwg.org/
    attrs.insert("class", "language-" + it.lang)
  }

  // Main code block container
  html.elem("code", attrs: attrs, lines.map(build-code-line-elem).join())
}

#let zebraw-html-show(
  numbering: none,
  inset: none,
  background-color: none,
  highlight-color: none,
  comment-color: none,
  lang-color: none,
  comment-flag: none,
  lang: none,
  comment-font-args: none,
  lang-font-args: none,
  numbering-font-args: none,
  extend: none,
  hanging-indent: none,
  indentation: none,
  highlight-lines: (),
  numbering-offset: 0,
  header: none,
  footer: none,
  numbering-separator: none,
  line-range: (0, -1),
  wrap: true,
  block-width: 42em,
  it,
) = context {
  let (
    numbering,
    inset,
    background-color,
    highlight-color,
    comment-color,
    lang-color,
    comment-flag,
    lang,
    comment-font-args,
    lang-font-args,
    numbering-font-args,
    extend,
    hanging-indent,
    indentation,
    numbering-separator,
  ) = parse-zebraw-args(
    numbering: numbering,
    inset: inset,
    background-color: background-color,
    highlight-color: highlight-color,
    comment-color: comment-color,
    lang-color: lang-color,
    comment-flag: comment-flag,
    lang: lang,
    comment-font-args: comment-font-args,
    lang-font-args: lang-font-args,
    numbering-font-args: numbering-font-args,
    extend: extend,
    hanging-indent: hanging-indent,
    indentation: indentation,
    numbering-separator: numbering-separator,
  )

  // Process highlight lines
  let (highlight-nums, comments) = tidy-highlight-lines(highlight-lines)

  // Process lines
  let lines = tidy-lines(
    numbering,
    it.lines,
    highlight-nums,
    comments,
    highlight-color,
    background-color,
    comment-color,
    comment-flag,
    comment-font-args,
    numbering-offset,
    inset,
    is-html: true,
    line-range: line-range,
  )

  // Common styles
  let numbering-width = if numbering == true {
    if it.lines.len() + numbering-offset < 100 { 1.5em } else { auto }
  } else if type(numbering) == array {
    auto
  } else {
    0
  }
  let lineno-attrs = (
    class: class-list("lineno", if numbering-separator { "sep" }),
    style: create-style(width: repr-or-str(numbering-width)),
  )

  let default-color = text.fill
  let default-bg = curr-background-color(background-color, 0)

  let create-lineno(lineno) = {
    set text(..numbering-font-args)
    html.elem("span", attrs: lineno-attrs, if type(lineno) == array {
      // todo: can be improved
      lineno.map(n => html.elem("span", n)).join()
    } else {
      [#lineno]
    })
  }

  let create-highlight(line, bg) = {
    html.elem(
      "span",
      attrs: (
        class: "hll",
        style: create-style(
          background: bg.to-hex(),
          margin: "0 " + repr-or-str(-inset.right) + " 0 " + repr-or-str(-inset.left),
          padding: "0 " + repr-or-str(inset.right) + " 0 " + repr-or-str(inset.left),
        ),
      ),
      line,
    )
  }

  // Helper for creating code line elements
  let create-code-line-elem(line) = {
    // Create main line element
    let line-elem = {
      if numbering-width != 0 {
        create-lineno(line.number)
      }

      // Code content
      line.indentation

      show linebreak: none
      show text: style-code-line.with(default-color: default-color)
      line.body
    }

    // Create optional background wrapper
    let bg = line.fill
    let is-block = false
    if bg != default-bg {
      is-block = true
      line-elem = create-highlight(line-elem, bg)
    }

    (line-elem, is-block)
  }

  // Helper functions for header/footer
  let create-header-footer(content, bg) = {
    html.elem(
      "span",
      attrs: (
        class: "header",
        style: create-style(padding: repr-or-str(inset.right) + " " + repr-or-str(inset.left), background: bg.to-hex()),
      ),
      text(..comment-font-args, content),
    )
  }

  let create-lang-label() = {
    html.elem(
      "div",
      attrs: (
        class: "zebraw-code-lang",
        style: create-style(background: lang-color.to-hex(), border-radius: repr-or-str(inset.left)),
        translate: "no",
      ),
      if type(lang) == bool { it.lang } else { lang },
    )
  }

  // Main code block container
  html.elem("div", attrs: (class: "zebraw-code-block"), {
    // Language label
    if type(lang) != bool or lang == true and it.lang != none {
      create-lang-label()
    }

    html.elem("pre", {
      let attrs = (
        style: create-style(
          background: default-bg.to-hex(),
          border-radius: repr-or-str(inset.left),
          padding: repr-or-str(inset.top)
            + " "
            + repr-or-str(inset.right)
            + " "
            + repr-or-str(inset.bottom)
            + " "
            + repr-or-str(inset.left),
        ),
      )
      let cls = class-list(if it.lang != none { "language-" + it.lang }, if wrap { "pre-wrap" })
      if cls.len() > 0 {
        attrs.class = cls
      }
      html.elem("code", attrs: attrs, {
        create-header-footer(
          if header != none { header } else { comments.at("header", default: none) },
          curr-background-color(background-color, 0),
        )
        {
          // gather code lines
          let is-prev-block = true
          for line in lines {
            let (line-elem, is-cur-block) = create-code-line-elem(line)
            if not (is-prev-block or is-cur-block) {
              "\n"
            }
            is-prev-block = is-cur-block
            line-elem
          }
        }
        create-header-footer(
          if footer != none { footer } else { comments.at("footer", default: none) },
          curr-background-color(background-color, lines.len() + 1),
        )
      })
    })
  })
}

#let zebraw-html-styles() = {
  html.elem("style", read("html/styles.css"))
}

#let zebraw-html-clipboard-copy() = {
  html.elem("script", read("html/clipboard-copy.js"))
}

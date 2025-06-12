#import "util.typ": *
#import "html-utils.typ": *


#let style-code-line(it, default-color: black) = context {
  if it.text == "" {
    return none
  }
  if it.text.trim().len() == 0 {
    return it
  }
  let fill = text.fill
  let weight = text.weight
  let style = {
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

  // Common styles
  let numbering-width = if numbering == true {
    if it.lines.len() + numbering-offset < 100 { 1.5em } else { auto }
  } else if type(numbering) == array {
    auto
  } else {
    0
  }

  let lineno-style = create-style(width: repr-or-str(numbering-width))

  let default-color = text.fill
  let default-bg = curr-background-color(background-color, 0)

  // Helper for creating code line elements
  let build-code-line-elem(line, is-background: false) = {
    // Create main line element
    let line-elem = {
      if numbering-width != 0 {
        // Line number
        set text(..numbering-font-args)
        let attrs = (class: class-list("lineno", if numbering-separator { "sep" }), style: lineno-style)
        html.elem("span", attrs: attrs, if type(line.number) == array {
          line.number.map(n => html.elem("span", attrs: (style: "margin-left: 0.2em"), n)).join()
        } else {
          [#line.number]
        })
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
      line-elem = html.elem(
        "span",
        attrs: (
          class: "hll",
          style: create-style(
            background: bg.to-hex(),
            margin: "0 " + repr-or-str(-inset.right) + " 0 " + repr-or-str(-inset.left),
            padding: "0 " + repr-or-str(inset.right) + " 0 " + repr-or-str(inset.left),
          ),
        ),
        line-elem,
      )
    }

    (line-elem, is-block)
  }

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

  // Helper functions for header/footer
  let create-header-footer(is-header, content) = {
    let key = if is-header { "header" } else { "footer" }

    let content = if content != none {
      content
    } else if key in comments {
      comments.at(key)
    } else {
      return none
    }

    html.elem(
      "span",
      attrs: (
        style: create-style(
          padding: repr-or-str(inset.right) + " " + repr-or-str(inset.left),
          background: if is-header {
            curr-background-color(background-color, 0).to-hex()
          } else {
            curr-background-color(background-color, lines.len() + 1).to-hex()
          },
          display: "block",
        ),
      ),
      text(..comment-font-args, content),
    )
  }

  // Main code block container
  html.elem("div", attrs: (class: "zebraw-code-block"), {
    // Language label
    if type(lang) != bool or lang == true and it.lang != none {
      html.elem(
        "div",
        attrs: (
          style: create-style(background: lang-color.to-hex(), border-radius: repr-or-str(inset.left)),
          class: "zebraw-code-lang",
          translate: "no",
        ),
        if type(lang) == bool { it.lang } else { lang },
      )
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
        create-header-footer(true, header)
        {
          // gather code lines
          let is-prev-block = true
          for line in lines {
            let (line-elem, is-cur-block) = build-code-line-elem(line)
            if not (is-prev-block or is-cur-block) {
              "\n"
            }
            is-prev-block = is-cur-block
            line-elem
          }
        }
        create-header-footer(false, footer)
      })
    })
  })
}

#let zebraw-html-styles() = {
  html.elem("style", {
    ````css
    .zebraw-code-block {
      position: relative;
    }
    .zebraw-code-block .zebraw-code-lang {
      position: absolute;
      right: 0;
      padding: 0.25em;
      font-size: 0.8em;
    }
    .zebraw-code-block .header {
      display: block;
    }
    .zebraw-code-block pre>code {
      display: block;
      overflow: auto;
    }
    .zebraw-code-block pre.pre-wrap {
      white-space: pre-wrap;
    }
    .zebraw-code-block .lineno {
      display: inline-block;
      margin-right: 0.35em;
      padding-right: 0.35em;
      text-align: right;
      user-select: none;
    }
    .zebraw-code-block .lineno.sep {
      box-shadow: -0.05rem 0 hsla(0, 0%, 0%, 0.07) inset;
    }
    .zebraw-code-block .hll {
      display: block;
    }
    .zebraw-code-block .underline {
      text-decoration: underline;
    }
    ````.text
  })
}

#let zebraw-html-clipboard-copy() = {
  html.elem(
    "script",
    ```javascript
    document.querySelectorAll('.zebraw-code-block').forEach(codeBlock => {
      const copyButton = codeBlock.querySelector('.zebraw-code-lang');
      if (!copyButton) return;

      copyButton.style.cursor = 'pointer';
      copyButton.title = 'Click to copy code';

      copyButton.addEventListener('click', () => {
        const code = Array.from(codeBlock.querySelectorAll('.zebraw-code-line'))
          .map(line => line.textContent)
          .join('\n');

        navigator.clipboard.writeText(code)
          .catch(() => {
            const textarea = document.createElement('textarea');
            textarea.value = code;
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
          });

        const originalTitle = copyButton.title;
        copyButton.title = 'Code copied!';
        setTimeout(() => copyButton.title = originalTitle, 2000);
      });
    });
    ```.text,
  )
}

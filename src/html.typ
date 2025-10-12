#import "util.typ": *

#let repr-or-str(x) = {
  if type(x) == str {
    x
  } else {
    repr(x)
  }
}

#let create-style(..styles) = styles.pos().filter(s => s != none).flatten().join("; ")

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
  let args = parse-zebraw-args(
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

  // Extract args
  let numbering = args.numbering
  let inset = args.inset
  let background-color = args.background-color
  let highlight-color = args.highlight-color
  let comment-color = args.comment-color
  let lang-color = args.lang-color
  let comment-flag = args.comment-flag
  let lang = args.lang
  let comment-font-args = args.comment-font-args
  let lang-font-args = args.lang-font-args
  let numbering-font-args = args.numbering-font-args
  let extend = args.extend
  let hanging-indent = args.hanging-indent
  let indentation = args.indentation
  let numbering-separator = args.numbering-separator
  let fast-preview = args.fast-preview

  // Process highlight lines
  let (highlight-nums, comments, line-colors) = tidy-highlight-lines(highlight-lines)

  // Process lines
  let lines = process-lines(
    numbering,
    it.lines,
    none, // No highlight numbers for inline
    none, // No comments for inline
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
    class: class-list(
      "expressive-code-inline",
      if it.lang != none { "language-" + it.lang },
    ),
    style: create-style-dict((
      "--ec-codeFg": default-color.to-hex(),
      "--ec-codeBg": background-color-at-index(background-color, 0).to-hex(),
      "--ec-codePadInl": repr-or-str(inset.left),
      "--ec-codePadBlk": repr-or-str(inset.top),
      "--ec-borderRad": repr-or-str(inset.left),
    )),
  )

  let text-div-style = (
    "text-align: left",
    "display: flex",
    "align-items: center",
    "width: 100%",
  )

  let background-text-style = (
    "user-select: none",
    "opacity: 0",
    "color: transparent",
  )

  // Process highlight lines
  let (highlight-nums, comments) = parse-highlight-lines(highlight-lines)

  // Process lines
  let lines = process-lines(
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
    line-colors: line-colors,
  )

  let default-color = text.fill
  let default-bg = background-color-at-index(background-color, 0)
  let show-numbering = numbering != false

  /// Renders the language badge shown above the block
  let create-lang-label() = {
    html.elem(
      "div",
      attrs: (
        class: "code-lang",
        translate: "no",
      ),
      if type(lang) == bool { it.lang } else { lang },
    )
  }

  /// Renders the copy-to-clipboard button shown in the toolbar
  let create-copy-button() = {
    html.elem(
      "button",
      attrs: (
        type: "button",
        class: "copy-button",
        title: "Copy code",
        "data-state": "idle",
        "aria-label": "Copy code",
      ),
      {
        html.elem("span", attrs: (class: "sr-only"), [Copy code])
        html.elem("span", attrs: (class: "copy-label", "aria-hidden": "true"), [Copy])
        html.elem("span", attrs: (class: "copy-feedback", "aria-hidden": "true"), [Copied!])
      },
    )
  }

  /// Renders the optional header or footer content inside the code element
  let create-header-footer(content, position, bg, extend) = {
    if content == none and not extend {
      return
    }

    let classes = class-list("ec-" + position, if content == none { "ec-ext" })
    let attrs = (class: classes)
    if bg != none {
      attrs.style = create-style-dict(("background": bg.to-hex()))
    }

    if content == none {
      html.elem("div", attrs: attrs, [])
    } else {
      html.elem("div", attrs: attrs, text(..comment-font-args, content))
    }
  }

  /// Renders a gutter cell with the provided line number(s)
  let create-lineno(lineno) = {
    set text(..numbering-font-args)
    html.elem("div", attrs: (class: "ln"), {
      if lineno == none {
        ""
      } else if type(lineno) == array {
        for num in lineno {
          html.elem("span", [#num])
        }
      } else {
        [#lineno]
      }
    })
  }

  /// Builds a single Expressive Code style line element
  let create-code-line(line) = {
    let line-classes = class-list(
      "ec-line",
      if line.type == "highlight" { "highlight" },
      if line.comment != none { "has-comment" },
    )

    let line-style = (:)
    if line.fill != none {
      line-style.insert("--lineBg", line.fill.to-hex())
      if line.fill != default-bg {
        line-style.insert("background", line.fill.to-hex())
      }
    }

    let indent-length = if line.indentation != none { line.indentation.len() } else { 0 }
    if indent-length > 0 {
      line-style.insert("--ecIndent", str(indent-length) + "ch")
    }

    let line-attrs = (class: line-classes)
    let line-style = (:)
    if line.fill != none {
      line-style.insert("--lineBg", line.fill.to-hex())
      if line.fill != default-bg {
        line-style.insert("background", line.fill.to-hex())
      }
    }
    let indent-length = if line.indentation != none { line.indentation.len() } else { 0 }
    if indent-length > 0 {
      line-style.insert("--ecIndent", str(indent-length) + "ch")
    }
    if line-style.len() > 0 {
      line-attrs.style = create-style-dict(line-style)
    }

    let indent-overlay = if indentation > 0 and indent-length > 0 {
      html.elem(
        "span",
        attrs: (
          class: "indent-overlay",
          "aria-hidden": "true",
        ),
        [],
      )
    } else {
      none
    }

    let code-attrs = (:)
    let code-class = class-list()
    if code-class != none {
      code-attrs.class = code-class
    }
    if line.indentation != none {
      code-attrs.insert("data-indent", line.indentation)
    }

    html.elem("div", attrs: line-attrs, {
      if show-numbering and line.number != none {
        html.elem("div", attrs: (class: "gutter"), create-lineno(line.number))
      }

      html.elem("div", attrs: ((class: "code") + code-attrs), {
        if indent-overlay != none { indent-overlay }
        show linebreak: none
        show text: style-code-line.with(default-color: default-color)
        line.body
      })

      if line.comment != none {
        let comment-flag = line.comment.at("comment-flag", default: none)
        let comment-fill = if line.comment.fill != none { line.comment.fill.to-hex() } else { comment-color.to-hex() }
        html.elem(
          "div",
          attrs: (class: "ec-comment", style: create-style-dict(("background": comment-fill))),
          {
            if comment-flag != none and comment-flag != "" {
              comment-flag
              " "
            }
            line.comment.body
          },
        )
      }
    })
  }

  // Determine classes and attributes for wrapper and pre elements
  let wrapper-class = class-list(
    "expressive-code",
    if numbering-separator { "lineno-sep" },
    if show-numbering { "has-gutter" },
    if indentation > 0 { "has-indent-guides" },
  )

  let fallback-lang-bg = if lang-color != none {
    lang-color
  } else {
    default-color.lighten(55%)
  }
  let lang-fill = lang-font-args.at("fill", default: none)
  let fallback-lang-fg = if lang-fill != none {
    lang-fill
  } else {
    default-color
  }
  let copy-bg = default-bg.lighten(22%)
  let copy-bg-hover = copy-bg.lighten(8%)
  let copy-bg-focus = copy-bg.lighten(12%)
  let copy-fg = default-color
  let copy-fg-hover = default-color
  let copy-fg-focus = default-color

  let wrapper-vars = (
    "--ec-borderRad": repr-or-str(inset.left),
    "--ec-codePadBlk": repr-or-str(inset.top),
    "--ec-codePadInl": repr-or-str(inset.left),
    "--ec-codeFg": default-color.to-hex(),
    "--ec-codeBg": default-bg.to-hex(),
    "--ec-langBg": fallback-lang-bg.to-hex(),
    "--ec-langFg": fallback-lang-fg.to-hex(),
    "--ec-copyBg": copy-bg.to-hex(),
    "--ec-copyFg": copy-fg.to-hex(),
    "--ec-gutterBg": default-bg.to-hex(),
    "--ec-gutterGap": repr-or-str("0.25rem"),
    "--ec-gutterPadLeft": repr-or-str("0.5rem"),
    "--ec-codeFontSize": repr-or-str("0.85em"),
    "--ec-codeLineHeight": repr-or-str(1.5),
    "--ec-copyBgHover": copy-bg-hover.to-hex(),
    "--ec-copyBgFocus": copy-bg-focus.to-hex(),
    "--ec-copyFgHover": copy-fg-hover.to-hex(),
    "--ec-copyFgFocus": copy-fg-focus.to-hex(),
  )
  if highlight-color != none {
    wrapper-vars.insert("--ec-hlBg", highlight-color.to-hex())
  }
  if comment-color != none {
    wrapper-vars.insert("--ec-commentBg", comment-color.to-hex())
  }
  if lang-color != none {
    wrapper-vars.insert("--ec-langBg", lang-color.to-hex())
  }
  if show-numbering {
    let gutter-normal = default-color.lighten(60%)
    let gutter-highlight = default-color.lighten(45%)
    wrapper-vars.insert("--ec-gtrFg", gutter-normal.to-hex())
    wrapper-vars.insert("--ec-gtrHighlightFg", gutter-highlight.to-hex())
    wrapper-vars.insert("--ec-gtrBrdCol", gutter-normal.transparentize(35%).to-hex())
  }
  if indentation > 0 {
    wrapper-vars.insert("--ec-indentStep", str(indentation) + "ch")
    let guide-color = default-color.transparentize(65%)
    wrapper-vars.insert("--ec-indentGuideCol", guide-color.to-hex())
  }

  let wrapper-style = create-style-dict(wrapper-vars)

  let pre-attrs = (
    data-language: if it.lang != none { it.lang } else { "plaintext" },
  )
  if wrap {
    pre-attrs.class = "wrap"
  }

  if show-numbering and type(numbering) != array and lines.len() > 0 {
    let first-line = numbering-offset + 1
    let last-line = first-line + lines.len() - 1
    let width = str(first-line).len()
    if str(last-line).len() > width {
      width = str(last-line).len()
    }
    if width < 2 {
      width = 2
    }
    pre-attrs.style = create-style-dict(("--lnWidth": str(width) + "ch"))
  }

  let code-attrs = (:)
  let code-class = class-list(
    if it.lang != none { "language-" + it.lang },
  )
  if code-class != none {
    code-attrs.class = code-class
  }

  let header-content = if header != none { header } else { comments.at("header", default: none) }
  let footer-content = if footer != none { footer } else { comments.at("footer", default: none) }
  let header-bg = background-color-at-index(background-color, 0)
  let footer-bg = background-color-at-index(background-color, lines.len() + 1)

  html.elem("div", attrs: (class: wrapper-class, style: wrapper-style), {
    if type(lang) != bool or lang == true and it.lang != none {
      create-lang-label()
    }

    create-copy-button()

    html.elem("pre", attrs: pre-attrs, {
      html.elem("code", attrs: code-attrs, {
        create-header-footer(header-content, "header", header-bg, extend)

        for line in lines {
          create-code-line(line)
        }

        create-header-footer(footer-content, "footer", footer-bg, extend)
      })
    })
  })
}

      // Foreground content
      html.elem(
        "div",
        attrs: (
          style: create-style(
            "overflow-x: auto",
            "overflow-y: hidden",
          ),
        ),
        (
          ..create-header-footer(true, header, comments, extend),
          ..lines.map(line => build-code-line-elem(line)).flatten(),
          ..create-header-footer(false, footer, comments, extend),
        ).join(),
      )

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
    },
  )
}

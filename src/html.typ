#import "utils.typ": *

#let repr-or-str(x) = {
  if type(x) == str {
    x
  } else {
    repr(x)
  }
}

/// HTML variant.
#let zebraw-html(
  highlight-lines: (),
  header: none,
  footer: none,
  inset: none,
  background-color: none,
  highlight-color: none,
  comment-color: none,
  lang-color: none,
  comment-flag: none,
  lang: none,
  comment-font-args: none,
  lang-font-args: none,
  extend: none,
  block-width: 42em,
  line-width: 100%,
  wrap: true,
  body,
) = context {
  let args = parse-zebraw-args(
    inset,
    background-color,
    highlight-color,
    comment-color,
    lang-color,
    comment-flag,
    lang,
    comment-font-args,
    lang-font-args,
    extend,
  )
  let inset = args.inset
  let background-color = args.background-color
  let highlight-color = args.highlight-color
  let comment-color = args.comment-color
  let lang-color = args.lang-color
  let comment-flag = args.comment-flag
  let lang = args.lang
  let comment-font-args = args.comment-font-args
  let lang-font-args = args.lang-font-args
  let extend = args.extend

  let (highlight-nums, comments) = tidy-highlight-lines(highlight-lines)

  show raw.where(block: true): it => {
    let pre-style = (
      "padding-top: " + repr-or-str(inset.top),
      "padding-bottom: " + repr-or-str(inset.bottom),
      "margin: 0",
      "width: " + repr-or-str(line-width),
    ).join("; ")

    let text-div-style(line) = (
      "background: " + line.fill.to-hex(),
      "text-align: left",
      "display: flex",
      "align-items: center",
      "width: " + if wrap { "100%" } else { repr-or-str(line-width) },
    ).join("; ")

    let comment-div-style(line) = (
      text-div-style(line).split("; ")
        + (
          "padding-top: " + repr-or-str(inset.top),
          "padding-bottom: " + repr-or-str(inset.bottom),
        )
    ).join("; ")

    let build-code-line-elem(line) = (
      html.elem(
        "div",
        attrs: (style: (text-div-style(line))),
        {
          (
            html.frame(box(width: 2.1em, inset: (right: inset.right), align(right)[#line.number]))
              + html.elem(
                "pre",
                attrs: (style: (pre-style)),
                {
                  show text: it => context {
                    let c = text.fill
                    html.elem(
                      "span",
                      attrs: (
                        style: (
                          "color: " + c.to-hex(),
                          ..if wrap { ("white-space: pre-wrap",) } else { none },
                        ).join("; "),
                      ),
                      it,
                    )
                  }
                  if line.body.func() == text {
                    linebreak()
                  } else {
                    line.body
                  }
                },
              )
          )
        },
      ),
      ..if line.comment != none {
        (
          html.elem(
            "div",
            attrs: (style: (comment-div-style(line.comment))),
            html.frame(
              text(
                ..comment-font-args,
                box(width: 2.1em, inset: (right: inset.right), []) + line.comment.indent + line.comment.body,
              ),
            ),
          ),
        )
      },
    )


    let build-cell(is-header, content) = table.cell(
      colspan: 1,
      html.elem(
        "div",
        attrs: (
          style: (
            "background: "
              + if content != none { comment-color.to-hex() } else {
                curr-background-color(background-color, 0).to-hex()
              },
            "width: " + if wrap { "100%" } else { repr-or-str(line-width) },
          ).join("; "),
        ),
        html.elem(
          "div",
          attrs: (
            style: "padding: " + repr-or-str(inset.right) + " " + repr-or-str(inset.left),
          ),
          text(..comment-font-args, content),
        ),
      ),
    )

    let header-cell = if header != none or comments.keys().contains("header") {
      (build-cell(true, if header != none { header } else { comments.at("header") }),)
    } else if extend {
      (build-cell(true, none),)
    } else {
      ()
    }

    let footer-cell = if footer != none or comments.keys().contains("footer") {
      (build-cell(false, if footer != none { footer } else { comments.at("footer") }),)
    } else if extend {
      (build-cell(false, none),)
    } else {
      ()
    }

    let lines = tidy-lines(
      it.lines,
      highlight-nums,
      comments,
      highlight-color,
      background-color,
      comment-color,
      comment-flag,
      comment-font-args,
      is-html: true,
    )

    html.elem(
      "div",
      attrs: (
        style: (
          "position: relative",
          "width: " + repr-or-str(block-width), // 正则表达式匹配 repr-or-str(...) 的模式为：/repr\([^)]*\)/
        ).join("; "),
      ),
      {
        if lang != none {
          html.elem(
            "div",
            attrs: (
              style: (
                "position: absolute",
                "top: 0",
                "right: 0",
                "padding: 0.25em",
                "background: " + lang-color.to-hex(),
                "font-size: 0.8em",
                "border-radius: " + repr-or-str(inset.right),
              ).join("; "),
            ),
            {
              set text(..lang-font-args)
              if type(lang) == bool { it.lang } else { lang }
            },
          )
        } else { none }
        html.elem(
          "div",
          attrs: (
            style: (
              "overflow-x: auto",
              "overflow-y: hidden",
              "border-radius: " + repr-or-str(inset.left),
            ).join("; "),
          ),
          (
            ..header-cell,
            lines.map(line => build-code-line-elem(line)),
            ..footer-cell,
          )
            .flatten()
            .join(),
        )
        // linebreak()
      },
    )
  }

  body
}

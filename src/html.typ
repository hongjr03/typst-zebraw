#import "mod.typ": parse-zebraw-args

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

  let (highlight-nums, comments) = {
    let nums = ()
    let comments = (:)
    let lines = if type(highlight-lines) == int {
      (highlight-lines,)
    } else if type(highlight-lines) == array {
      highlight-lines
    }
    for line in lines {
      if type(line) == int {
        nums.push(line)
      } else if type(line) == array {
        nums.push(line.first())
        comments.insert(str(line.at(0)), line.at(1))
      } else if type(line) == dictionary {
        if not (line.keys().contains("header") or line.keys().contains("footer")) {
          nums.push(int(line.keys().first()))
        }
        comments += line
      }
    }
    (nums, comments)
  }

  let curr-background-color(background-color, idx) = {
    let res = if type(background-color) == color {
      background-color
    } else if type(background-color) == array {
      background-color.at(calc.rem(idx, background-color.len()))
    }
    res
  }

  show raw.where(block: true): it => {
    let pre-style = (
      "padding-top: " + repr(inset.top),
      "padding-bottom: " + repr(inset.bottom),
      "margin: 0",
      "width: " + repr(line-width),
    ).join("; ")

    let text-div-style(line) = (
      "background: " + line.fill.to-hex(),
      "text-align: left",
      "display: flex",
      "align-items: center",
      "width: " + if wrap { repr(block-width) } else { repr(line-width) },
    ).join("; ")

    let comment-div-style(line) = (
      text-div-style(line).split("; ")
        + (
          "padding-top: " + repr(inset.top),
          "padding-bottom: " + repr(inset.bottom),
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
                  line.body
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
            "width: " + if wrap { repr(block-width) } else { repr(line-width) },
          ).join("; "),
        ),
        html.elem(
          "div",
          attrs: (
            style: "padding: " + repr(inset.right) + " " + repr(inset.left),
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

    let lines = it
      .lines
      .map(line => {
        let res = ()
        if (type(highlight-nums) == array and highlight-nums.contains(line.number)) {
          res.push((
            number: line.number,
            body: line.body,
            fill: highlight-color,
            comment: if comments.keys().contains(str(line.number)) {
              (
                indent: box(line.text.split(regex("\S")).first()),
                body: if comment-flag != "" {
                  {
                    strong(text(ligatures: true, comment-flag))
                    h(0.35em, weak: true)
                  }
                  text(..comment-font-args, comments.at(str(line.number)))
                } else {
                  text(..comment-font-args, comments.at(str(line.number)))
                },
                fill: comment-color,
              )
            } else { none },
          ))
        } else {
          let fill-color = curr-background-color(background-color, line.number)
          res.push((
            number: line.number,
            body: line.body,
            fill: fill-color,
            comment: none,
          ))
        }
        res
      })
      .flatten()
    html.elem(
      "div",
      attrs: (
        style: (
          "position: relative",
          "width: " + repr(block-width),
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
                "border-radius: " + repr(inset.right),
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
              "border-radius: " + repr(inset.left),
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
      },
    )
  }

  body
}

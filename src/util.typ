#import "state.typ": *

#let tidy-highlight-lines(highlight-lines) = {
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

#let curr-background-color(background-color, idx) = {
  let res = if type(background-color) == color {
    background-color
  } else if type(background-color) == array {
    background-color.at(calc.rem(idx, background-color.len()))
  }
  res
}

#let tidy-lines(
  numbering,
  lines,
  highlight-nums,
  comments,
  highlight-color,
  background-color,
  comment-color,
  comment-flag,
  comment-font-args,
  numbering-offset,
  inset,
  indentation: 0,
  is-html: false,
  line-range: (1, none),
  hanging-indent: false,
) = {
  let lines-result = ()
  let (start, end, keep-offset) = if type(line-range) == array {
    (
      line-range.at(0) - 1,
      if line-range.at(1) != none {
        line-range.at(1) - 1
      } else { none },
      true,
    )
  } else if type(line-range) == dictionary {
    (
      line-range.range.at(0) - 1,
      if line-range.range.at(1) != none {
        line-range.range.at(1) - 1
      } else { none },
      line-range.keep-offset,
    )
  } else {
    (0, none, true)
  }
  let lines = lines.slice(start, end)
  for (x, line) in lines.enumerate() {
    let res = ()
    let indentation = if line.text.trim() == "" {
      if x > 0 and lines-result.last().keys().contains("indentation") and lines-result.last().type != "comment" {
        lines-result.last().indentation
      } else if (
        lines-result.len() > 1
          and lines-result.at(-2).keys().contains("indentation")
          and lines-result.at(-2).type != "comment"
      ) {
        lines-result.at(-2).indentation
      }
    } else {
      line.text.split(regex("\S")).first()
    }
    let body = if line.text.trim() == "" {
      [#indentation\ ]
    } else {
      line.body
    }


    if (type(highlight-nums) == array and highlight-nums.contains(line.number)) {
      let comment = if comments.keys().contains(str(line.number)) {
        (
          type: "comment",
          indentation: line.text.split(regex("\S")).first(),
          comment-flag: comment-flag,
          body: text(..comment-font-args, comments.at(str(line.number))),
          fill: comment-color,
        )
      } else { none }

      res.push((
        type: "highlight",
        indentation: indentation,
        number: if numbering != false {
          if keep-offset {
            line.number + numbering-offset
          } else {
            line.number + numbering-offset - start
          }
        } else { none },
        body: body,
        fill: highlight-color,
        // if it's html, the comment will be saved in this field
        comment: if not is-html { none } else { comment },
      ))

      // otherwise, we need to push the comment as a separate line
      if not is-html and comment != none {
        res.push((
          type: "comment",
          number: none,
          body: if comment != none {
            if comment-flag != "" {
              indentation
              strong(text(ligatures: true, comment.comment-flag))
              h(0.35em, weak: true)
            }
            comment.body
          } else { "" },
          fill: comment-color,
        ))
      }
    } else {
      let fill-color = curr-background-color(background-color, line.number)
      res.push((
        type: "normal",
        indentation: indentation,
        number: if numbering == true {
          if keep-offset {
            line.number + numbering-offset
          } else {
            line.number + numbering-offset - start
          }
        } else if numbering == false { none } else {
          numbering.map(list => {
            assert(list.len() == lines.len(), message: "numbering list length should be equal to lines length")
            list.at(line.number - 1)
          })
        },
        body: body,
        fill: fill-color,
        comment: none,
      ))
    }

    for item in res {
      lines-result.push(item)
    }
  }
  lines-result
}


// Renders a single indentation marker (vertical line)
#let render-indentation-marker(height-val, line-height) = {
  if indentation <= 0 { return " " }

  if fast-preview {
    set text(fill: gray.transparentize(50%))
    "|"
  } else if height-val != none {
    let line-end-y = if hanging-indent {
      height-val - inset.top
    } else {
      line-height + inset.bottom
    }

    place(
      std.line(
        start: (0em, -inset.top),
        end: (0em, line-end-y),
        stroke: .05em + gray.transparentize(50%),
      ),
      left + top,
    )
    " "
  } else {
    " "
  }
}

// Format indentation with vertical guides
#let format-indentation(idt, height, line-height, indentation) = {
  if indentation <= 0 { return idt }

  // Process each leading space in indentation string
  let len = idt.len()
  let processed = ""

  let breakpoint = -1
  for i in range(len) {
    // Add vertical line for each position that's a multiple of indentation
    if calc.rem(i, indentation) == 0 and idt.at(i) == " " {
      processed += box(render-indentation-marker(height, line-height))
    } else if idt.at(i) != " " {
      breakpoint = i
      break
    } else {
      processed += idt.at(i)
    }
  }

  // Add remaining non-space characters
  if breakpoint != -1 {
    for i in range(breakpoint, len) {
      processed += idt.at(i)
    }
  }

  processed
}

// Process line's indentation
#let process-indentation(line, height, line-height, hanging-indent, indentation) = {
  // Handle different content types based on hanging-indent setting
  if repr(line.body.func()) == "sequence" and line.body.children.first().func() == text {
    if line.body.children.first().text.trim() == "" {
      // Empty first text node
      if hanging-indent {
        grid(
          columns: 2,
          format-indentation(line.indentation, height, line-height, indentation), line.body.children.slice(1).join(),
        )
      } else {
        format-indentation(line.indentation, height, line-height, indentation)
        line.body.children.slice(1).join()
      }
    } else {
      format-indentation(line.body.children.first().text, height, line-height, indentation)
      line.body.children.slice(1).join()
    }
  } else if repr(line.body.func()) == "text" {
    if hanging-indent {
      grid(
        columns: 2,
        format-indentation(line.indentation, height, line-height, indentation), line.body.text.trim(),
      )
    } else {
      format-indentation(line.indentation, height, line-height, indentation)
      line.body.text.trim()
    }
  } else {
    line.body
  }
}

// Renders a code line with indentation processing
#let render-code-line(line, height, hanging-indent, indentation) = {
  let line-height = measure("|").height

  // Only process indentation if available
  if line.keys().contains("indentation") {
    let indented-content = process-indentation(line, height, line-height, hanging-indent, indentation)
    indented-content
  } else {
    // No indentation processing needed
    line.body
  }
}

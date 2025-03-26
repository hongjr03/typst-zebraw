#import "states.typ": *

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
) = {
  let lines-result = ()
  for (x, line) in lines.enumerate() {
    let res = ()
    let indent = if line.text.trim() == "" {
      if x > 0 and lines-result.last().keys().contains("indentation") {
        lines-result.last().indentation
      } else if x > 1 and lines-result.at(x - 1).keys().contains("indentation") {
        lines-result.at(x - 1).indentation
      }
    } else {
      line.text.split(regex("\S")).first()
    }
    let body = if line.text.trim() == "" {
      [#indent\ ]
    } else {
      line.body
    }


    if (type(highlight-nums) == array and highlight-nums.contains(line.number)) {
      let comment = if comments.keys().contains(str(line.number)) {
        (
          indent: line.text.split(regex("\S")).first(),
          comment-flag: comment-flag,
          body: text(..comment-font-args, comments.at(str(line.number))),
          fill: comment-color,
        )
      } else { none }

      res.push((
        indentation: indent,
        number: if numbering { line.number + numbering-offset } else { none },
        body: body,
        fill: highlight-color,
        // if it's html, the comment will be saved in this field
        comment: if not is-html { none } else { comment },
      ))

      // otherwise, we need to push the comment as a separate line
      if not is-html and comment != none {
        res.push((
          number: none,
          body: if comment != none {
            if comment-flag != "" {
              box(comment.indent)
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
        indentation: indent,
        number: if numbering { line.number + numbering-offset } else { none },
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

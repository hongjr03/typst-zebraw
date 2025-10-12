#import "state.typ": *
#import "indentation.typ": *

/// Get the current background color based on type (single color or array)
#let curr-background-color(background-color, idx) = {
  let res = if type(background-color) == color {
    background-color
  } else if type(background-color) == array {
    background-color.at(calc.rem(idx, background-color.len()))
  }
  res
}

/// Calculate the width for line numbering column
/// Returns appropriate width based on line count and numbering type
#let calculate-numbering-width(numbering, total-lines, numbering-offset) = {
  if numbering == false {
    0pt
  } else if (total-lines + numbering-offset < 100) and type(numbering) != array {
    2.1em
  } else {
    auto
  }
}

/// Render a single line (either line number or code content)
#let render-line(
  line,
  is-line-number: false,
  numbering-width: auto,
  height: none,
  hanging-indent: false,
  indentation: 0,
  inset: (:),
  fast-preview: false,
  numbering-font-args: (:),
  numbering-separator: 0.3em,
) = {
  grid.cell(
    fill: line.fill,
    block(
      width: if not is-line-number { 100% } else { numbering-width },
      inset: inset,
      {
        if is-line-number {
          // Line number rendering
          set text(..numbering-font-args)
          (line.number,).flatten().map(num => box([#num])).join(h(numbering-separator, weak: true))
        } else {
          // Code line rendering with optional indentation processing
          indentation-render-line(line, height, hanging-indent, indentation, inset, fast-preview)
        }
      },
    ),
  )
}

/// Create a header section for the code block
#let create-header(
  header-param,
  comments,
  comment-color,
  comment-font-args,
  inset,
  has-lang,
  extend,
  background-color,
) = {
  let content = if header-param != none {
    header-param
  } else if comments.keys().contains("header") {
    comments.at("header")
  } else {
    none
  }

  if content != none {
    // Custom header content
    grid.cell(
      align: left + top,
      colspan: 2,
      box(
        width: 100%,
        inset: inset.pairs().map(((key, value)) => (key, value * 2)).to-dict(),
        radius: if not has-lang { (top: inset.left) } else { (top-left: inset.left) },
        fill: comment-color,
        text(..comment-font-args, content),
      ),
    )
  } else if extend {
    // Empty header with background for extension
    grid.cell(
      colspan: 2,
      box(
        width: 100%,
        fill: curr-background-color(background-color, 0),
        inset: (:) + (top: inset.top),
        radius: (top: inset.left),
        [],
      ),
    )
  } else {
    none
  }
}

/// Create a footer section for the code block
#let create-footer(
  footer-param,
  comments,
  comment-color,
  comment-font-args,
  inset,
  extend,
  background-color,
  lines-len,
) = {
  let content = if footer-param != none {
    footer-param
  } else if comments.keys().contains("footer") {
    comments.at("footer")
  } else {
    none
  }

  if content != none {
    // Custom footer content
    grid.cell(
      align: left + top,
      colspan: 2,
      box(
        width: 100%,
        inset: inset.pairs().map(((key, value)) => (key, value * 2)).to-dict(),
        radius: (bottom: inset.left),
        fill: comment-color,
        text(..comment-font-args, content),
      ),
    )
  } else if extend {
    // Empty footer with background for extension
    grid.cell(
      colspan: 2,
      box(
        width: 100%,
        fill: curr-background-color(background-color, lines-len + 1),
        inset: (:) + (bottom: inset.bottom),
        radius: (bottom: inset.left),
        [],
      ),
    )
  } else {
    none
  }
}

/// Render the language tab if needed
#let render-lang-tab(
  has-lang,
  lang,
  lang-color,
  lang-font-args,
  inset,
  it,
) = context {
  if has-lang {
    let lang-tab = box(
      inset: 0.34em,
      outset: (bottom: inset.left),
      radius: (top: inset.left),
      fill: lang-color,
      text(
        bottom-edge: "bounds",
        ..lang-font-args,
        if type(lang) == bool { it.lang } else { lang },
      ),
    )
    v(-measure(lang-tab).height)
    h(1fr)
    lang-tab
    v(0em, weak: true)
  }
}

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
  // Process line range
  let (start, end, keep-offset) = if type(line-range) == array {
    (line-range.at(0) - 1, if line-range.at(1) != none { line-range.at(1) - 1 } else { none }, true)
  } else if type(line-range) == dictionary {
    (
      line-range.range.at(0) - 1,
      if line-range.range.at(1) != none { line-range.range.at(1) - 1 } else { none },
      line-range.keep-offset,
    )
  } else {
    (0, none, true)
  }

  // Slice lines according to range
  let lines = lines.slice(start, end)
  let lines-result = ()

  // Process each line
  for (x, line) in lines.enumerate() {
    let indent-string = if line.text.trim(whitespace-regex, at: std.start) == "" {
      // For empty lines, use indentation from previous non-comment lines
      let prev-line = if x > 0 and lines-result.last().type != "comment" {
        lines-result.last()
      } else if lines-result.len() > 1 and lines-result.at(-2).type != "comment" {
        lines-result.at(-2)
      } else {
        none
      }

      if prev-line != none and prev-line.keys().contains("indentation") {
        prev-line.indentation
      } else {
        indentation * " "
      }
    } else {
      // Use function from indentation.typ to extract indentation string
      indentation-extract-from-text(line.text)
    }

    let body = if line.text.trim(whitespace-regex, at: std.start) == "" {
      [\ ]
    } else {
      line.body
    }


    // Calculate line number to display
    let display-number = if numbering == true {
      if keep-offset { line.number + numbering-offset } else { line.number + numbering-offset - start }
    } else if numbering == false {
      none
    } else if type(numbering) == array {
      numbering.map(list => {
        assert(list.len() == lines.len(), message: "numbering list length should be equal to lines length")
        list.at(line.number - 1)
      })
    }

    // Process highlighted lines
    if type(highlight-nums) == array and highlight-nums.contains(line.number) {
      // Create comment if it exists for this line
      let comment = if comments.keys().contains(str(line.number)) {
        (
          type: "comment",
          indentation: line.text.split(regex("\S")).first(),
          comment-flag: comment-flag,
          body: text(..comment-font-args, comments.at(str(line.number))),
          fill: comment-color,
        )
      } else { none }

      // Add highlighted line
      lines-result.push((
        type: "highlight",
        indentation: indent-string,
        number: display-number,
        body: body,
        fill: highlight-color,
        comment: if is-html { comment } else { none },
      ))

      // Add separate comment line if needed
      if not is-html and comment != none {
        lines-result.push((
          type: "comment",
          number: none,
          body: {
            if comment-flag != "" {
              indent-string
              strong(text(ligatures: true, comment.comment-flag))
              h(0.35em, weak: true)
            }
            comment.body
          },
          fill: comment-color,
        ))
      }
    } else {
      // Add normal line
      lines-result.push((
        type: "normal",
        indentation: indent-string,
        number: display-number,
        body: body,
        fill: curr-background-color(background-color, line.number),
        comment: none,
      ))
    }
  }

  lines-result
}

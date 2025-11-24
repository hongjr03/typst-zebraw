#import "state.typ": *
#import "indentation.typ": *

/// Get the current background color based on type (single color or array)
#let background-color-at-index(background-color, idx) = {
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
  radius,
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
        radius: if not has-lang { (top: radius) } else { (top-left: radius) },
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
        fill: background-color-at-index(background-color, 0),
        inset: (:) + (top: inset.top),
        radius: (top: radius),
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
  radius,
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
        radius: (bottom: radius),
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
        fill: background-color-at-index(background-color, lines-len + 1),
        inset: (:) + (bottom: inset.bottom),
        radius: (bottom: radius),
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
  radius,
  it,
) = context {
  if has-lang {
    let lang-tab = box(
      inset: 0.34em,
      outset: (bottom: radius),
      radius: (top: radius),
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

/// Parse highlight lines to extract line numbers, comments, and colors
#let parse-highlight-lines(highlight-lines) = {
  let nums = ()
  let comments = (:)
  let line-colors = (:)

  if type(highlight-lines) == int {
    nums.push(highlight-lines)
  } else if type(highlight-lines) == array {
    for line in highlight-lines {
      if type(line) == int {
        nums.push(line)
      } else if type(line) == array {
        let line-num = line.first()
        nums.push(line-num)

        // Process additional elements (color and/or comment)
        for item in line.slice(1) {
          if type(item) == color {
            line-colors.insert(str(line-num), item)
          } else {
            comments.insert(str(line-num), item)
          }
        }
      } else if type(line) == dictionary {
        if not (line.keys().contains("header") or line.keys().contains("footer")) {
          let line-num = int(line.keys().first())
          nums.push(line-num)

          let value = line.at(line.keys().first())
          if type(value) == color {
            line-colors.insert(str(line-num), value)
          } else {
            comments.insert(str(line-num), value)
          }
        } else {
          comments += line
        }
      }
    }
  } else if type(highlight-lines) == dictionary {
    for (key, value) in highlight-lines {
      if not (key == "header" or key == "footer") {
        let line-num = int(key)
        nums.push(line-num)

        if type(value) == color {
          line-colors.insert(str(line-num), value)
        } else {
          comments.insert(str(line-num), value)
        }
      } else {
        comments.insert(key, value)
      }
    }
  }

  (nums, comments, line-colors)
}

/// Process line range parameter and return ranges array with keep-offset
/// Converts 1-based line numbers to 0-based indices
/// Supports:
/// - Single range: (start, end) or (range: (start, end), keep-offset: bool)
/// - Multiple ranges: ((start1, end1), (start2, end2), ...) or ((range: (start1, end1), keep-offset: bool), ...)
#let process-line-range(line-range) = {
  // Helper function to process a single range specification
  let process-single-range(range-spec) = {
    if type(range-spec) == array and range-spec.len() == 2 and type(range-spec.at(0)) == int {
      // Simple (start, end) format
      (
        range-spec.at(0) - 1,
        if range-spec.at(1) != none { range-spec.at(1) - 1 } else { none },
        true,
      )
    } else if type(range-spec) == dictionary {
      // Dictionary format with range and keep-offset
      (
        range-spec.range.at(0) - 1,
        if range-spec.range.at(1) != none { range-spec.range.at(1) - 1 } else { none },
        range-spec.at("keep-offset", default: true),
      )
    } else {
      none
    }
  }

  if type(line-range) == array {
    // Check if it's a single range (two integers) or multiple ranges
    if line-range.len() == 2 and type(line-range.at(0)) == int and (type(line-range.at(1)) == int or line-range.at(1) == none) {
      // Single range: (start, end)
      ((
        line-range.at(0) - 1,
        if line-range.at(1) != none { line-range.at(1) - 1 } else { none },
        true,
      ),)
    } else {
      // Multiple ranges: process each element
      line-range.map(process-single-range).filter(r => r != none)
    }
  } else if type(line-range) == dictionary {
    // Single range in dictionary format
    ((
      line-range.range.at(0) - 1,
      if line-range.range.at(1) != none { line-range.range.at(1) - 1 } else { none },
      line-range.at("keep-offset", default: true),
    ),)
  } else {
    // Default: all lines
    ((0, none, true),)
  }
}

/// Extract indentation string from current line or previous lines
/// For empty lines, uses indentation from previous non-comment line
#let extract-indent-string(line, x, lines-result, indentation) = {
  if line.text.trim(whitespace-regex, at: std.start) == "" {
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
}

/// Calculate the display number for a line based on numbering settings
#let calculate-display-number(numbering, line, keep-offset, numbering-offset, start, lines-len) = {
  if numbering == true {
    if keep-offset {
      line.number + numbering-offset
    } else {
      line.number + numbering-offset - start
    }
  } else if numbering == false {
    none
  } else if type(numbering) == array {
    numbering.map(list => {
      assert(
        list.len() == lines-len,
        message: "numbering list length should be equal to lines length",
      )
      list.at(line.number - 1)
    })
  }
}

/// Create a comment object for a highlighted line
#let create-comment-for-line(line-number, comments, comment-flag, comment-font-args, comment-color, line-text) = {
  if comments.keys().contains(str(line-number)) {
    (
      type: "comment",
      indentation: line-text.split(regex("\S")).first(),
      comment-flag: comment-flag,
      body: text(..comment-font-args, comments.at(str(line-number))),
      fill: comment-color,
    )
  } else {
    none
  }
}

/// Process a highlighted line and return line object(s)
#let process-highlight-line(
  line,
  indent-string,
  display-number,
  body,
  highlight-color,
  comment,
  is-html,
  comment-color,
  comment-flag,
) = {
  let result = ()

  // Add highlighted line
  result.push((
    type: "highlight",
    indentation: indent-string,
    number: display-number,
    body: body,
    fill: highlight-color,
    comment: if is-html { comment } else { none },
  ))

  // Add separate comment line if needed (for non-HTML output)
  if not is-html and comment != none {
    result.push((
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

  result
}

/// Process a normal (non-highlighted) line and return line object
#let process-normal-line(
  line,
  indent-string,
  display-number,
  body,
  background-color,
) = {
  (
    type: "normal",
    indentation: indent-string,
    number: display-number,
    body: body,
    fill: background-color-at-index(background-color, line.number),
    comment: none,
  )
}

/// Process lines with multiple range support
/// Slices lines according to ranges and adds separator for skipped lines
#let process-lines(
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
  line-colors: (:), // New parameter for per-line colors
  smart-skip: true, // Show separator between ranges
  skip-text: "{} lines skipped", // Template for skip message, {} will be replaced with line count
) = {
  // Process line ranges (now returns an array of ranges)
  let ranges = process-line-range(line-range)

  let lines-result = ()

  // Process each range
  for (range-idx, range-spec) in ranges.enumerate() {
    let (start, end, keep-offset) = range-spec

    // Slice lines according to range
    let lines-slice = lines.slice(start, end)

    // Helper function to get highlight color for a specific line
    let get-highlight-color(line-number) = {
      // First check if this line has a specific color
      if line-colors.keys().contains(str(line-number)) {
        line-colors.at(str(line-number))
      } else if type(highlight-color) == array {
        // Use array colors cyclically
        let highlight-index = highlight-nums.position(n => n == line-number)
        if highlight-index != none {
          highlight-color.at(calc.rem(highlight-index, highlight-color.len()))
        } else {
          highlight-color.at(0)
        }
      } else {
        // Single color for all highlights
        highlight-color
      }
    }

    // Process each line in the current range
    for (x, line) in lines-slice.enumerate() {
      // Extract indentation string
      let indent-string = extract-indent-string(line, x, lines-result, indentation)

      // Determine body content
      let body = if line.text.trim(whitespace-regex, at: std.start) == "" {
        [\ ]
      } else {
        line.body
      }

      // Calculate line number to display
      let display-number = calculate-display-number(
        numbering,
        line,
        keep-offset,
        numbering-offset,
        start,
        lines-slice.len(),
      )

      // Process highlighted or normal lines
      if type(highlight-nums) == array and highlight-nums.contains(line.number) {
        // Get the color for this specific highlighted line
        let line-highlight-color = get-highlight-color(line.number)

        // Create comment if it exists for this line
        let comment = create-comment-for-line(
          line.number,
          comments,
          comment-flag,
          comment-font-args,
          comment-color,
          line.text,
        )

        // Process highlight line with specific color
        let processed-lines = process-highlight-line(
          line,
          indent-string,
          display-number,
          body,
          line-highlight-color, // Use specific color here
          comment,
          is-html,
          comment-color,
          comment-flag,
        )

        for processed-line in processed-lines {
          lines-result.push(processed-line)
        }
      } else {
        // Add normal line
        lines-result.push(
          process-normal-line(
            line,
            indent-string,
            display-number,
            body,
            background-color,
          ),
        )
      }
    }

    // Add separator between ranges (but not after the last range)
    if smart-skip and range-idx < ranges.len() - 1 {
      // Calculate how many lines were skipped
      let current-end = if end == none { lines.len() } else { end }
      let next-start = ranges.at(range-idx + 1).at(0)
      let skipped-lines = next-start - current-end

      if skipped-lines > 0 {
        // Process skip-text template
        let skip-message = if type(skip-text) == str {
          // Replace {} with the number of skipped lines
          let parts = skip-text.split("{}")
          if parts.len() == 2 {
            [#parts.at(0)#skipped-lines#parts.at(1)]
          } else {
            // Fallback if template format is incorrect
            [#skipped-lines lines skipped]
          }
        } else {
          // If skip-text is content, use it directly
          skip-text
        }
        
        // Add a separator line showing the skip
        lines-result.push((
          indentation: "",
          number: [#text(fill: gray.darken(20%), sym.dots.v)],
          body: text(fill: gray.darken(20%), skip-message),
          fill: background-color-at-index(background-color, lines-result.len()),
          comment: none,
        ))
      }
    }
  }

  lines-result
}

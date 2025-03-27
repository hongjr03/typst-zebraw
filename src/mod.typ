#import "util.typ": *
#import "html.typ": zebraw-html-show

#let zebraw-show(
  args: (:),
  highlight-lines: (),
  numbering-offset: 0,
  header: none,
  footer: none,
  it,
) = {
  // Extract all necessary parameters from args dictionary
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

  // Calculate width for line numbering
  let numbering-width = if numbering {
    if (it.lines.len() + numbering-offset < 100) { 2.1em } else { auto }
  } else { 0pt }

  // Process highlight lines and comments
  let (highlight-nums, comments) = tidy-highlight-lines(highlight-lines)

  // Setup helper functions for layout
  let b(..args, body) = box(width: 100%, inset: inset, ..args, body)

  let g(..args) = grid(
    columns: (numbering-width, 1fr),
    align: (right + top, left),
    ..args,
  )

  // Determine if we should show a language tab
  let has-lang = (type(lang) == bool and lang and it.lang != none) or type(lang) != bool

  // Helper function to render a line (either code or line number)
  let line-render(line, num: false, height: none) = grid.cell(
    fill: line.fill,
    block(
      width: if not num { 100% } else { numbering-width },
      inset: inset,
      context if num {
        // Line number rendering
        set text(..numbering-font-args)
        [#(line.number)]
      } else {
        let line-height = measure("|").height
        if line.keys().contains("indentation") and height != none {
          let indentation-spaces = {
            if indentation > 0 {
              show indentation * " ": box({
                // TODO: fast preview
                if sys.inputs.keys().contains("x-preview") {
                  set text(fill: gray.transparentize(50%))
                  "|" + " " * (indentation - 1)
                } else {
                  place(
                    std.line(
                      start: (0em, -inset.top),
                      end: (0em, if hanging-indent { height - inset.top } else { line-height + inset.bottom }),
                      stroke: .05em + gray.transparentize(50%),
                    ),
                    left + top,
                  )
                  " " * indentation
                }
              })
              line.indentation
            } else {
              line.indentation
            }
          }

          // Code line rendering with indentation handling
          if (
            repr(line.body.func()) == "sequence"
              and line.body.children.first().func() == text
              and line.body.children.first().text.trim() == ""
          ) {
            if hanging-indent {
              par(
                hanging-indent: measure(indentation-spaces).width,
                {
                  indentation-spaces
                  line.body.children.slice(1).join()
                },
              )
            } else {
              indentation-spaces
              line.body.children.slice(1).join()
            }
          } else if (
            repr(line.body.func()) == "text"
          ) {
            indentation-spaces
            line.body.text.trim()
          } else {
            line.body
          }
        } else {
          line.body
        }
      },
    ),
  )

  // Process lines with highlighting, numbers, and comments
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
    indentation: indentation,
    is-html: false,
  )

  // Helper function to create header or footer section
  let create-section(position, content-param, comment-key) = {
    let content = if content-param != none {
      content-param
    } else if comments.keys().contains(comment-key) {
      comments.at(comment-key)
    } else {
      none
    }

    if content != none {
      // Custom header or footer content
      grid.cell(
        align: left + top,
        colspan: 2,
        b(
          inset: inset.pairs().map(((key, value)) => (key, value * 2)).to-dict(),
          radius: if position == "header" {
            if not has-lang { (top: inset.left) } else { (top-left: inset.left) }
          } else {
            (bottom: inset.left)
          },
          fill: comment-color,
          text(..comment-font-args, content),
        ),
      )
    } else if extend {
      // Empty header or footer with background for extension
      grid.cell(
        colspan: 2,
        b(
          fill: curr-background-color(background-color, if position == "header" { 0 } else { lines.len() + 1 }),
          inset: (:) + (if position == "header" { (top: inset.top) } else { (bottom: inset.bottom) }),
          radius: if position == "header" { (top: inset.left) } else { (bottom: inset.left) },
          [],
        ),
      )
    } else {
      none
    }
  }

  // Render language tab if needed
  if has-lang {
    v(-.34em)
    align(
      right,
      block(
        sticky: true,
        inset: 0.34em,
        outset: (bottom: inset.left),
        radius: (top: inset.left),
        fill: lang-color,
        text(
          bottom-edge: "bounds",
          ..lang-font-args,
          if type(lang) == bool { it.lang } else { lang },
        ),
      ),
    )
    v(0em, weak: true)
  }

  // Render the code block
  block(
    breakable: true,
    radius: inset.left,
    clip: true,
    fill: curr-background-color(background-color, 0),
    {
      context layout(code-block-size => {
        // Calculate line heights for consistent rendering
        let last-line = if lines.last().number == none { lines.at(-2) } else { lines.last() }

        // Create line objects with their heights pre-computed
        let lines-with-height = lines.map(line => {
          let height = measure(
            g(line-render(last-line, num: true), line-render(line)),
            width: code-block-size.width,
          ).height
          (line: line, height: height)
        })

        // Create the main grid structure with header, content and footer
        g(
          // 1. Header section
          ..{
            let header-cell = create-section("header", header, "header")
            if header-cell != none { (grid.header(repeat: false, header-cell),) } else { () }
          },

          // 2. Line numbers column
          grid(
            rows: lines-with-height.map(item => item.height),
            ..lines-with-height.map(item => line-render(item.line, num: true))
          ),

          // 3. Code lines column
          grid(
            rows: lines-with-height.map(item => item.height),
            ..lines-with-height.map(item => line-render(item.line, height: item.height))
          ),

          // 4. Footer section
          ..{
            let footer-cell = create-section("footer", footer, "footer")
            if footer-cell != none { (grid.footer(repeat: false, footer-cell),) } else { () }
          },
        )
      })
    },
  )
}

/// Block of code with highlighted lines and comments.
///
/// -> content
#let zebraw(
  /// Whether to show the line numbers.
  ///
  /// #example(
  /// ````typ
  /// #zebraw(
  ///   numbering: false,
  ///   ```typ
  ///   #grid(
  ///     columns: (1fr, 1fr),
  ///     [Hello,], [world!],
  ///    )
  ///   ```
  ///  )
  /// ````,
  /// scale-preview: 100%,
  /// )
  /// -> boolean
  numbering: true,
  /// Lines to highlight or comments to show.
  ///
  /// #example(
  /// ````typ
  /// #zebraw(
  ///   highlight-lines: range(3, 7),
  ///   header: [*Fibonacci sequence*],
  ///   ```typst
  ///   #let count = 8
  ///   #let nums = range(1, count + 1)
  ///   #let fib(n) = (
  ///     if n <= 2 { 1 }
  ///     else { fib(n - 1) + fib(n - 2) }
  ///   )
  ///
  ///   #align(center, table(
  ///     columns: count,
  ///     ..nums.map(n => $F_#n$),
  ///     ..nums.map(n => str(fib(n))),
  ///   ))
  ///   ```,
  ///   footer: [The fibonacci sequence is defined through the recurrence relation $F_n = F_(n-1) + F_(n-2)$],
  /// )
  /// ````,
  /// scale-preview: 100%,
  /// )
  ///
  /// -> array | int
  highlight-lines: (),
  /// The offset of line numbers. The first line number will be `numbering-offset + 1`.
  /// Defaults to `0`.
  /// -> int
  numbering-offset: 0,
  /// The header of the code block.
  ///
  /// -> string | content
  header: none,
  /// The footer of the code block.
  ///
  /// -> string | content
  footer: none,
  /// The inset of each line.
  /// #example(
  /// ````typ
  /// #zebraw(
  ///   inset: (top: 6pt, bottom: 6pt),
  ///   ```typst
  ///   #let count = 8
  ///   #let nums = range(1, count + 1)
  ///   #let fib(n) = (
  ///     if n <= 2 { 1 }
  ///     else { fib(n - 1) + fib(n - 2) }
  ///   )
  ///
  ///   #align(center, table(
  ///     columns: count,
  ///     ..nums.map(n => $F_#n$),
  ///     ..nums.map(n => str(fib(n))),
  ///   ))
  ///   ```,
  /// )
  /// ````,
  /// scale-preview: 100%,
  /// )
  /// -> dictionary
  inset: none,
  /// The background color of the block and normal lines.
  ///
  /// #example(
  /// ````typ
  /// #zebraw(
  ///   background-color: (luma(240), luma(245), luma(250), luma(245)),
  ///   ```typst
  ///   #let count = 8
  ///   #let nums = range(1, count + 1)
  ///   #let fib(n) = (
  ///     if n <= 2 { 1 }
  ///     else { fib(n - 1) + fib(n - 2) }
  ///   )
  ///
  ///   #align(center, table(
  ///     columns: count,
  ///     ..nums.map(n => $F_#n$),
  ///     ..nums.map(n => str(fib(n))),
  ///   ))
  ///   ```,
  /// )
  /// ````,
  /// scale-preview: 100%,
  /// )
  /// -> color | array
  background-color: none,
  /// The background color of the highlighted lines.
  ///
  /// -> color
  highlight-color: none,
  /// The background color of the comments. The color is set to `none` at default and it will be rendered in a lightened `highlight-color`.
  ///
  /// #example(````typ
  /// #zebraw(
  ///   highlight-color: yellow.lighten(80%),
  ///   comment-color: yellow.lighten(90%),
  ///   highlight-lines: (
  ///     (1, [The Fibonacci sequence is defined through the recurrence relation $F_n = F_(n-1) + F_(n-2)$]),
  ///     ..range(9, 14),
  ///     (13, [The first \#count numbers of the sequence.]),
  ///   ),
  ///   ```typ
  ///   = Fibonacci sequence
  ///   #let count = 8
  ///   #let nums = range(1, count + 1)
  ///   #let fib(n) = (
  ///     if n <= 2 { 1 }
  ///     else { fib(n - 1) + fib(n - 2) }
  ///   )
  ///
  ///   #align(center, table(
  ///     columns: count,
  ///     ..nums.map(n => $F_#n$),
  ///     ..nums.map(n => str(fib(n))),
  ///   ))
  ///   ```
  /// )
  /// ````,
  /// scale-preview: 100%)
  ///
  /// -> color
  comment-color: none,
  /// The background color of the language tab. The color is set to `none` at default and it will be rendered in comments' color.
  /// #example(````typ
  /// #zebraw(
  ///   lang: true,
  ///   lang-color: eastern,
  ///   lang-font-args: (
  ///     font: "libertinus serif",
  ///     weight: "bold",
  ///     fill: white
  ///   ),
  ///   ```typst
  ///   #grid(
  ///     columns: (1fr, 1fr),
  ///     [Hello], [world!],
  ///   )
  ///   ```
  /// )
  /// ````,
  /// scale-preview: 100%)
  /// -> color
  lang-color: none,
  /// The flag at the beginning of comments. The indentation of codes will be rendered before the flag. When the flag is set to `""`, the indentation before the flag will be disabled as well.
  ///
  /// #example(````typ
  /// #zebraw(
  ///   comment-flag: "",
  ///   highlight-lines: (
  ///     (1, [The Fibonacci sequence is defined through the recurrence relation $F_n = F_(n-1) + F_(n-2)$]),
  ///     ..range(9, 14),
  ///     (13, [The first \#count numbers of the sequence.]),
  ///   ),
  ///   ```typ
  ///   = Fibonacci sequence
  ///   #let count = 8
  ///   #let nums = range(1, count + 1)
  ///   #let fib(n) = (
  ///     if n <= 2 { 1 }
  ///     else { fib(n - 1) + fib(n - 2) }
  ///   )
  ///
  ///   #align(center, table(
  ///     columns: count,
  ///     ..nums.map(n => $F_#n$),
  ///     ..nums.map(n => str(fib(n))),
  ///   ))
  ///   ```
  /// )
  /// ````,
  /// scale-preview: 100%)
  ///
  /// -> string | content
  comment-flag: none,
  /// Whether to show the language tab, or a string or content of custom language name to display.
  ///
  /// #example(````typ
  /// #zebraw(
  ///   lang: true,
  ///   ```typ
  ///   #grid(
  ///     columns: (1fr, 1fr),
  ///     [Hello,], [world!],
  ///   )
  ///   ```
  /// )
  /// ````,
  /// scale-preview: 100%)
  ///
  /// #example(````typ
  /// #zebraw(
  ///   lang: strong[Typst],
  ///   ```typ
  ///   #grid(
  ///     columns: (1fr, 1fr),
  ///     [Hello,], [world!],
  ///   )
  ///   ```
  /// )
  /// ````,
  /// scale-preview: 100%)
  ///
  /// -> boolean | string | content
  lang: none,
  /// The arguments passed to comments' font.
  ///
  /// -> dictionary
  comment-font-args: none,
  /// The arguments passed to the language tab's font.
  ///
  /// #example(````typ
  /// #zebraw(
  ///   lang: true,
  ///   comment-font-args: (font: "IBM Plex Serif", style: "italic"),
  ///   lang-font-args: (font: "IBM Plex Sans", weight: "bold"),
  ///   highlight-lines: (
  ///     (1, [The Fibonacci sequence is defined through the recurrence relation $F_n = F_(n-1) + F_(n-2)$]),
  ///     ..range(9, 14),
  ///     (13, [The first \#count numbers of the sequence.]),
  ///   ),
  ///   ```typ
  ///   = Fibonacci sequence
  ///   #let count = 8
  ///   #let nums = range(1, count + 1)
  ///   #let fib(n) = (
  ///     if n <= 2 { 1 }
  ///     else { fib(n - 1) + fib(n - 2) }
  ///   )
  ///
  ///   #align(center, table(
  ///     columns: count,
  ///     ..nums.map(n => $F_#n$),
  ///     ..nums.map(n => str(fib(n))),
  ///   ))
  ///   ```
  /// )
  /// ````,
  /// scale-preview: 100%)
  ///
  /// -> dictionary
  lang-font-args: none,
  /// The arguments passed to the line numbers' font.
  ///
  /// #example(````typ
  /// #zebraw(
  ///   numbering-font-args: (fill: blue),
  ///   ```typ
  ///   = Fibonacci sequence
  ///   #let count = 8
  ///   #let nums = range(1, count + 1)
  ///   #let fib(n) = (
  ///     if n <= 2 { 1 }
  ///     else { fib(n - 1) + fib(n - 2) }
  ///   )
  ///
  ///   #align(center, table(
  ///     columns: count,
  ///     ..nums.map(n => $F_#n$),
  ///     ..nums.map(n => str(fib(n))),
  ///   ))
  ///   ```
  /// )
  /// ````,
  /// scale-preview: 100%)
  ///
  /// -> dictionary
  numbering-font-args: none,
  /// Whether to extend the vertical spacing.
  ///
  /// #example(````typ
  /// #zebraw(
  ///   extend: false,
  ///   ```typ
  ///   #grid(
  ///     columns: (1fr, 1fr),
  ///     [Hello,], [world!],
  ///   )
  ///   ```
  /// )
  /// ````,
  /// scale-preview: 100%)
  ///
  /// -> boolean
  extend: none,
  /// Whether to show the hanging indent.
  /// -> boolean
  hanging-indent: none,
  /// The amount of indentation, used to draw indentation lines.
  /// -> int
  indentation: none,
  /// (Only for HTML) The width of the code block.
  /// -> length | relative
  block-width: 42em,
  /// (Only for HTML) Whether to wrap the code lines.
  /// -> boolean
  wrap: true,
  /// The body.
  /// -> content
  body,
) = context {
  show raw.where(block: true): if dictionary(std).keys().contains("html") and target() == "html" {
    zebraw-html-show.with(
      args: parse-zebraw-args(
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
      ),
      highlight-lines: highlight-lines,
      numbering-offset: numbering-offset,
      header: header,
      footer: footer,
      wrap: wrap,
      block-width: block-width,
    )
  } else {
    zebraw-show.with(
      args: parse-zebraw-args(
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
      ),
      highlight-lines: highlight-lines,
      numbering-offset: numbering-offset,
      header: header,
      footer: footer,
    )
  }
  body
}

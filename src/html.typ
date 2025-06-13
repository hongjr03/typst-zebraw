/// HTML output module for Zebraw code highlighting

#import "util.typ": *
#import "html/utils.typ": *

/// Styles a single line of code for HTML output
///
/// Applies text color and font weight styling to code content by wrapping
/// it in HTML span elements with appropriate CSS styles.
#let style-code-line(it, default-color: black) = context {
  // Skip empty lines
  if it.text == "" {
    return none
  }

  // Return whitespace as-is
  if it.text.trim().len() == 0 {
    return it
  }

  // Build CSS style string based on text properties
  let style = {
    let fill = text.fill
    let weight = text.weight

    // Add color style if different from default
    if fill != default-color {
      "color:" + fill.to-hex() + ";"
    }

    // Add font weight if not regular
    if weight != "regular" {
      "font-weight:" + weight
    }
  }

  // Wrap in span element if styling is needed, otherwise return as-is
  if style != none {
    html.elem("span", attrs: (style: style), it)
  } else {
    it
  }
}

/// Renders inline code blocks as HTML
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

  // NOTE: Inline mode does not support highlight or comments for simplicity

  // Helper for creating code line elements
  let create-code-line-elem(line) = {
    // Add indentation spacing
    line.indentation

    // Apply text styling to all text within this line
    show text: style-code-line.with(default-color: text.fill)
    line.body
  }

  // Process lines
  let lines = tidy-lines(
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
    style: create-style(background: curr-background-color(background-color, 0).to-hex()),
  )

  // Add language class for syntax highlighting compatibility
  if it.lang != none {
    // As suggested by whatwg, https://html.spec.whatwg.org/
    attrs.insert("class", "language-" + it.lang)
  }

  // Create the main inline code element
  html.elem("code", attrs: attrs, lines.map(create-code-line-elem).join())
}

/// Renders full-featured code blocks as HTML
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

  // Calculate optimal width for line numbering column
  let numbering-width = if numbering == true {
    // Auto-adjust width based on total line count
    if it.lines.len() + numbering-offset < 100 { 1.5em } else { auto }
  } else if type(numbering) == array {
    auto // Custom numbering may have variable width
  } else {
    0 // No numbering
  }

  // HTML attributes for line number elements
  let lineno-attrs = (
    class: class-list("lineno", if numbering-separator { "sep" }),
    style: create-style(width: repr-or-str(numbering-width)),
  )

  // Store default styling values to avoid duplicated styling
  let default-color = text.fill
  let default-bg = curr-background-color(background-color, 0)

  /// Creates HTML element for line numbers
  let create-lineno(lineno) = {
    set text(..numbering-font-args)
    html.elem("span", attrs: lineno-attrs, if type(lineno) == array {
      // TODO: Multi-numbering display can be improved
      lineno.map(n => html.elem("span", n)).join()
    } else {
      [#lineno]
    })
  }

  /// Creates highlight background wrapper for lines
  let create-highlight(line, bg) = {
    html.elem(
      "span",
      attrs: (
        class: "hll", // "highlighted line" class
        style: create-style(
          background: bg.to-hex(),
          // Extend highlight to full width by using negative margins
          margin: "0 " + repr-or-str(-inset.right) + " 0 " + repr-or-str(-inset.left),
          padding: "0 " + repr-or-str(inset.right) + " 0 " + repr-or-str(inset.left),
        ),
      ),
      line,
    )
  }

  /// Helper function to create complete HTML elements for code lines
  let create-code-line-elem(line) = {
    // Build the main line content
    let line-elem = {
      // Add line number if numbering is enabled
      if numbering-width != 0 {
        create-lineno(line.number)
      }

      line.indentation

      // NOTE: when the line is empty, there is a redundant linebreak
      show linebreak: none
      show text: style-code-line.with(default-color: default-color)
      line.body
    }

    // Wrap in highlight background if needed
    let bg = line.fill
    let is-block = false
    if bg != default-bg {
      is-block = true
      line-elem = create-highlight(line-elem, bg)
    }

    (line-elem, is-block)
  }

  /// Creates header/footer element
  let create-header-footer(content, bg) = {
    html.elem(
      "span",
      attrs: (
        class: "header",
        style: create-style(
          padding: repr-or-str(inset.right) + " " + repr-or-str(inset.left),
          background: bg.to-hex(),
        ),
      ),
      text(..comment-font-args, content),
    )
  }

  /// Creates the language label element
  let create-lang-label() = {
    html.elem(
      "div",
      attrs: (
        class: "zebraw-code-lang",
        style: create-style(
          background: lang-color.to-hex(),
          border-radius: repr-or-str(inset.left),
        ),
        translate: "no", // Prevent translation of code language names
      ),
      if type(lang) == bool { it.lang } else { lang },
    )
  }

  // Build the complete HTML structure: div > pre > code
  html.elem("div", attrs: (class: "zebraw-code-block"), {
    // Add language label at the top if configured
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
        // Add header if specified
        create-header-footer(
          if header != none { header } else { comments.at("header", default: none) },
          curr-background-color(background-color, 0),
        )

        {
          // Render all code lines with proper linebreaks
          let is-prev-block = true
          for line in lines {
            let (line-elem, is-cur-block) = create-code-line-elem(line)

            // Add newline separator between non-block elements
            if not (is-prev-block or is-cur-block) {
              "\n"
            }
            is-prev-block = is-cur-block
            line-elem
          }
        }

        // Add footer if specified
        create-header-footer(
          if footer != none { footer } else { comments.at("footer", default: none) },
          curr-background-color(background-color, lines.len() + 1),
        )
      })
    })
  })
}

/// Generates CSS styles for HTML code blocks
///
/// Returns a <style> element containing all the CSS rules needed for
/// proper display of Zebraw-generated HTML code blocks.
#let zebraw-html-styles() = {
  html.elem("style", read("html/styles.css"))
}

/// Generates JavaScript for clipboard copy functionality
///
/// Returns a <script> element containing JavaScript code that enables
/// copy-to-clipboard functionality for code blocks.
#let zebraw-html-clipboard-copy() = {
  html.elem("script", read("html/clipboard-copy.js"))
}

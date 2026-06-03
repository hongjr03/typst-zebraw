#import "layouts.typ" as layout-presets

#let _classes(..items) = {
  let classes = ()
  for item in items.pos() {
    if item != none and item != false and item != "" {
      classes.push(item)
    }
  }
  classes.join(" ")
}

#let _attr-dict(
  class: none,
  translate: none,
  aria_hidden: none,
  data_language: none,
  data_source_line: none,
  data_indent: none,
  data_copy_text: none,
) = {
  let attrs = (:)
  if class != none {
    attrs.insert("class", class)
  }
  if translate != none {
    attrs.insert("translate", translate)
  }
  if aria_hidden != none {
    attrs.insert("aria-hidden", aria_hidden)
  }
  if data_language != none {
    attrs.insert("data-language", data_language)
  }
  if data_source_line != none {
    attrs.insert("data-source-line", data_source_line)
  }
  if data_indent != none {
    attrs.insert("data-indent", data_indent)
  }
  if data_copy_text != none {
    attrs.insert("data-copy-text", data_copy_text)
  }
  attrs
}

#let _display-value(value) = {
  if value == none {
    []
  } else {
    [#value]
  }
}

#let _display-number(number) = {
  if number == none {
    []
  } else if type(number) == array {
    let cells = ()
    for item in number {
      cells.push(html.elem("span", attrs: (class: "zebraw-number-cell"), _display-value(item)))
    }
    cells.join()
  } else {
    _display-value(number)
  }
}

#let _line-attrs(row) = {
  let attrs = (
    class: _classes(
      "zebraw-row",
      "is-" + row.kind,
      if row.annotation != none and row.annotation.highlighted { "is-highlighted" },
      if row.annotation != none and row.annotation.comment != none { "has-comment" },
    ),
  )

  if row.source-number != none {
    attrs.insert("data-source-line", str(row.source-number))
  }

  attrs
}

#let _gutter(row, layout-plan) = {
  if layout-plan.gutter.placement == "hidden" or row.display-number == none {
    []
  } else {
    html.elem(
      "span",
      attrs: _attr-dict(
        class: "zebraw-gutter",
        aria_hidden: "true",
      ),
      _display-number(row.display-number),
    )
  }
}

#let _code(row) = {
  html.elem(
    "span",
    attrs: _attr-dict(
      class: "zebraw-code",
      translate: "no",
      data_indent: str(row.effective-indent-width),
    ),
    if row.kind == "blank" { [] } else { row.body },
  )
}

#let _comment(row, layout-plan) = {
  if row.annotation == none or row.annotation.comment == none or layout-plan.comments.placement == "hidden" {
    []
  } else {
    html.elem(
      "span",
      attrs: _attr-dict(
        class: "zebraw-comment",
        aria_hidden: "true",
      ),
      row.annotation.comment,
    )
  }
}

#let _skip(row) = html.elem(
  "span",
  attrs: _attr-dict(
    class: "zebraw-skip-label",
    aria_hidden: "true",
  ),
  row.body,
)

#let _row(row, layout-plan) = {
  if row.kind == "comment" {
    return []
  }

  html.elem(
    "span",
    attrs: _line-attrs(row),
    if row.kind == "skip" {
      _skip(row)
    } else {
      _gutter(row, layout-plan)
      _code(row)
      if layout-plan.comments.placement == "beside-line" {
        _comment(row, layout-plan)
      }
    },
  )
}

#let _copy-text(rows) = {
  let lines = ()
  for row in rows {
    if row.kind == "code" or row.kind == "blank" {
      lines.push(row.copy-text)
    }
  }
  lines.join("\n")
}

#let _style() = html.elem(
  "style",
  ".zebraw{display:block}.zebraw-pre{margin:0;overflow:auto}.zebraw-code-root{display:block;white-space:pre}.zebraw-row{display:block}.zebraw-gutter{display:inline-block;min-width:3ch;margin-right:1ch;text-align:right;user-select:none}.zebraw-number-cell{display:inline-block;min-width:2ch;text-align:right}.zebraw-number-cell+.zebraw-number-cell{margin-left:.5ch}.zebraw-comment,.zebraw-skip-label{user-select:none}",
)

#let render-html(model, style: (:), layout-plan: layout-presets.default, components-plan: (:)) = {
  let layout-plan = layout-presets.resolve(layout-plan)
  let rows = model.rows.filter(row => row.kind != "comment")
  let code-attrs = _attr-dict(
    class: _classes("zebraw-code-root", if model.lang != none { "language-" + model.lang }),
    translate: "no",
  )

  html.elem(
    "div",
    attrs: _attr-dict(
      class: _classes("zebraw", if model.lang != none { "language-" + model.lang }),
      data_language: if model.lang == none { "plaintext" } else { model.lang },
      data_copy_text: _copy-text(rows),
    ),
    {
      _style()
      if model.chrome.lang-label != none {
        html.elem("div", attrs: _attr-dict(class: "zebraw-lang", aria_hidden: "true"), [#model.chrome.lang-label])
      }
      html.elem(
        "pre",
        attrs: (class: "zebraw-pre"),
        html.elem(
          "code",
          attrs: code-attrs,
          rows.map(row => _row(row, layout-plan)).join(),
        ),
      )
    },
  )
}

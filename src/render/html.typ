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
  type: none,
  translate: none,
  aria_hidden: none,
  aria_label: none,
  data_language: none,
  data_source_line: none,
  data_indent: none,
  data_copy_text: none,
  data_state: none,
  style: none,
) = {
  let attrs = (:)
  if class != none {
    attrs.insert("class", class)
  }
  if type != none {
    attrs.insert("type", type)
  }
  if translate != none {
    attrs.insert("translate", translate)
  }
  if aria_hidden != none {
    attrs.insert("aria-hidden", aria_hidden)
  }
  if aria_label != none {
    attrs.insert("aria-label", aria_label)
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
  if data_state != none {
    attrs.insert("data-state", data_state)
  }
  if style != none {
    attrs.insert("style", style)
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

#let _gutter-placement(layout-plan) = {
  assert(
    layout-plan.gutter.at("enabled", default: none) == none,
    message: "zebraw: layout.gutter.enabled was removed; use gutter placement hidden instead",
  )

  let placement = layout-plan.gutter.placement
  assert(
    placement == "left" or placement == "right" or placement == "hidden",
    message: "zebraw: html gutter placement currently supports left, right, or hidden",
  )
  placement
}

#let _has-gutter(rows, layout-plan) = {
  if _gutter-placement(layout-plan) == "hidden" {
    return false
  }

  for row in rows {
    if row.display-number != none {
      return true
    }
  }
  false
}

#let _gutter(row, has-gutter) = {
  if not has-gutter {
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

#let _gutter-separator(layout-plan, has-gutter) = {
  if not has-gutter or not layout-plan.gutter.separator {
    []
  } else {
    html.elem(
      "span",
      attrs: _attr-dict(
        class: "zebraw-gutter-separator",
        aria_hidden: "true",
      ),
    )
  }
}

#let _comment-placement(layout-plan) = {
  assert(type(layout-plan.comments.indent) == bool, message: "zebraw: layout.comments.indent must be a boolean")
  let flag = layout-plan.comments.flag
  assert(
    flag == none or type(flag) == str or type(flag) == content,
    message: "zebraw: layout.comments.flag must be none, a string, or content",
  )

  let placement = layout-plan.comments.placement
  assert(
    placement == "below-line" or placement == "beside-line" or placement == "hidden",
    message: "zebraw: html comments placement currently supports below-line, beside-line, or hidden",
  )
  placement
}

#let _indent-guide-plan(layout-plan) = {
  let plan = layout-plan.indent-guides
  if not plan.enabled {
    return plan
  }

  assert(plan.unit > 0, message: "zebraw: layout.indent-guides.unit must be positive")
  assert(
    plan.mode == "line" or plan.mode == "fast-preview",
    message: "zebraw: html indent guide mode currently supports line or fast-preview",
  )
  plan
}

#let _indent-guide-columns(row, layout-plan) = {
  let plan = _indent-guide-plan(layout-plan)
  if not plan.enabled or not (row.kind == "code" or row.kind == "blank") {
    return ()
  }

  let columns = ()
  for column in range(row.effective-indent-width) {
    if calc.rem(column, plan.unit) == 0 {
      columns.push(column)
    }
  }
  columns
}

#let _indent-guides(row, layout-plan) = {
  let guides = ()
  for column in _indent-guide-columns(row, layout-plan) {
    guides.push(html.elem(
      "span",
      attrs: _attr-dict(
        class: "zebraw-indent-guide",
        aria_hidden: "true",
        style: "--zebraw-guide-column:" + str(column),
      ),
    ))
  }
  guides.join()
}

#let _code(row, layout-plan) = {
  html.elem(
    "span",
    attrs: _attr-dict(
      class: "zebraw-code",
      translate: "no",
      data_indent: str(row.effective-indent-width),
    ),
    {
      _indent-guides(row, layout-plan)
      if row.kind == "blank" { [] } else { row.body }
    },
  )
}

#let _comment-flag(flag) = {
  if flag == none or flag == "" {
    none
  } else if type(flag) == str {
    [#flag]
  } else {
    flag
  }
}

#let _comment-indent(row, layout-plan) = {
  if not layout-plan.comments.indent or row.effective-indent-width == 0 {
    []
  } else {
    html.elem(
      "span",
      attrs: _attr-dict(
        class: "zebraw-comment-indent",
        aria_hidden: "true",
        style: "--zebraw-comment-indent:" + str(row.effective-indent-width),
      ),
    )
  }
}

#let _comment-content(row, body, layout-plan) = {
  let flag = _comment-flag(layout-plan.comments.flag)
  _comment-indent(row, layout-plan)
  if flag != none {
    html.elem(
      "span",
      attrs: _attr-dict(
        class: "zebraw-comment-flag",
        aria_hidden: "true",
        style: "margin-right:" + repr(layout-plan.comments.flag-gap),
      ),
      flag,
    )
  }
  html.elem(
    "span",
    attrs: _attr-dict(class: "zebraw-comment-body"),
    body,
  )
}

#let _comment(row, layout-plan) = {
  if row.annotation == none or row.annotation.comment == none or _comment-placement(layout-plan) == "hidden" {
    []
  } else {
    html.elem(
      "span",
      attrs: _attr-dict(
        class: "zebraw-comment",
        aria_hidden: "true",
      ),
      _comment-content(row, row.annotation.comment, layout-plan),
    )
  }
}

#let _comment-row(row, layout-plan, has-gutter) = {
  let placement = _gutter-placement(layout-plan)
  let gutter = _gutter(row, has-gutter)
  let separator = _gutter-separator(layout-plan, has-gutter)
  let body = html.elem(
    "span",
    attrs: _attr-dict(
      class: "zebraw-comment",
      data_indent: str(row.effective-indent-width),
      aria_hidden: "true",
    ),
    _comment-content(row, row.body, layout-plan),
  )

  html.elem(
    "span",
    attrs: _attr-dict(
      class: _classes("zebraw-row", "is-comment"),
      data_source_line: str(row.source-number),
    ),
    if placement == "right" {
      body
      separator
      gutter
    } else {
      gutter
      separator
      body
    },
  )
}

#let _skip(row) = html.elem(
  "span",
  attrs: _attr-dict(
    class: "zebraw-skip-label",
    aria_hidden: "true",
  ),
  row.body,
)

#let _row(row, layout-plan, has-gutter) = {
  if row.kind == "comment" {
    return _comment-row(row, layout-plan, has-gutter)
  }

  let placement = _gutter-placement(layout-plan)
  let gutter = _gutter(row, has-gutter)
  let separator = _gutter-separator(layout-plan, has-gutter)
  let body = if row.kind == "skip" {
    _skip(row)
  } else {
    _code(row, layout-plan)
    if _comment-placement(layout-plan) == "beside-line" {
      _comment(row, layout-plan)
    }
  }

  html.elem(
    "span",
    attrs: _line-attrs(row),
    if placement == "right" {
      body
      separator
      gutter
    } else {
      gutter
      separator
      body
    },
  )
}

#let _visible-rows(rows, layout-plan) = {
  let placement = _comment-placement(layout-plan)
  let visible = ()
  for row in rows {
    if row.kind == "comment" and placement != "below-line" {
    } else if row.kind == "skip" and layout-plan.skip.placement == "hidden" {
    } else {
      visible.push(row)
    }
  }
  visible
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
  ".zebraw{display:block}.zebraw-pre{margin:0;overflow:auto}.zebraw-code-root{display:block;white-space:pre}.zebraw.is-wrapped .zebraw-code-root{white-space:pre-wrap;overflow-wrap:anywhere}.zebraw-row{display:block}.zebraw-gutter{display:inline-block;min-width:3ch;text-align:right;user-select:none}.zebraw-gutter-separator{display:inline-block;width:0;margin:0 .5ch;border-left:1px solid currentColor;opacity:.35;user-select:none}.zebraw-number-cell{display:inline-block;min-width:2ch;text-align:right}.zebraw-number-cell+.zebraw-number-cell{margin-left:.5ch}.zebraw-code{position:relative}.zebraw-indent-guide{position:absolute;top:0;bottom:0;left:calc(var(--zebraw-guide-column)*1ch);border-left:1px solid currentColor;opacity:.35;pointer-events:none}.zebraw-comment,.zebraw-skip-label{user-select:none}.zebraw-comment-indent{display:inline-block;width:calc(var(--zebraw-comment-indent)*1ch)}.zebraw-comment-flag{display:inline-block}.zebraw-copy-button{float:right}",
)

#let _copy-button() = html.elem(
  "button",
  attrs: _attr-dict(
    class: "zebraw-copy-button",
    type: "button",
    aria_label: "Copy code",
    data_state: "idle",
  ),
  [Copy],
)

#let _copy-script() = html.elem(
  "script",
  "if(!window.__zebrawCopyHandler){window.__zebrawCopyHandler=true;document.addEventListener('click',function(event){var button=event.target.closest('.zebraw-copy-button');if(!button){return;}var root=button.closest('.zebraw');if(!root){return;}var text=root.getAttribute('data-copy-text')||'';var done=function(){button.setAttribute('data-state','copied');setTimeout(function(){button.setAttribute('data-state','idle');},1200);};if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(text).then(done,done);}else{var area=document.createElement('textarea');area.value=text;area.setAttribute('readonly','');area.style.position='fixed';area.style.opacity='0';document.body.appendChild(area);area.select();try{document.execCommand('copy');}finally{document.body.removeChild(area);done();}}});}",
)

#let _html-plan(layout-plan) = {
  let plan = layout-plan.html
  assert(type(plan.wrap) == bool, message: "zebraw: layout.html.wrap must be a boolean")
  assert(type(plan.copy-button) == bool, message: "zebraw: layout.html.copy-button must be a boolean")
  plan
}

#let _chrome(model, layout-plan, slot) = {
  let content = if slot == "header" {
    model.chrome.header
  } else {
    model.chrome.footer
  }
  let placement = if slot == "header" {
    layout-plan.header.placement
  } else {
    layout-plan.footer.placement
  }

  if content == none or placement == "hidden" {
    []
  } else {
    html.elem("div", attrs: _attr-dict(class: "zebraw-" + slot), content)
  }
}

#let render-html(model, style: (:), layout-plan: layout-presets.default, components-plan: (:)) = {
  let layout-plan = layout-presets.resolve(layout-plan)
  let html-plan = _html-plan(layout-plan)
  let rows = _visible-rows(model.rows, layout-plan)
  let has-gutter = _has-gutter(rows, layout-plan)
  let code-attrs = _attr-dict(
    class: _classes("zebraw-code-root", if model.lang != none { "language-" + model.lang }),
    translate: "no",
  )

  html.elem(
    "div",
    attrs: _attr-dict(
      class: _classes("zebraw", if html-plan.wrap { "is-wrapped" }, if model.lang != none { "language-" + model.lang }),
      data_language: if model.lang == none { "plaintext" } else { model.lang },
      data_copy_text: _copy-text(rows),
    ),
    {
      _style()
      if html-plan.copy-button {
        _copy-button()
        _copy-script()
      }
      if model.chrome.lang-label != none {
        html.elem("div", attrs: _attr-dict(class: "zebraw-lang", aria_hidden: "true"), [#model.chrome.lang-label])
      }
      html.elem(
        "pre",
        attrs: (class: "zebraw-pre"),
        html.elem(
          "code",
          attrs: code-attrs,
          {
            _chrome(model, layout-plan, "header")
            rows.map(row => _row(row, layout-plan, has-gutter)).join()
            _chrome(model, layout-plan, "footer")
          },
        ),
      )
    },
  )
}

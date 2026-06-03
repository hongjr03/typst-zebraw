#let default = (
  inset: (top: 0.34em, right: 0.5em, bottom: 0.34em, left: 0.5em),
  numbers: (
    width: 2.4em,
    gutter: 0.4em,
    placement: "start",
    separator: false,
    separator-width: 0.05em,
    column-gutter: 0.35em,
  ),
  comments: (
    placement: "below-line",
    width: 14em,
    gap: 0.5em,
    flag: none,
    flag-gap: 0.35em,
    indent: false,
  ),
  indent-guides: (
    enabled: false,
    unit: 2,
    mode: "line",
    line-width: 0.05em,
  ),
  code: (
    hanging-indent: false,
  ),
  skip: (
    placement: "body",
  ),
  header: (
    placement: "above",
    inset: auto,
  ),
  footer: (
    placement: "below",
    inset: auto,
  ),
  lang-tab: (
    placement: "top-right",
  ),
  html: (
    wrap: true,
    copy-button: false,
  ),
  frame: (
    breakable: true,
    width: 100%,
    clip: true,
  ),
)

#let _resolve-inset(inset) = {
  if type(inset) == dictionary {
    (top: 0pt, right: 0pt, bottom: 0pt, left: 0pt) + inset
  } else {
    (top: inset, right: inset, bottom: inset, left: inset)
  }
}

#let _edge-inset(inset, slot) = {
  if slot == "header" {
    inset + (bottom: 0pt)
  } else {
    inset + (top: 0pt)
  }
}

#let _resolve-chrome(plan, base-inset, slot) = {
  let inset = if plan.inset == auto {
    _edge-inset(base-inset, slot)
  } else {
    _resolve-inset(plan.inset)
  }

  plan + (inset: inset)
}

#let _set-plan(state, plan) = state + (plan: plan)

#let _merge-section(state, key, patch) = {
  let plan = state.plan
  let section = plan.at(key, default: (:)) + patch
  plan.insert(key, section)
  _set-plan(state, plan)
}

#let _op(name, fields: (:)) = metadata((
  kind: "zebraw-layout-op",
  name: name,
  fields: fields,
))

#let _body-children(body) = {
  if body == none {
    ()
  } else if type(body) == array {
    body
  } else if type(body) == content and repr(body.func()) == "sequence" {
    body.fields().children
  } else {
    (body,)
  }
}

#let _layout-op(item) = {
  assert(type(item) == content and item.func() == metadata, message: "zebraw: layout body can only contain layout primitives")
  let value = item.fields().value
  assert(
    type(value) == dictionary and value.at("kind", default: none) == "zebraw-layout-op",
    message: "zebraw: layout body can only contain layout primitives",
  )
  value
}

#let _apply-op(state, item) = {
  let op = _layout-op(item)
  let fields = op.fields

  if op.name == "patch" {
    _set-plan(state, state.plan + fields.patch)
  } else if op.name == "inset" {
    _set-plan(state, state.plan + (inset: fields.value))
  } else if op.name == "section" {
    _merge-section(state, fields.key, fields.patch)
  } else if op.name == "apply" {
    assert(type(fields.layout) == function, message: "zebraw: layouts.apply expects a layout function")
    let next = (fields.layout)(state)
    if type(next) == dictionary and next.at("plan", default: none) != none {
      next
    } else {
      _set-plan(state, next)
    }
  } else if op.name == "custom" {
    assert(type(fields.render) == function, message: "zebraw: layouts.custom expects a render function")
    state + (render: fields.render)
  } else {
    panic("zebraw: unknown layout primitive " + repr(op.name))
  }
}

#let compose(..args) = {
  let pos = args.pos()
  assert(pos.len() <= 1, message: "zebraw: layouts.compose expects at most one body")
  let body = if pos.len() == 0 { none } else { pos.first() }
  let items = _body-children(body)
  state => {
    let out = state
    for item in items {
      out = _apply-op(out, item)
    }
    out
  }
}

#let patch(..overrides) = _op("patch", fields: (patch: overrides.named()))
#let inset(value) = _op("inset", fields: (value: value))
#let numbers(..overrides) = _op("section", fields: (key: "numbers", patch: overrides.named()))
#let comments(..overrides) = _op("section", fields: (key: "comments", patch: overrides.named()))
#let indent-guides(..overrides) = _op("section", fields: (key: "indent-guides", patch: overrides.named()))
#let code(..overrides) = _op("section", fields: (key: "code", patch: overrides.named()))
#let skip(..overrides) = _op("section", fields: (key: "skip", patch: overrides.named()))
#let header(..overrides) = _op("section", fields: (key: "header", patch: overrides.named()))
#let footer(..overrides) = _op("section", fields: (key: "footer", patch: overrides.named()))
#let lang-tab(..overrides) = _op("section", fields: (key: "lang-tab", patch: overrides.named()))
#let html(..overrides) = _op("section", fields: (key: "html", patch: overrides.named()))
#let frame(..overrides) = _op("section", fields: (key: "frame", patch: overrides.named()))
#let apply(layout) = _op("apply", fields: (layout: layout))
#let custom(render) = _op("custom", fields: (render: render))

#let _initial-state(ctx) = ctx + (
  plan: default,
  render: none,
)

#let _layout-result(layout, ctx) = {
  if type(layout) == function {
    layout(_initial-state(ctx))
  } else {
    layout
  }
}

#let resolve(layout, model: none, target: none) = {
  let layout = if type(layout) == dictionary and layout.at("plan", default: none) != none {
    layout.plan
  } else {
    layout
  }
  assert(type(layout) == dictionary, message: "zebraw: layout must be a layout function or dictionary plan")

  let inset = _resolve-inset(layout.at("inset", default: default.inset))
  let header = _resolve-chrome(default.header + layout.at("header", default: (:)), inset, "header")
  let footer = _resolve-chrome(default.footer + layout.at("footer", default: (:)), inset, "footer")

  (
    inset: inset,
    numbers: default.numbers + layout.at("numbers", default: (:)),
    comments: default.comments + layout.at("comments", default: (:)),
    indent-guides: default.indent-guides + layout.at("indent-guides", default: (:)),
    code: default.code + layout.at("code", default: (:)),
    skip: default.skip + layout.at("skip", default: (:)),
    header: header,
    footer: footer,
    lang-tab: default.lang-tab + layout.at("lang-tab", default: (:)),
    html: default.html + layout.at("html", default: (:)),
    frame: default.frame + layout.at("frame", default: (:)),
  )
}

#let render(layout, ctx, default-render) = {
  let result = _layout-result(layout, ctx)

  if type(result) == content {
    return result
  }

  let state = if type(result) == dictionary and result.at("plan", default: none) != none {
    result
  } else {
    _initial-state(ctx) + (plan: result)
  }

  let plan = resolve(state.plan, model: ctx.block, target: ctx.target)
  let state = state + (plan: plan)

  if state.render != none {
    (state.render)(state)
  } else {
    default-render(plan)
  }
}

#import "source.typ": source-from-raw
#import "model.typ": build-block-model
#import "render/debug.typ": render-debug
#import "render/pdf.typ": render-pdf
#import "render/html.typ": render-html
#import "render/layouts.typ" as layouts
#import "render/components.typ" as components
#import "selectors.typ" as selectors
#import "annotations.typ" as annotations
#import "numbering.typ" as numbering

#let default-layout = layouts.compose()
#let default-components = components.default
#let default-numbering = numbering.line()
#let default-target = "pdf"

#let _summary-marker(model) = {
  if model.label == none {
    []
  } else {
    [#metadata(model.summary) #model.label]
  }
}

/// Render a raw block with Zebraw.
#let zebraw(
  target: default-target,
  select: none,
  annotate: none,
  numbering: default-numbering,
  style: (:),
  layout: default-layout,
  components: default-components,
  body,
) = {
  if type(body) != content or body.func() != raw or not body.block {
    return body
  }

  context {
    let source = source-from-raw(body)
    let model = build-block-model(
      source,
      select: select,
      annotate: annotate,
      numbering: numbering,
    )

    if target == "debug" {
      render-debug(model)
    } else if target == "pdf" {
      render-pdf(
        model,
        style: style,
        layout-plan: layout,
        components-plan: components,
      )
    } else if target == "html" {
      render-html(
        model,
        style: style,
        layout-plan: layout,
        components-plan: components,
      )
    } else {
      panic("zebraw: unsupported render target " + repr(target))
    }

    _summary-marker(model)
  }
}

#import "source.typ": source-from-raw
#import "model.typ": build-block-model
#import "render/debug.typ": render-debug
#import "render/pdf.typ": render-pdf
#import "render/layouts.typ" as layouts
#import "render/components.typ" as components
#import "selectors.typ" as selectors
#import "annotations.typ" as annotations
#import "numbering.typ" as numbering

#let default-layout = layouts.default
#let default-components = components.default
#let default-numbering = numbering.line()

#let _summary-marker(model) = {
  if model.label == none {
    []
  } else {
    [#metadata(model.summary) #model.label]
  }
}

/// Render a raw block with Zebraw.
#let zebraw(
  select: none,
  annotate: none,
  numbering: default-numbering,
  style: (:),
  layout: default-layout,
  components: default-components,
  debug: false,
  body,
) = {
  if type(body) != content or body.func() != raw {
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

    if debug {
      render-debug(model)
    } else {
      render-pdf(
        model,
        style: style,
        layout-plan: layout,
        components-plan: components,
      )
    }

    _summary-marker(model)
  }
}

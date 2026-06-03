#import "source.typ": source-from-raw
#import "model.typ": build-block-model
#import "render/debug.typ": render-debug
#import "render/pdf.typ": render-pdf
#import "selectors.typ" as selectors
#import "annotations.typ" as annotations

/// Render a raw block with Zebraw.
#let zebraw(
  select: none,
  annotate: none,
  numbering: true,
  numbering-offset: 0,
  style: (:),
  debug: false,
  body,
) = {
  if type(body) != content or body.func() != raw {
    return body
  }

  let source = source-from-raw(body)
  let model = build-block-model(
    source,
    select: select,
    annotate: annotate,
    numbering: numbering,
    numbering-offset: numbering-offset,
  )

  if debug {
    render-debug(model)
  } else {
    render-pdf(model, style: style)
  }
}

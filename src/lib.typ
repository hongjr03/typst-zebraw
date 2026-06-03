#import "source.typ": source-from-raw
#import "model.typ": build-block-model
#import "render/debug.typ": render-debug
#import "selectors.typ" as selectors

/// Render a raw block with Zebraw.
///
/// The first v1 slice intentionally renders the internal model in a readable
/// debug form. PDF and HTML renderers will consume the same model later.
#let zebraw(
  select: none,
  highlight-lines: (),
  numbering: true,
  numbering-offset: 0,
  body,
) = {
  if type(body) != content or body.func() != raw {
    return body
  }

  let source = source-from-raw(body)
  let model = build-block-model(
    source,
    select: select,
    highlight-lines: highlight-lines,
    numbering: numbering,
    numbering-offset: numbering-offset,
  )

  render-debug(model)
}

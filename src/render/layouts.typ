#let default = (
  gutter: (
    enabled: true,
    width: 2.4em,
    gap: 0.4em,
    placement: "left",
  ),
  comments: (
    placement: "below-line",
  ),
  skip: (
    placement: "body",
  ),
  frame: (
    breakable: true,
    width: 100%,
    clip: true,
  ),
)

#let resolve(layout) = (
  gutter: default.gutter + layout.at("gutter", default: (:)),
  comments: default.comments + layout.at("comments", default: (:)),
  skip: default.skip + layout.at("skip", default: (:)),
  frame: default.frame + layout.at("frame", default: (:)),
)

#let with(..overrides) = resolve(overrides.named())

#let default = (
  gutter: (
    enabled: true,
    width: 2.4em,
    gap: 0.4em,
    placement: "left",
  ),
  comments: (
    placement: "below-line",
    width: 14em,
    gap: 0.5em,
  ),
  skip: (
    placement: "body",
  ),
  header: (
    placement: "above",
  ),
  footer: (
    placement: "below",
  ),
  lang-tab: (
    placement: "top-right",
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
  header: default.header + layout.at("header", default: (:)),
  footer: default.footer + layout.at("footer", default: (:)),
  lang-tab: default.lang-tab + layout.at("lang-tab", default: (:)),
  frame: default.frame + layout.at("frame", default: (:)),
)

#let with(..overrides) = resolve(overrides.named())

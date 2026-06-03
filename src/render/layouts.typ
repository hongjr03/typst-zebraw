#let default = (
  gutter: (
    width: 2.4em,
    gap: 0.4em,
    placement: "left",
    separator: false,
    separator-width: 0.05em,
    number-gap: 0.35em,
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
  ),
  footer: (
    placement: "below",
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

#let resolve(layout) = (
  gutter: default.gutter + layout.at("gutter", default: (:)),
  comments: default.comments + layout.at("comments", default: (:)),
  indent-guides: default.indent-guides + layout.at("indent-guides", default: (:)),
  code: default.code + layout.at("code", default: (:)),
  skip: default.skip + layout.at("skip", default: (:)),
  header: default.header + layout.at("header", default: (:)),
  footer: default.footer + layout.at("footer", default: (:)),
  lang-tab: default.lang-tab + layout.at("lang-tab", default: (:)),
  html: default.html + layout.at("html", default: (:)),
  frame: default.frame + layout.at("frame", default: (:)),
)

#let with(..overrides) = resolve(overrides.named())

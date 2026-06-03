#let zebraw(body) = {
  if body.func() == raw {
    yaml.encode(body)
  }
}

#import "src/lib.typ": zebraw-html

= 🦓 Zebraw but in HTML world

== Example

#let example = ````typ
#zebraw-html(
  highlight-lines: (
    (3, [to avoid negative numbers]),
    (9, "50 => 12586269025"),
  ),
  lang: true,
  block-width: 32em,
  line-width: 80em,
  wrap: false,
  ```rust
  pub fn fibonacci_reccursive(n: i32) -> u64 {
      if n < 0 {
          panic!("{} is negative!", n);
      }
      match n {
          0 => panic!("zero is not a right argument to fibonacci_reccursive()!"), 0 => panic!("zero is not a right argument to fibonacci_reccursive()!"),
          1 | 2 => 1,
          3 => 2,
          _ => fibonacci_reccursive(n - 1) + fibonacci_reccursive(n - 2),
      }
  }
  ```,
)
````

#html.elem(
  "div",
  attrs: (style: "display: flex; flex-direction: row; gap: 1em;"),
  (
    html.elem("pre", attrs: (style: "width: 50%; white-space: pre-wrap"), example.text),
    eval(example.text, mode: "markup", scope: (zebraw-html: zebraw-html)),
  ).join(),
)

#let example = ````typ
#zebraw-html(
  highlight-lines: (
    (3, [to avoid negative numbers]),
    (9, "50 => 12586269025"),
  ),
  lang: true,
  block-width: 32em,
  line-width: 80em,
  wrap: true,
  ```rust
  pub fn fibonacci_reccursive(n: i32) -> u64 {
      if n < 0 {
          panic!("{} is negative!", n);
      }
      match n {
          0 => panic!("zero is not a right argument to fibonacci_reccursive()!"), 0 => panic!("zero is not a right argument to fibonacci_reccursive()!"),
          1 | 2 => 1,
          3 => 2,
          _ => fibonacci_reccursive(n - 1) + fibonacci_reccursive(n - 2),
      }
  }
  ```,
)
````

#html.elem(
  "div",
  attrs: (style: "display: flex; flex-direction: row; gap: 1em;"),
  (
    html.elem("pre", attrs: (style: "width: 50%; white-space: pre-wrap"), example.text),
    eval(example.text, mode: "markup", scope: (zebraw-html: zebraw-html)),
  ).join(),
)

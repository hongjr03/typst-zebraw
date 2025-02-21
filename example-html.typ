#import "src/lib.typ": zebraw-html

#let _exp(left, right) = {
  block(
    breakable: false,
    html.elem(
      "div",
      (
        left,
        html.elem("div", right, attrs: (style: "padding: 1em; font-size: 0.9em;")),
      ).join(),
      attrs: (class: "exp", style: "margin: 1em 0em;"),
    ),
  )
}
#let exp(code, frame: false) = {
  _exp(
    html.elem("pre", code.text, attrs: (style: "white-space: pre-wrap;")),
    {
      let body = eval(code.text, mode: "markup", scope: (zebraw-html: zebraw-html))
      if frame {
        html.elem("div", html.frame(body), attrs: (class: "frame"))
      } else {
        body
      }
    },
  )
}
#let exp-err(code, msg) = {
  _exp(code, "ERR:\n" + msg)
}
#let exp-warn(code, msg) = {
  _exp(code, eval(code.text, mode: "markup") + "WARN:\n" + msg)
}
#let exp-change(code, before, after) = {
  if is-meta {
    return
  }
  _exp(
    code,
    html.elem(
      "div",
      (
        [曾经],
        [现在],
        before,
        after,
      )
        .map(x => html.elem("div", x))
        .join(),
      attrs: {
        (style: "display: grid; grid-template-columns: 1fr 1fr; gap: 0.5em; ")
      },
    ),
  )
}


#html.elem(
  "script",
  attrs: (src: "https://unpkg.com/@tailwindcss/browser@4"),
)
#html.elem(
  "style",
  // 48rem is from tailwindcss, the medium breakpoint.
  ```css
  @media (width >= 64rem) {
    .exp {
      display: grid;
      grid-template-columns: 50% 50%;
      gap: 0.5em;
    }
  }

  @media (width < 64rem) {
    .exp {
      display: block;
    }
  }

  .frame {
    shadow: 0 0 0.5em rgba(0, 0, 0, 0.1);
    border-radius: 0.5em;
    background: #fff;
    padding: 0.5em;
  }
  ```.text,
)
#html.elem(
  "div",
  attrs: (class: "container xl:max-w-5xl mx-auto p-4"),

  {
    html.elem(
      "h1",
      attrs: (
        class: "text-2xl font-bold underline",
      ),
      [🦓 Zebraw but in HTML world],
    )

    html.elem("h2", [Example], attrs: (class: "text-xl font-bold"))

    exp(````typ
    #zebraw-html(
      highlight-lines: (
        (3, [to avoid negative numbers]),
        (9, "50 => 12586269025"),
      ),
      lang: true,
      block-width: 100%,
      line-width: 100%,
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
    ````)

    exp(````typ
    #zebraw-html(
      highlight-lines: (
        (3, [to avoid negative numbers]),
        (9, "50 => 12586269025"),
      ),
      lang: true,
      block-width: 100%,
      line-width: 100%,
      wrap: true,
      ```rust
      pub fn fibonacci_reccursive(n: i32) -> u64 {
          if n < 0 {
              panic!("{} is negative!", n);
          }
          match n {
              0 => panic!("zero is not a right argument to fibonacci_reccursive()!"),
              1 | 2 => 1,
              3 => 2,
              _ => fibonacci_reccursive(n - 1) + fibonacci_reccursive(n - 2),
          }
      }
      ```,
    )
    ````)
  },
)

#import "src/lib.typ": *

#show raw: set text(font: "Fira Code")
#show: zebraw.with()

= 🦓 Zebraw

Zebraw is a lightweight and fast package for displaying code blocks with line numbers in typst, supporting code line highlighting. The term "*Zebraw*" is a combination of "*zebra*" and "*raw*", for the highlighted lines will be displayed in the code block like a zebra lines.

== Example

To use, import `zebraw` package then follow with ```typ #show zebraw.with() ```.

#grid(columns: 2, column-gutter: 1em)[````typ
  #import "@preview/zebraw:0.2.0": *

  #show: zebraw.with()

  ```typ
  hi
  It's a raw block with line numbers.
  ```
  ````][
  ```typ
  hi
  It's a raw block with line numbers.
  ```
]

The line spacing can be adjusted by passing the `inset` parameter to the `zebraw` function. The default value is `top: 3pt, bottom: 3pt, left: 3pt, right: 3pt`.

#grid(columns: 2, column-gutter: 1em)[````typ
  #show: zebraw.with(
    inset: (top: 6pt, bottom: 6pt)
  )

  ```typ
  hi
  It's a raw block with line numbers.
  ```
  ````][
  #show: zebraw.with(inset: (top: 6pt, bottom: 6pt))
  ```typ
  hi
  It's a raw block with line numbers.
  ```
]

For cases where code line highlighting is needed, you should use ```typ #zebraw()``` function with `highlight-lines` parameter to specify the line numbers that need to be highlighted, as shown below:

#grid(columns: 2, column-gutter: 1em)[````typ
  #zebraw(
    highlight-lines: (1, 3),
    ```typ
    It's me,
    hi!
    I'm the problem it's me.
    ```,
  )
  ````][
  #zebraw(
    highlight-lines: (1, 3),
    ```typ
    It's me,
    hi!
    I'm the problem it's me.
    ```,
  )
]

Customize the highlight color by passing the `highlight-color` parameter to the `zebraw` function:

#grid(columns: (1.2fr, 1fr), column-gutter: 1em)[````typ
  #zebraw(
    highlight-lines: (1,),
    highlight-color: blue.lighten(90%),
    ```typ
    I'm so blue!
                -- George III
    ```,
  )
  ````][
  #zebraw(
    highlight-lines: (1,),
    highlight-color: blue.lighten(90%),
    ```typ
    I'm so blue!
                -- George III
    ```,
  )
]

For more complex highlighting, you can also add comments to the highlighted lines by passing an array of line numbers and comments to the `highlight-lines` parameter:

#grid(columns: 2, column-gutter: 1em)[

  #zebraw(
    highlight-lines: (
      (3, "accept array of line number and comments"),
      (4, [comments can be both #str and #content]),
      (12, "ligature is supported!"),
    ),
    ````typ
    #zebraw(
      highlight-lines: (
        (1, "auto indent!"),
        (2, [Content available as *well*.]),
        3
      ),
      highlight-color: blue.lighten(90%),
      comment-font-args: (
        fill: blue,
        font: "IBM Plex Sans"
      ),
      comment-flag: "~~>",
      ```typ
      I'm so blue!
                  -- George III
      I'm not.
                  -- Alexander Hamilton
      ```,
    )
    ````,
  )][

  #zebraw(
    highlight-lines: (
      (1, "auto indent!"),
      (2, [Content available as *well*.]),
      3,
    ),
    highlight-color: blue.lighten(90%),
    comment-font-args: (fill: blue, font: "IBM Plex Sans"),
    comment-flag: "~~>",
    ```typ
    I'm so blue!
                -- George III
    I'm not.
                -- Alexander Hamilton
    ```,
  )
]

You can also add a header or footer to the code block by passing the `header` / `footer` parameter to the `zebraw` function, as shown below:

#grid(columns: 2, column-gutter: 1em)[#zebraw(
    highlight-lines: (
      (2, [if `lang` is set to `false`, then there will be no language displayed on the end of header]),
    ),
    ````typ
    #zebraw(
      lang: false,
      header: "this is the example of the header",
      ```typ
      I'm so blue!
                  -- George III
      I'm not.
                  -- Alexander Hamilton
      ```,
      footer: "this is the end of the code",
    )
    ````,
  )][
  #zebraw(
    header: "this is the example of the header",
    lang: false,
    ```typ
    I'm so blue!
                -- George III
    I'm not.
                -- Alexander Hamilton
    ```,
    footer: "this is the end of the code",
  )
]

== Real-world Example

Here is an example of using `zebraw` to highlight lines in a Rust code block:

#zebraw(
  highlight-lines: (
    (3, [to avoid negative numbers]),
    (6, [0️⃣ is not a right argument to fibonacci_reccursive()!]),
  ),
  header: "// fibonacci_reccursive()",
  ```rust
  pub fn fibonacci_reccursive(n: i32) -> u64 {
      if n < 0 {
          panic!("{} is negative!", n);
      }
      match n {
          0 => panic!("zero is not a right argument to fibonacci_reccursive()!"),
          1 | 2 => 1,
          3 => 2,
          /*
          50    => 12586269025,
          */
          _ => fibonacci_reccursive(n - 1) + fibonacci_reccursive(n - 2),
      }
  }
  ```,
)

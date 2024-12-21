#import "src/lib.typ": *

#show: zebraw.with()

= typst-zebraw

Zebraw is a lightweight and fast package for displaying code blocks with line numbers in typst, supporting code line highlighting. The term "*Zebraw*" is a combination of "*zebra*" and "*raw*", for the highlighted lines will be displayed in the code block like a zebra lines.

== Example

To show a raw block with line numbers, just import `zebraw` package and then follow with ```typ #show zebraw.with() ```.

#grid(columns: 2, column-gutter: 1em)[````typ
  #import "@preview/zebraw:0.1.0": *

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
    ```
  )
]

Customize the highlight color by passing the `highlight-color` parameter to the `zebraw` function:

#grid(columns: 2, column-gutter: 1em)[````typ
  #zebraw(
    highlight-lines: (1,),
    highlight-color: blue.lighten(90%),
    ```typ
    It's me,
    hi!
    I'm the problem it's me.
    ```,
  )
  ````][
  #zebraw(
    highlight-lines: (1,),
    highlight-color: blue.lighten(90%),
    ```typ
    I'm so blue!
                -- George III
    ```
  )
]
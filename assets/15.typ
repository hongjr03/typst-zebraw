#{
// render_code
context {
set page(width: auto, height: auto, margin: 1em)    
block(
    width: 20em,
        stroke: gray,
        radius: 0.25em,
        inset: 0.5em,
        eval(````typ
#zebraw(
  highlight-lines: 1,
  highlight-color: blue.lighten(90%),
  ```text
  I'm so blue!
              -- George III
  ```,
)
````.text, mode: "markup", scope: (zebraw: zebraw, zebraw-init: zebraw-init, zebraw-themes: zebraw-themes)),
    )}
}
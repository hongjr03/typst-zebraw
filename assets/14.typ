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
  background-color: luma(235),
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```,
)

#zebraw(
  background-color: (luma(235), luma(245), luma(255), luma(245)),
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```,
)
````.text, mode: "markup", scope: (zebraw: zebraw, zebraw-init: zebraw-init, zebraw-themes: zebraw-themes)),
    )}
}
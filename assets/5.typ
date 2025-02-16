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
  highlight-lines: (
    (6, [The Fibonacci sequence is defined through the recurrence relation $F_n = F_(n-1) + F_(n-2)$]),
  ),
  comment-flag: "",
  ```typ
  = Fibonacci sequence
  #let count = 8
  #let nums = range(1, count + 1)
  #let fib(n) = (
    if n <= 2 { 1 }
    else { fib(n - 1) + fib(n - 2) }
  )

  #align(center, table(
    columns: count,
    ..nums.map(n => $F_#n$),
    ..nums.map(n => str(fib(n))),
  ))
  ```
)
````.text, mode: "markup", scope: (zebraw: zebraw, zebraw-init: zebraw-init, zebraw-themes: zebraw-themes)),
    )}
}
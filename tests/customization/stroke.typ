#import "/src/lib.typ": *
#set page(height: auto, width: 300pt)

// Test 1: Default stroke (should be none)
#zebraw(
  lang-color: blue,
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)

#v(1em)

// Test 2: Custom stroke
#zebraw(
  stroke: 2pt+luma(235),
  lang-color: blue,
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)

#v(1em)

// Test 3: Zero radius (sharp corners)
#zebraw(
  radius: 0pt,
  stroke: 2pt+luma(235),
  lang-color: blue,
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)

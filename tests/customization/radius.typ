#import "/src/lib.typ": *
#set page(height: auto, width: 300pt)

// Test 1: Default radius (should be 0.34em)
#zebraw(
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)

#v(1em)

// Test 2: Custom radius with default inset
#zebraw(
  radius: 10pt,
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)

#v(1em)

// Test 3: Large inset with small radius (demonstrates independence)
#zebraw(
  inset: (top: 10pt, bottom: 10pt, left: 20pt, right: 20pt),
  radius: 2pt,
  numbering: false,
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)

#v(1em)

// Test 4: Small inset with large radius (demonstrates independence)
#zebraw(
  inset: (top: 2pt, bottom: 2pt, left: 4pt, right: 4pt),
  radius: 15pt,
  numbering: false,
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)

#v(1em)

// Test 5: Zero radius (sharp corners)
#zebraw(
  radius: 0pt,
  ```typ
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)

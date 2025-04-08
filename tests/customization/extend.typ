#import "/src/lib.typ": *
#set page(height: auto, width: 300pt)

#zebraw(
  extend: false,
  ```typst
  #grid(
    columns: (1fr, 1fr),
    [Hello], [world!],
  )
  ```
)
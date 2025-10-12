#import "/src/lib.typ": *

#set page(width: 20em, height: auto, margin: 1em)
#show: zebraw

// Test 1: Array with specific colors for each line
#zebraw(
  highlight-lines: (
    (1, rgb("#edb4b0").lighten(50%)),
    (2, rgb("#a4c9a6").lighten(50%)),
  ),
  ```python
  - device = "cuda"
  + device = accelerator.device
    model.to(device)
  ```,
)

#v(1em)

// Test 2: Array of colors (cyclic)
#zebraw(
  highlight-lines: (1, 2, 3),
  highlight-color: (rgb("#edb4b0"), rgb("#a4c9a6"), rgb("#94e2d5")).map(c => c.lighten(70%)),
  ```python
    line 1
    line 2
    line 3
  ```,
)

#v(1em)

// Test 3: Mixed - some with specific colors, some with default
#zebraw(
  highlight-lines: (
    ("1": rgb("#ff0000").lighten(80%)), // Red for line 1
    2, // Default color
    (3, rgb("#00ff00").lighten(80%)), // Green for line 3
  ),
  highlight-color: rgb("#0000ff").lighten(80%), // Blue as default
  ```python
    line 1
    line 2
    line 3
  ```,
)

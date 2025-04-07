#import "/src/lib.typ": *
#set page(height: auto, width: 300pt)

#show: zebraw.with(numbering-separator: true)
```typ
#grid(
  columns: (1fr, 1fr),
  [Hello], [world!],
)
```

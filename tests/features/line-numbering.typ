#import "/src/lib.typ": *
#set page(height: auto, width: 300pt)

#show: zebraw.with(numbering-offset: 10)
```typ
#grid(
  columns: (1fr, 1fr),
  [Hello], [world!],
)
```

#show: zebraw.with(numbering: false)
```typ
#grid(
  columns: (1fr, 1fr),
  [Hello], [world!],
)
```

#show: zebraw.with(
  numbering-offset: 10,
  numbering: false,
)
```typ
#grid(
  columns: (1fr, 1fr),
  [Hello], [world!],
)
```

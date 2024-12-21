# typst-zebraw

Zebraw is a **lightweight** and **fast** package for displaying code blocks with line numbers in typst, supporting code line highlighting. The term "_**Zebraw**_" is a combination of "**_zebra_**" and "**_raw_**", for the highlighted lines will be displayed in the code block like a zebra lines.

## Example

To use, import `zebraw` package then follow with `#show zebraw.with()`.

````typ
#import "@preview/zebraw:0.1.0": *

#show: zebraw.with()

```typ
hi
It's a raw block with line numbers.
```
````

![example1](assets/example1.svg)

The line spacing can be adjusted by passing the `inset` parameter to the `zebraw` function. The default value is `top: 3pt, bottom: 3pt, left: 3pt, right: 3pt`.

````typ
#show: zebraw.with(inset: (top: 6pt, bottom: 6pt))

```typ
hi
It's a raw block with line numbers.
```
````

![line-spacing](assets/line-spacing.svg)

For cases where code line highlighting is needed, you should use `#zebraw()` function with `highlight-lines` parameter to specify the line numbers that need to be highlighted, as shown below:

````typ
#zebraw(
  highlight-lines: (1, 3),
  ```typ
  It's me,
  hi!
  I'm the problem it's me.
  ```
)
````

![example2](assets/example2.svg)

Customize the highlight color by passing the `highlight-color` parameter to the `zebraw` function:

````typ
#zebraw(
  highlight-lines: (1,),
  highlight-color: blue.lighten(90%),
  ```typ
  I'm so blue!
              -- George III
  ```
)
````

![example3](assets/example3.svg)

## Performance

Focusing on performance, Zebraw is designed to be lightweight and fast with simple and proper features. It can handle code blocks with ease. The following is a test of a typst file with over 2000 code blocks, each containing 3 lines of code and a test of another typst file with only 30 code blocks.

| Package | 2000 code blocks | 30 code blocks |
| --- | --- | --- |
| Typst Native | 0.62s | 0.10s |
| Zebraw | 0.86s | 0.10s |
| Codly | 4.03s | 0.14s |
| Codelst | 24.31s | 0.11s |

You can see that while in the case of less code blocks, all packages have similar performance. However, when the number of code blocks increases, Zebraw is still able to maintain a good performance, while the performance of Codly and Codelst drops significantly.

## Limitations

- Zebraw does not support features as complex as Codly and Codelst.
- Zebraw does not support the `highlight-range` parameter **yet**.
- ...

## License

Zebraw is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
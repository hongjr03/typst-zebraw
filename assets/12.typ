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
#show: zebraw-init.with(..zebraw-themes.zebra-reverse, lang: false)
#show: zebraw

```rust
pub fn fibonacci_reccursive(n: i32) -> u64 {
    if n < 0 {
        panic!("{} is negative!", n);
    }
    match n {
        0 => panic!("zero is not a right argument to fibonacci_reccursive()!"),
        1 | 2 => 1,
        3 => 2,
        _ => fibonacci_reccursive(n - 1) + fibonacci_reccursive(n - 2),
    }
}
```
````.text, mode: "markup", scope: (zebraw: zebraw, zebraw-init: zebraw-init, zebraw-themes: zebraw-themes)),
    )}
}
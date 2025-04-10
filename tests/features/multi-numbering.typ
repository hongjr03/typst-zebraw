#set page(height: auto, width: 400pt, margin: 20pt)

#import "/src/lib.typ": *

#let rearraged = {
  let input = read("data/diff").split("\n")
  let num(n, hide: false, marker: none) = {
    box(
      width: 2.4em,
      {
        if hide {
          std.hide[#n]
        } else {
          [#n]
        }
        if marker != none {
          marker
        } else {
          std.hide[+]
        }
      },
    )
  }
  let code = ()
  let add-nums = ()
  let del-nums = ()
  let add-num-last = 0
  let del-num-last = 0
  for (x, line) in input.enumerate() {
    let item = if (line.starts-with("@@")) {
      add-nums.push(num(add-num-last, hide: true))
      del-nums.push(num(del-num-last, hide: true))
      code.push(line)
    } else if not (line.starts-with("+++")) and (line.starts-with("+")) {
      add-num-last += 1
      add-nums.push(num(add-num-last))
      del-nums.push(num(del-num-last, hide: true, marker: text(red)[-]))
      code.push(line.slice(1))
    } else if not (line.starts-with("---")) and (line.starts-with("-")) {
      del-num-last += 1
      add-nums.push(num(add-num-last, hide: true))
      del-nums.push(num(del-num-last, marker: text(green)[+]))
      code.push(line.slice(1))
    } else {
      add-num-last += 1
      del-num-last += 1
      add-nums.push(num(add-num-last))
      del-nums.push(num(del-num-last))
      code.push(if line.len() < 1 or x < 5 {
        line
      } else {
        line.slice(1)
      })
    }
  }
  (
    numbering: (
      add-nums,
      del-nums,
    ),
    code: code.join("\n"),
  )
}


#show: zebraw.with(
  numbering: rearraged.numbering,
  indentation: 2,
  hanging-indent: true,
)
#raw(rearraged.code, block: true, lang: "diff")

#set page(height: auto, width: 400pt, margin: 20pt)

#import "/src/lib.typ": *

#let line-nums = {
  let input = read("data/diff").split("\n")
  let add-nums = ()
  let del-nums = ()
  let add-num-last = 0
  let del-num-last = 0
  for line in input {
    let line = line.trim()
    let item = if (line.starts-with("@@")) {
      add-nums.push(hide[#add-num-last])
      del-nums.push(hide[#del-num-last])
      (type: "hunk", line: line)
    } else if (line.starts-with("+")) {
      add-num-last += 1
      add-nums.push(add-num-last)
      del-nums.push(hide[#del-num-last])
      (type: "add", line: line)
    } else if (line.starts-with("-")) {
      del-num-last += 1
      add-nums.push(hide[#add-num-last])
      del-nums.push(del-num-last)
      (type: "del", line: line)
    } else {
      add-num-last += 1
      del-num-last += 1
      add-nums.push(add-num-last)
      del-nums.push(del-num-last)
      (type: "context", line: line)
    }
  }
  (
    add-nums,
    del-nums,
  )
}


#show: zebraw.with(numbering: line-nums, highlight-lines: (3, (4, "test comment")))

#raw(read("data/diff"), block: true, lang: "diff")

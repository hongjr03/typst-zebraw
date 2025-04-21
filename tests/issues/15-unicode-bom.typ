#import "/src/lib.typ": *

#set page(height: auto, width: 300pt)
#show: zebraw.with(indentation: 2)

#let whitespaces = (
  "\u{0009}",
  "\u{000B}",
  "\u{000C}",
  "\u{0020}",
  "\u{00A0}",
  "\u{FEFF}",
)


#for ws in whitespaces {
  let code = raw(ws * 2 + "hi", block: true)
  code
}


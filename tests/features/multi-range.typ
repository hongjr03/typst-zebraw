#import "/src/lib.typ": *

#set page(width: 20cm, height: auto, margin: 1cm)
#show: zebraw-init

= Test Multiple Ranges

== Single Range (Backward Compatibility)

#zebraw(
  line-range: (2, 4),
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  ```
)

== Multiple Ranges

#zebraw(
  line-range: ((1, 3), (5, 7)),
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Multiple Ranges with keep-offset

#zebraw(
  line-range: (
    (range: (1, 3), keep-offset: true),
    (range: (5, 7), keep-offset: true),
  ),
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Multiple Ranges without keep-offset

#zebraw(
  line-range: (
    (range: (1, 3), keep-offset: false),
    (range: (5, 7), keep-offset: false),
  ),
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Three Ranges

#zebraw(
  line-range: ((1, 2), (4, 5), (7, 9)),
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Multiple Ranges with Highlighting

#zebraw(
  line-range: ((1, 3), (5, 7)),
  highlight-lines: (1, 5),
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Multiple Ranges without smart-skip

#zebraw(
  line-range: ((1, 3), (5, 7)),
  smart-skip: false,
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Custom skip-text

#zebraw(
  line-range: ((1, 3), (5, 7)),
  skip-text: "... {} lines ...",
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Custom skip-text (Chinese)

#zebraw(
  line-range: ((1, 3), (5, 7)),
  skip-text: "略过 {} 行",
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Custom skip-text (Content)

#zebraw(
  line-range: ((1, 3), (5, 7)),
  skip-text: strong(emph[Skipped some lines here]),
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

== Complex Example with Comments

#zebraw(
  line-range: ((1, 3), (5, 7)),
  highlight-lines: (
    (1, [Function definition]),
    (5, [Print result]),
  ),
  ```python
  def fibonacci(n):
      if n <= 1:
          return n
      return fibonacci(n-1) + fibonacci(n-2)
  
  print(fibonacci(10))
  result = fibonacci(20)
  print(f"Result: {result}")
  ```
)

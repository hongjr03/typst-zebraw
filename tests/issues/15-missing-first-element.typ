#import "/src/lib.typ": *

#set page(height: auto, width: 300pt)
#show: zebraw.with(indentation: 2)

```typ
class Test {
  public:
    Test(int const id);
    void Print() const;
  private:
    int mId;
};
```
\

```cpp
class Test {
  public:
    Test(int const id);
    void Print() const;
  private:
    int mId;
};
```

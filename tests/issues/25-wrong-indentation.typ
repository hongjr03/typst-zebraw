#import "/src/lib.typ": *

#set page(height: auto, width: 300pt)
#show: zebraw.with(indentation: 2, hanging-indent: true)

```c
#include <stddef.h>

/*@
  requires \valid_read(arr + (0 .. len-1));
  requires Sorted:
    \forall integer i, j; 0 <= i <= j < len ==> arr[i] <= arr[j];
  requires len >= 0;

  behavior found:
    assumes \exists integer j; 0 <= j < len && arr[j] == value;
    ensures arr[\result] == value;

  behavior not_found:
    assumes \forall integer j; 0 <= j < len ==> arr[j] != value;
    ensures \result == -1;

  assigns \nothing;
*/
int bsearch(int *arr, int len, int value) {
  if (len == 0)
    return -1;

  int low = 0;
  int up = len - 1;

  /*@
    loop invariant 0 <= low && up < len;
    loop invariant
      \forall integer i; 0 <= i < len && arr[i] == value ==> low <= i <= up;
    loop assigns low, up;
    loop variant up - low;
  */
  while (low <= up) {
    int mid = low + (up - low) / 2;
    if (arr[mid] > value)
      up = mid - 1;
    else if (arr[mid] < value)
      low = mid + 1;
    else
      return mid;
  }
  return -1;
}
```

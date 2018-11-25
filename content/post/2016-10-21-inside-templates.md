---
title: Unpacking C++ Templates
date: '2016-10-21'
---

For those of you that know me, I have a bit of an interest in programming languages and language internals.
This blog post is meant to be the first in a series that walks through some fundamentals of common languages.
Today's post is about C++ templates and their semantics, and then in future posts I'll be discussing how
templates differ from the idea of generics in other languages like Java.

## Templates 101

It's a very common problem in writing software where you want to take a set of functions or classes and
generalize them to work for any input data type.

For example, let's say that we want to calculate the sum of the items in a vector. We don't care ahead of
time what's inside the vector, we just want to write the general __algorithm__ for the sum, and then apply it
to any vector.

In a language like Python, this is fairly trivial:

```python
def mysum(lst):
    accum = 0
    for val in lst:
      accum += val
```

Thanks to Python's support for duck-typing, we don't need to care about the type of data inside of `vec`, all
that matters is that we can add two such items together.

How would this code look in a language like C++? Pretty similar, with different syntax. We need to make use
of C++'s ___templates___ feature.

```c++
template<typename T>
T mysum(T[] items, size_t numItems) {
    T accum = 0;
    for (size_t i = 0; i < numItems; i++) {
        accum += items[i];
    }
    return accum;
}
```

## The First Law of Templates: Lazy Generation

These two blocks of code look similar enough if you squint at them, but there's something very different
going on under the hood: in C++, this code doesn't exist.


<blockquote>
  Doesn't exist?
</blockquote>

Yep, it turns out that template code is really just __phantom code__, and doesn't generate any assembly on
its own.

To see an example of this, let's see the assembly that gets generated for the following file:

```shell
$ cat <<EOF > test.cc
template<typename T>
T identity(T t) {
    return t;
}

int main() {
  return 0;
}
EOF
$ g++ -S test.cc
$ cat test.S

_main:                                  ## @main
  .cfi_startproc
  ... code for main() function...
  .cfi_endproc
```



## Concrete Class Generation

Let's see what happens when we adjust our example from before to include a call to the `identity` function:

```c++
template<typename T>
T identity(T t) {
    return t;
}

int main() {
  return identity(10); // should return 10
}
```

Now, let's look at the generated assembly:

```asm
_main:                                  ## @main
  .cfi_startproc
  ... stack setup, function argument setup ...
  callq __Z8identityIiET_S0_
  ... stack cleanup ...
  .cfi_endproc

  ...

__Z8identityIiET_S0_:                   ## @_Z8identityIiET_S0_
  .cfi_startproc
  ... implementation of identity that takes an int and returns an int ...
  .cfi_endproc
```

Note the name of the second function: `__Z8identityIiET_S0_`. The important part of that string of garbage
characters is `Ii`, with the second `i` denoting that the function returns an int. If we add another call,
and look at the generated assembly:

```c++
template<typename T>
T identity(T t) {
    return t;
}

int main() {
  double d = identity(10.0);
  return identity(10); // should return 10
}
```

```assembly
_main:                                  ## @main
  .cfi_startproc
  ... main includes calls to both identity functions ...
  .cfi_endproc

  .globl  __Z8identityIdET_S0_
__Z8identityIdET_S0_:                   ## @_Z8identityIdET_S0_
  .cfi_startproc
  ... implementation of double identity(double); ...
  .cfi_endproc

  .globl  __Z8identityIiET_S0_
__Z8identityIiET_S0_:                   ## @_Z8identityIiET_S0_
  .cfi_startproc
  ... implementation of int identity(int); ...
  .cfi_endproc
```

## Next Time

So this time we walked through a few example of generation of templates in C++, and the way they're lazily
generated. In the next post in the series, we'll talk about generics in languages like Java and Scala, and
eventually move on to structural subtyping like what we see in the [go](https://golang.org) world.


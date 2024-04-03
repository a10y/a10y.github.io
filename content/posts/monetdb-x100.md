+++
title = 'Paper Review: MonetDB/X100 - Hyper-Pipelining Query Execution'
date = 2024-04-02T15:32:48-05:00
+++

## Link

https://15721.courses.cs.cmu.edu/spring2024/papers/04-execution1/boncz-cidr2005.pdf

## Notes

This is a 2005 paper from the [CMU Advanced Database Systems](https://15721.courses.cs.cmu.edu/spring2024/schedule.html) syllabus. The authors are from CWI (same research lab behind DuckDB).

The purpose of the paper is to demonstrate how DBMS of the time were poorly suited for modern super-scalar CPUs, and gives an overview of the design and implementation of new execution engine for MonetDB that has better mechanical sympathy.

What are super-scalar CPUs?

- They are the processor we’re most familiar with today (Intel, ARM)
- Designed with multiple **pipelines**, which are able to reorder the order of code execution
- Having more pipelines can be better than having a faster clock speed in many cases
- Data dependencies (e.g. a load following a store) create **pipeline breaks** which force execution to stall, adding clock cycles

Why were contemporary DBs poorly designed for super-scalar CPUs?

- They weren’t built with pipeline awareness. This led to some bad outcomes
    - Filters were implemented with branching, which cause pipeline breaks
- Tuple-at-a-time processing forces you to do LD, OP, STR in sequence. This creates a pipeline blocker for every single tuple
- Column-at-a-time has the opposite problem: it leads to wasteful materialization, because you end up materializing a lot of data that doesn’t need to make it to the final result set → **Memory Bandwidth constraint**!

The authors built X100 to incorporate ideas to make MonetDB work on modern hardware:

- Vectorized processing engine. Each operator receives and populates a batch of rows, which they call a vector
- Gives developers ability to define custom operators, and build fused operators which inline a sequence of operations into a single vectorized operation
- Minimizes branching and allows the CPU to run operators without jumps wherever possible

How do you get around the wasteful materialization problem?

- Every vector emitted by a node will have a **selection vector** attached to it. This is a set/bitmap that indicates which of the fields from the tuple should be ignored
    - Why do this instead of having dynamically-sized tuples?
    - Because we want to pre-allocate memory and let the CPU do straight-line execution.
    - Mapping operators that transform data element `i` will write a result to output element `i`
    - Aggregations/final materialization ignores elements that are not in the selection vector/bitmap

How does it do?

- They compare against DB2, and the original version of MonetDB with the old execution engine
- X100 did ~100x better than the old MonetDB engine for most queries at small scales, and 5-100x better than DB2 at high scale

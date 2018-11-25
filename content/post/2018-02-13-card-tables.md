---
title: JVM Garbage collection; or WTF is a Card Table?
date: 2018-02-13
---

I find the JVM a really fascinating piece of technology (not least of all because I spend a lot of time working
with/against it). The folks from Sun and subsequently Oracle Labs are a really brilliant bunch, and taking a
peek under the hood can be equal parts awe-inspiring and cringy.

Today I wanted to highlight a heuristic that the HotSpot JVM uses for its various garbage collectors to reduce the
amount of space it searches when performing a new-generation GC.

As a refresh: the JVM segregates the heap into multiple generations, the most notable being the YoungGen (or NewGen) and
the OldGen. Objects in the YoungGen are expected to die young and thus be frequently available for collection, while the
objects in OldGen are likely to stay in OldGen (rich get richer and poor get poorer is a decent analogy here).

When performing a GC for the YoungGen, the collector needs to find all "live" objects, and copy them somewhere,
reclaiming the leftover space. Live objects are defined as follows:

  1. All objects in the "root set", consisting of objects referenced by stack references, or held by a static
     reference
  1. All objects referenced in the field of another live object

You can then construct the reachable set inductively, starting at the root set and iterating #2 until we've exhausted
the tree of object references. For a minor GC, which only collects YoungGen, references to objects in OldGen are ignored
for the purposes of creating this live tree, as in the minor GC we find all live YoungGen objects, copy/compact into a
new space, and reclaim the rest as free space.

Ignoring Oldgen is risky though, because references to YoungGen objects can be held in OldGen! Think of a gigantic
`ConcurrentHashMap` that you keep for the lifetime of your application, and you've just added a new entry to it. The map
itself is in OldGen, and holds a reference to the newly added value that sits in YoungGen. To handle this, we need to
perform _tracing_ on assignments to reference fields in our objects. The question is how to do this tracing efficiently
in such a way that it narrows our search space at collection time.

### Enter the Card Table

HotSpot maintains a **card table**, a structure that efficiently serves as a bitset for "dirty" memory pages. More
concretely, say I have the following snippet of code:

```java
// Somewhere inside some method...
this.myMap = new HashMap<String, String>();
// ...
```

The JVM injects what is effectively the following code at runtime around the assignment:

```
        CARD_TABLE[&this >> 9] = 1
```

Here, the mark bit for the address where the object resides is being set, meaning that there has been an assignment to
a field in the card that holds this object, where a "card" here is a 2^9 = 512 byte region of the heap. We can now use
the card table to form a heuristic over which objects in the OldGen need to be searched. Clearly, only objects in OldGen
that exist in a card where their mark bit is set in the card table are eligible to hold new references to YoungGen
objects. Thus, we augment our minor GC algorithm from before like so:

  1. Start with root set as the set of all reachable objects
  1. Transitively, find all objects in YoungGen reachable from the root set
  1. Scan the card table, and for all cards in OldGen where the mark bit is set, scan objects in those cards for
     pointers to YoungGen
  1. Clear the mark bits
  1. After objects get relocated, update the pointers in OldGen, remarking cards in the card table if they actually
     point to YoungGen objects

### Links

A lot of this knowledge was gleaned from the following places, please go read these links to get more depth!

* ["Understanding GC pauses in JVM, HotSpot's minor GC"](http://blog.ragozin.info/2011/06/understanding-gc-pauses-in-jvm-hotspots.html).
  Card table stuff towards the beginning of the _Write Barrier_ section.
* ["Garbage collection in the HotSpot JVM"](https://www.ibm.com/developerworks/library/j-jtp11253/)
* ["The JVM Write Barrier - Card Marking"](http://psy-lob-saw.blogspot.co.uk/2014/10/the-jvm-write-barrier-card-marking.html)
* ["False sharing induced by card table marking"](https://blogs.oracle.com/dave/false-sharing-induced-by-card-table-marking)
* ["Memory Management Reference"](http://www.memorymanagement.org/glossary/c.html#glossary-c), "C" section of the
glossary. Checkout the definitions for **card** and **card marking**. Also this entire guide just looks pretty nice.

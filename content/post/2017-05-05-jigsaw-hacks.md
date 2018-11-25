---
title: A Collection of JDK Hacks That Are Broken In Jigsaw
date: '2017-05-05'
---



**The Hack**:
Injecting new classes into packages you don't actually own.

**Why We Do It**:
Accessing package protected methods and classes.

**Post-Jigsaw Solution**:
Fix the damn issue in the upstream code. If it's a very slow-moving project then fork it and publish the artifacts to [Jitpack](https://jitpack.io) or your
favorite corporate Maven repo. If it's a fast-moving project that has monthly releases then just send a patch to the owner and see if they accept it. Odds
are if what you're doing is not too disgusting, other people will want to have the same functionality, so they'll be willing to take your change.

**The Hack**:
Using private APIs via runtime reflection capabilities, e.g. `Class.forName("com.foo.internal.SuperTopSecret")`. When a package declares a module,
even with reflection you can't access any type in a package that isn't `exports`ed.

**Why We Do It**:
Sometimes it becomes necessary to edit objects that are private to modify the internal functionining. Usuaully this is done to modify a field
or call a method on a private singleton. At my last job we did this with Apache Spark's catalog class to implement custom catalogs on top of
the internal catalog.

**Post-Jigsaw Solution**:
There's really not much you can do here. Again, either fork/vendor the dependency or convince the owner to make the package public.

---
title: Make Your Own Tools
date: '2017-03-08'
---

> _Give me lever long enough and a fulcrum sturdy enough and I will move the world._
>
> &mdash; Archimedes on mechanical advantage

Tools give you leverage, the upfront investment saves you time later on.
Whenever you have a large project, make sure you either find **_OR MAKE_** the right
tools for the job.

Even this site is developed using a hand-rolled Makefile. I used to have to run
some tedious commands to perform a watch, deploy and rebuild parts of my site.
Instead, I took the time to setup Git
[post-receive](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) hooks
to deploy my site just by pushing, Heroku-style. If I wanna be able to edit my
Markdown and have the site rebuild on save, I just run `make watch` in a
separate iTerm2 tab, and write away. Tools have pervaded almost all parts of my life.

Being a student, this of course applies to my academic life as well.  In every
class I take, I always spend ~15-20 minutes writing a script that that can run
my tests, diff my answers against some test cases (either provided ones or ones
that I write myself). This becomes more important as the project grows larger
and the room for error expands rapidly (especially for group projects). I don’t
go as far as setting up CI because for two people, waiting for Circle to finish
building and running tests is much slower than sitting next to someone and
watching them run the tests, but I still make sure that I integrate testing
early on and communicate (either through a README or in person) how my
partner(s) should run the tests, and add new tests.

The best thing about this is that you can measure your progress trivially: if
the tests fail, you have work left to do. If they all pass, then you’re
(probably) done.  Building good tools for testing my own software has been key
for me in all the classes where I’ve done well, as well as in my internships.
The skill of being able to write simple bash/python/whatever scripts that are
capable of performing menial tasks frees your mind up so you can get to work,
and validation is as simple as "did it pass/fail".

Clear your mind, write good tools.

---
title: A new way to deploy Hakyll to Github Pages
date: '2017-04-18'
---

I like Hakyll. It's cool, it works well, and I should probably be doing more
functional programming, so my static blog engine is a good place to start.  I
used to have my Hakyll blog hosted on a directory on a private DigitalOcean
server, but the IRS took me to school this tax season (in retrospect, doing an
internship in the UK that started the same week as the Brexit referendum was
not the most fiscally responsible choice), so I started cancelling unnecessary
services I'd been paying for, and my hosting provider was one of them.

I decided to move over to Github Pages publishing for my site, since it checks
all my important boxes&mdash;it's free and you can enforce HTTPS. Github Pages
is also served out of a bunch of globally distributed CDNs, so expected latency
should be lower than everyone going directly to my US-West region VPS. (**Note**:
back when I hosted the blog myself, most of the readers were either bots
looking for unsecured mysqladmin instances or other php vulns, almost all of
them from China or Estonia: 欢迎朋友 and Tere sõbrad).

It turns out that the GH Pages deployment story for Hakyll blogs is pure
fantasy: even Jasper himself recommends a funky technique that requires
`rsync`'ing your built items into the current directory, fiddling with
`.gitignore`s across branches. It's all very confusing, and I've never had any
luck getting it to work.  After a long time being frustrated with this setup, I
took a few minutes today and figured out one that works out better, at least
for me.

The trick is that Hakyll generates a `_site/` directory that includes all the
posts and pages it generates. If you setup an ephemeral hidden folder
`.deploy/` in the root of your project, that you ignore with your `.gitignore`,
then you can copy all of the `_site/` files into `.deploy/`, and force-push to
master from `.deploy`. This directory can then be deleted if the push succeeds.

If you're interested, take a look at my [deploy
script](https://github.com/a10y/a10y.github.io/blob/develop/scripts/deploy.sh)
and
[.gitignore](https://github.com/a10y/a10y.github.io/blob/develop/.gitignore) to
see how this works.

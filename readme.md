# Blog

I recently switched over to using Hugo for static site management, from Hakyll.

I liked Hakyll back in college, when the focus was on the tech and less on content. I want to challenge myself to write better content,
so I'm looking for something more batteries-included.

## Build instructions

```
./setup-hooks.sh    # Setup git hooks to deploy the blog when develop is pushed
make serve          # Start the hugo dev server for local publishing
make deploy         # One-off deploy
```
#!/usr/bin/env bash

PRE_PUSH_HOOK='.git/hooks/pre-push'

cat<<EOF >${PRE_PUSH_HOOK}
# Re-deploy blog when pushing changes
make deploy
git add public/
git status -s | grep -E '^A'
if [[ $? -eq 0 ]]; then
    git commit -m 'Point public/ to latest deployed hash'
fi
EOF
chmod +x ${PRE_PUSH_HOOK}

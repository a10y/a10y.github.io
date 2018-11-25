#!/usr/bin/env bash

PRE_COMMIT_HOOK='.git/hooks/pre-commit'

if [[ ! -f ${PRE_COMMIT_HOOK} ]]; then
    cat<<EOF >${PRE_COMMIT_HOOK}
# Re-deploy blog on change
make deploy
EOF
    chmod +x ${PRE_COMMIT_HOOK}
fi

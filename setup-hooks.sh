#!/usr/bin/env bash

PRE_PUSH_HOOK='.git/hooks/pre-push'

cat<<EOF >${PRE_PUSH_HOOK}
# Re-deploy blog when pushing changes
make deploy
EOF
chmod +x ${PRE_PUSH_HOOK}

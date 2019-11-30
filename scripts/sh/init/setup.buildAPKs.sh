#!/bin/env sh 
# Copyright 2019 (c) all rights reserved 
# by BuildAPKs https://buildapks.github.io/buildAPKs/
# Invocation: ~/buildAPKs/scripts/sh/init/setup.BuildAPKs.sh 
#####################################################################
set -e
STRING1="Command \`au\` enables rollback; Available at https://wae.github.io/au/: Continuing..."
STRING2="Cannot update ~/buildAPKs prerequisites: Continuing..."
STRING3="Cannot clone ~/buildAPKs: Continuing..."
printf "%s\\n" "Beginning buildAPKs setup:"
[ ! -z "$(command -v "au")" ] && (au aapt apksigner curl dx ecj git) || (printf "%s\\n" "$STRING1") || [ ! -z "$(command -v apt)" ] && (pkg install aapt apksigner curl dx ecj git) || (printf "%s\\n" "$STRING2") 
cd "$HOME"
git clone https://github.com/BuildAPKs/buildAPKs || printf "%s\\n\\n" "$STRING3"
bash "$HOME"/buildAPKs/scripts/bash/build/build.entertainment.bash "$@"
# setup.BuildAPKs.sh EOF

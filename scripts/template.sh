#!/bin/bash

template="$(cat $1)"
template=$(sed 's/\([^\\]\)"/\1\\"/g; s/^"/\\"/g' <<< "$template")
eval "echo \"${template}\"" > $2

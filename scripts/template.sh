#!/bin/bash

template=$1
output=$2

template="$(cat $template)"
template=$(sed 's/\([^\\]\)"/\1\\"/g; s/^"/\\"/g' <<< "$template")
eval "echo \"${template}\"" > $output

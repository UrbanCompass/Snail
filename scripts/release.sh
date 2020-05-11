#!/bin/sh

publish=$1
spec="Snail.podspec"
template="$spec.template"

#replace spec tag
export SnailVersion=`git describe --tags --abbrev=0`
./scripts/template.sh Snail.podspec.template $spec

echo "Updating spec.. ✅"
cat $spec

if [ "$publish" == "publish" ]; then
    pod trunk push $spec
else
    pod lib lint --verbose --allow-warnings
fi

#!/bin/sh

publish=$1
spec="Snail.podspec"

#replace spec tag
replacement=`git describe --tags --abbrev=0`
sed -i '' "s/  s.version.*/  s.version      = \"$replacement\"/" $spec

echo "Updating spec.. ✅"
cat $spec

if [ "$publish" == "publish" ]; then
    pod trunk push $spec
fi

#!/usr/bin/env bash
set -Eeuo pipefail

repo="bowtie/ruby"

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
  versions=( */ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
  [ -d "$version" ] || continue

  dockerfile="$version/Dockerfile"
  tag="$version"

  if [ -f $dockerfile ]; then
    full_version=$(cat $dockerfile | grep "ENV RUBY_VERSION" | sed -E 's/ENV RUBY_VERSION //g')

    echo "Build $repo:$tag (from $dockerfile)"
    echo " Also $repo:$full_version"
    # docker build -f $dockerfile -t $repo:$tag .
    # docker push $repo:$tag

  else
    echo "CANNOT Build $repo:$tag (MISSING: $dockerfile)"
  fi
done

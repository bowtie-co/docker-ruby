#!/usr/bin/env bash
set -Eeuo pipefail

repo="bowtie/ruby"

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
  versions=( */ )
fi
versions=( "${versions[@]%/}" )

latest=""

for version in "${versions[@]}"; do
  [ -d "$version" ] || continue

  dockerfile="$version/Dockerfile"
  tag="$version"

  if [ -f $dockerfile ]; then
    full_version=$(cat $dockerfile | grep "ENV RUBY_VERSION" | sed -E 's/ENV RUBY_VERSION //g')

    echo "Build $repo:$tag ($dockerfile)"
    docker build -f $dockerfile -t $repo:$tag .

    echo "  Tag $repo:$tag => $repo:$full_version"
    docker tag $repo:$tag $repo:$full_version

    # docker push $repo:$tag
    # docker push $repo:$full_version

    latest=$version
  else
    echo "CANNOT Build $repo:$tag (MISSING: $dockerfile)"
  fi
done

if [ "$latest" != "" ]; then
  echo "  Tag $repo:$latest => $repo:latest"

  # docker tag $repo:$latest repo:latest
  # docker push $repo:latest
fi

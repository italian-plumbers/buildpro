#!/usr/bin/env bash
cd "$( dirname "$0" )"
gtag=`git describe --tags`
if [ -n "$(git status --porcelain --untracked=no)" ] || [[ ${gtag} == *"-g"* ]]; then
  gtag=latest
fi
# build ghcr.io images
prefix="ghcr.io/italian-plumbers/buildpro/"
for img in ubuntu rocky-pro rocky-mdv rocky-ci rocky-pin rocky-pdv
do
  pkg=${prefix}${img}:${gtag}
  time docker image build \
    --network=host \
    --build-arg BPROTAG=${gtag} \
    --file ${img}.dockerfile \
    --tag ${prefix}${img}:latest \
    --tag ${pkg} .
  docker push ${prefix}${img}:${gtag}
done

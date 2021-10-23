#!/bin/sh -e
docker build . -t karloie/yaasp
docker rm --force yaasp || true
docker run \
  --rm \
  --init \
  --name yaasp \
  --read-only \
  --tmpfs /run \
  --tmpfs /tmp \
  -p 2222:2222 \
  -v $(pwd)/config:/config:ro \
  -ti karloie/yaasp $1

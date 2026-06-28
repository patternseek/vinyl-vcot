# Vinyl Cache engine, straight from the apk package (not compiled).
#
#   ALPINE_TAG      Alpine branch the engine apk comes from. edge ships varnish 9.0.x;
#                   stable 3.22 ships 7.7.x. edge drifts -- pin to a stable once one
#                   ships 9.x.
#   VARNISH_VERSION apk version pin for the engine (package still named `varnish` -- it
#                   is the Vinyl project, pre-rename). Pinned exact so engine changes are
#                   deliberate: an edge varnish bump then fails the build until this is
#                   updated on purpose. Exact apk pins need the `-rN` revision
#                   (`9.0.3-r0`, not `9.0.3`); `~9.0` floats the 9.0.x minor instead.
#                   NOTE: edge carries only the current version, so a pinned build stops
#                   resolving once edge bumps -- update the pin deliberately when it does.
#                   Current edge version (to copy when bumping):
#                   https://pkgs.alpinelinux.org/packages?name=varnish&branch=edge&arch=x86_64
ARG ALPINE_TAG=edge

FROM alpine:${ALPINE_TAG}
ARG VARNISH_VERSION=9.0.3-r0
# tzdata for local-time log timestamps; varnish is the cache engine.
RUN apk add --no-cache tzdata "varnish${VARNISH_VERSION:+=$VARNISH_VERSION}"

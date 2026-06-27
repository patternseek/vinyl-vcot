# Vinyl Cache engine, straight from the apk package (not compiled).
#
#   ALPINE_TAG      Alpine branch the engine apk comes from. edge ships varnish 9.0.x;
#                   stable 3.22 ships 7.7.x. edge drifts -- pin to a stable once one
#                   ships 9.x.
#   VARNISH_VERSION optional apk version pin for the engine. The package is still named
#                   `varnish` (it is the Vinyl project, not yet renamed after the split).
#                   Empty = whatever ALPINE_TAG currently ships. Set an apk constraint to
#                   pin, e.g. `9.0.0-r0` (exact) or `~9.0` (latest 9.0.x). The version
#                   must exist in ALPINE_TAG's repo (edge only carries the current one).
ARG ALPINE_TAG=edge

FROM alpine:${ALPINE_TAG}
ARG VARNISH_VERSION=~9.0
# tzdata for local-time log timestamps; varnish is the cache engine.
RUN apk add --no-cache tzdata "varnish${VARNISH_VERSION:+=$VARNISH_VERSION}"

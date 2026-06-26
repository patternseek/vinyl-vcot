#   ALPINE_TAG     edge selects varnish 9.0.x (stable 3.22 is 7.7.x). edge drifts, pin once a stable ships 9.x.
#   BLOBDIGEST_REF 8.0 uses varnishapi (matches Alpine); master needs the renamed vinylapi (source build only).
#   VCOT_REF       35001c9f, not main: main's go.mod pins varnishapi v1.0.2, a tag upstream deleted (unfetchable); this commit pins the fetchable v1.0.0.
ARG ALPINE_TAG=edge
ARG BLOBDIGEST_REF=8.0
ARG VCOT_REF=35001c9f

FROM alpine:${ALPINE_TAG} AS build
ARG BLOBDIGEST_REF
ARG VCOT_REF

# Go + vmod build toolchain + varnish-dev (varnishapi, vmodtool, build macros),
# py3-docutils for the vmod man page.
RUN apk add --no-cache \
        go build-base automake autoconf libtool pkgconf git \
        varnish-dev py3-docutils

# Alpine's varnish-dev advertises vmodtool at /usr/share/varnish/vmodtool.py (via
# varnishapi.pc) but omits the file, so vmod builds fail without it. We vendor the
# matching engine's vmodtool.py here. re-vendor if the engine major bumps.
COPY vmodtool.py /usr/share/varnish/vmodtool.py

# libvmod-blobdigest, required by otel.inc.vcl, not in any distro. make install
# DESTDIR=/out stages the .so under the vmod dir, copied into runtime below.
WORKDIR /src
RUN git clone https://gitlab.com/uplex/varnish/libvmod-blobdigest.git \
    && cd libvmod-blobdigest \
    && git checkout "${BLOBDIGEST_REF}" \
    && { [ -f bootstrap ] && sh bootstrap || sh autogen.sh; } \
    && ./configure \
    && make -j"$(nproc)" \
    && make install DESTDIR=/out

# vcot daemon, built against the same engine API. VSM_NOPID lets it attach to the
# VSM across container boundaries without the pid match.
# + Patch: vcot only maps the Start/Resp/BerespBody Timestamp events and returns an
# error (logged per-record) for every other one (Req, Process, Fetch, Bereq, ...),
# which floods the log under traffic. We make those unhandled labels a no-op. The
# grep guard fails the build if the line moves on a VCOT_REF bump (re-check then).
ENV VSM_NOPID=1
RUN git clone https://gitlab.com/uplex/varnish/VinylCacheOpenTelemetry.git vcot \
    && cd vcot \
    && git checkout "${VCOT_REF}" \
    && grep -q 'Failed to parse Timestamp payload' internal/vsl/vsl.go \
    && sed -i 's#return errors.New("Failed to parse Timestamp payload")#return nil#' internal/vsl/vsl.go \
    && CGO_ENABLED=1 GOOS=linux go build -o /out/usr/local/bin/vcot ./cmd/vcot.go

# the cache engine from the package + our two artifacts
FROM alpine:${ALPINE_TAG} AS runtime
RUN apk add --no-cache varnish tzdata
ENV VSM_NOPID=1
# blobdigest .so into the vmod dir, plus the vcot binary.
COPY --from=build /out/ /
# otel.inc.vcl baked alongside the engine config, version-locked to this vcot, so
# consumers can `include "otel.inc.vcl"` without shipping it.
COPY otel.inc.vcl /etc/varnish/otel.inc.vcl

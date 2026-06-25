# vinyl-vcot

Prebuilt container image bundling the OSS Vinyl/Varnish Cache engine,
libvmod-blobdigest, and the VCOT (VinylCacheOpenTelemetry) tracing daemon.

- Engine from the `varnish` apk package (not compiled).
- libvmod-blobdigest — required by `otel.inc.vcl`; not packaged by any distro,
  so compiled here against the apk `varnish-dev`.
- vcot — built against the same engine API. 
- `/etc/varnish/otel.inc.vcl` — the VCOT VCL include, baked in and
  version-locked to the vcot binary. Consumers `include "otel.inc.vcl"` from their
  own VCL; they do not ship it.

`vmodtool.py` and `otel.inc.vcl` are vendored in this repo
## License

This project is **GPL-3.0-or-later** (see `LICENSE`), consistent with the bundled
VCOT components. 

- `otel.inc.vcl` — vendored from VinylCacheOpenTelemetry (VCOT), GPL-3.0-or-later.
- `vmodtool.py` — vendored from Varnish/Vinyl Cache, BSD-2-Clause (retains its own
  header).
- The built image also bundles, from their own upstreams: the Vinyl/Varnish engine
  and its vmods (BSD-2-Clause), libvmod-blobdigest (BSD-2-Clause, with MIT portions
  from librhash), and the compiled `vcot` daemon (GPL-3.0-or-later).

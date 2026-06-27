# vinyl-cache

Minimal container image for the OSS Vinyl/Varnish Cache engine.

- Engine from the `varnish` apk package (still named `varnish`; it is the Vinyl
  project, not yet renamed after the split). Not compiled.
- `ALPINE_TAG` selects the branch the package comes from; `VARNISH_VERSION`
  optionally pins the engine version within it (see the `Dockerfile` header).

## License

This repo (Dockerfile, CI, test VCL) is BSD-2-Clause — see `LICENSE`. The built
image also bundles the Vinyl/Varnish engine and its vmods, themselves BSD-2-Clause
under their own upstream terms.

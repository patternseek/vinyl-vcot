# Vendored verbatim from VinylCacheOpenTelemetry at the pinned VCOT_REF, version locked
# to the vcot binary. Do not edit. Re-vendor when bumping VCOT_REF.
vcl 4.1;

import std;
import blobdigest;
import blob;

sub vcl_init {
    # initialize with fixed prefix server.identity - we ware not afraid of
    # prefix attacks for this use case. MD5 because it has enough bytes and its
    # weaknesses do not apply
    new otel_trace = blobdigest.digest(MD5,
        blob.decode(encoded=server.identity), TASK);
    new otel_span = blobdigest.digest(MD5,
        blob.decode(encoded=server.identity), TASK);
}

sub otel_trace_gen {
    otel_trace.update(blob.decode(encoded=std.random(1, 4294967295)));
    otel_trace.update(blob.decode(encoded=now));
}

sub otel_span_gen {
    otel_span.update(blob.decode(encoded=std.random(1, 4294967295)));
    otel_span.update(blob.decode(encoded=now));
}

sub otel_recv {
    # Validate existing traceparent (RFC 9416 format)
    if (req.http.traceparent &&
	(req.http.traceparent !~ "^([0-9a-f]{2})-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})$" ||
	 req.http.traceparent ~ "-0{16}-|-0{32}-")) {
        std.log("Invalid traceparent format: " + req.http.traceparent);
        unset req.http.traceparent;
    }

    if (!req.http.traceparent) {
        # Generate new trace ID (128-bit) and span ID (64-bit)
        call otel_trace_gen;
        call otel_span_gen;

        set req.http.traceparent =
            {"00-"} + blob.encode(HEX, blob = blob.sub(otel_trace.final(), 16B)) +
            {"-"} + blob.encode(HEX, blob = blob.sub(otel_span.final(), 8B)) +
            {"-01"};
    }
    else {
        # Inherit parent span (keep trace ID, generate new span ID)
        call otel_span_gen;
        set req.http.traceparent = regsub(req.http.traceparent,
            "(?<=-)[0-9a-f]{16}(?=-)",
            blob.encode(HEX, blob = blob.sub(otel_span.final(), 8B)));
    }
}

# Propagate to backend responses
sub otel_deliver {
    set resp.http.traceparent = req.http.traceparent;
    if (!resp.http.tracestate && req.http.tracestate) {
        set resp.http.tracestate = req.http.tracestate;
    }
}

vcl 4.1;

import directors;
include "otel.inc.vcl";

backend app1 { .host = "127.0.0.1"; .port = "8080"; }

sub vcl_init {
    new vd = directors.round_robin();
    vd.add_backend(app1);
}

sub vcl_recv {
    set req.backend_hint = vd.backend();
    call otel_recv;
}

sub vcl_deliver {
    call otel_deliver;
}

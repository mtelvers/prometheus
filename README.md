## OCaml client library for Prometheus monitoring

To run services reliably, it is useful if they can report various metrics
(for example, heap size, queue lengths, number of warnings logged, etc).

A monitoring service can be configured to collect this data regularly.
The data can be graphed to help understand the performance of the service over time,
or to help debug problems quickly.
It can also be used to send alerts if a service is down or behaving poorly.

This repository contains code to report metrics to a [Prometheus][] monitoring server.

### Packages

The library is split so that defining and recording metrics never pulls in a
concurrency library; an application picks a backend only when it comes to
serving them. `prometheus-lwt` provides the Lwt backend today; further
backends (e.g. Eio, Miou) can be added without changing the core.

| Package | Adds | Use it for |
|---|---|---|
| `prometheus` | — (`re`) | Defining and recording metrics. Libraries depend only on this. |
| `prometheus-app` | `fmt` | Rendering a snapshot to the text format, plus standard GC collectors. No HTTP, no concurrency library. |
| `prometheus-cohttp` | `cohttp` | A `/metrics` handler functor for any cohttp backend. |
| `prometheus-lwt` (+ `.unix`) | `lwt`, `cohttp-lwt(-unix)`, `cmdliner`, `logs` | Serving metrics from an Lwt application. |

### Use by libraries

Library authors should define a set of metrics that may be useful, depending
only on the backend-agnostic `prometheus` package. For example, the DataKitCI
cache module defines several metrics like this:

```ocaml
module Metrics = struct
  open Prometheus

  let namespace = "DataKitCI"
  let subsystem = "cache"

  let builds_started_total =
    let help = "Total number of builds started" in
    Counter.v_label ~help ~label_name:"name" ~namespace ~subsystem "builds_started_total"

  let builds_succeeded_total =
    let help = "Total number of builds that succeeded" in
    Counter.v_label ~help ~label_name:"name" ~namespace ~subsystem "builds_succeeded_total"

  let builds_failed_total =
    let help = "Total number of builds that failed" in
    Counter.v_label ~help ~label_name:"name" ~namespace ~subsystem "builds_failed_total"

  [...]
end
```

Each of these metrics has a `name` label, which allows the reports to be further broken down
by the type of thing being built.

When (for example) a build succeeds, the CI does:

```ocaml
Prometheus.Counter.inc_one (Metrics.builds_succeeded_total build_type)
```

Recording is synchronous and backend-agnostic, so this code is identical
regardless of which scheduler the eventual application uses.

### Use by applications (Lwt)

An Lwt application enables reporting with the `prometheus-lwt` package. The
`prometheus-lwt.unix` library provides the `Prometheus_lwt_unix` module, which
adds a cmdliner option and a pre-configured web-server. See `examples/example.ml`,
which can be run as:

```shell
$ dune exec -- examples/example.exe --listen-prometheus=9090
If run with the option --listen-prometheus=9090, this program serves metrics at
http://localhost:9090/metrics
Tick!
Tick!
...
```

`prometheus-lwt` also provides collectors that may suspend (`register_lwt`), an
Lwt-returning `CollectorRegistry.collect`, and Lwt timing helpers
(`Prometheus_lwt.Gauge.time`, `track_inprogress`, `Prometheus_lwt.Summary.time`).

### Exporting without an HTTP server

Unikernels and applications that push metrics elsewhere can use `prometheus-app`
directly: `Prometheus_app.TextFormat_0_0_4.output` renders a snapshot, with no
dependency on cohttp, Unix, or a concurrency library.

### API docs

Generated API documentation is available at <https://mirage.github.io/prometheus/>.

## Licensing

This code is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/docker/datakit/blob/master/LICENSE.md) for the full
license text.

[Prometheus]: https://prometheus.io

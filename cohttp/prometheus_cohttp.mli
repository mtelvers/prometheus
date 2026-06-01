(** A [/metrics] handler for any cohttp backend.

    Depends only on the base [cohttp] package, so it pulls in no concurrency
    library of its own. Instantiate {!Make} with the server module from any
    cohttp backend (e.g. [cohttp-lwt]'s [Cohttp_lwt.S.Server]). *)

module Make (Server : Cohttp.Generic.Server.S) : sig
  val callback :
    collect:(unit -> Prometheus.CollectorRegistry.snapshot Server.IO.t) ->
    Server.conn -> Http.Request.t -> Server.body -> Server.response Server.IO.t
  (** [callback ~collect] responds to [GET /metrics] with [collect ()] rendered
      in the text format, and to anything else with [400 Bad Request]. [collect]
      produces the snapshot in the server's IO monad. Use as
      [Server.make ~callback:(callback ~collect) ()]. *)
end

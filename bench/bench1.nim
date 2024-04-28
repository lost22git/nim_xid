# import timeit
import criterion

import std/oids
import xid
import uuid4

var cfg = newDefaultConfig()

benchmark cfg:
  proc xid() {.measure.} =
    discard $initXid()

  proc stdOid() {.measure.} =
    discard $genOid()

  proc nimUUID4() {.measure.} =
    discard $uuid4()

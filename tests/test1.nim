import unittest
import std/strutils
import std/os

import xid
test "initXid":
  initXid().debug()

test "castToXid":
  let raw =
    [byte 0x4d, 0x88, 0xe1, 0x5b, 0x60, 0xf4, 0x86, 0xe4, 0x28, 0x41, 0x2d, 0xc9]
  check $castToXid(raw) == "9m4e2mr0ui3e8a215n4g"

test "parseXid":
  let s = "9m4e2mr0ui3e8a215n4g"
  check s == $parseXid(s)

# NOTE: would be disordered in a second when counter overflow 3bytes
#
test "ordered!":
  var prev = ""
  var curr = ""
  for i in 1 .. 6_000_000:
    curr = $initXid()
    if curr > prev:
      prev = curr
    else:
      echo "-".repeat(66)
      parseXid(prev).debug
      echo "-".repeat(66)
      parseXid(curr).debug
      raise newException(ValueError, "disordered!")

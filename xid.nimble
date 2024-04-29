# Package

version = "0.1.0"
author = "lost"
description = "xid for nim lang"
license = "MIT"
srcDir = "src"

# Dependencies

requires "nim >= 2.0.0", "checksums"

task installBenchDeps, "install deps for bench":
  exec "nimble install criterion"
  exec "nimble install uuid4"

task bench, "run bench":
  exec "nimble installBenchDeps"
  exec "nim c -r -d:release --opt:speed bench/bench1.nim"

task docs, "generate docs":
  exec "nimble doc --index:on --project --out:docs src/xid.nim"

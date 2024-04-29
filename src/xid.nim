from std/os import getCurrentProcessId
from std/random import initRand, next
from std/times import Time, getTime, toUnix, fromUnix
from std/atomics import Atomic, fetchAdd, store
from std/strutils import strip, alignLeft
from std/streams import FileStream, openFileStream, readAll, close
import checksums/md5

#[

  # CRC32 implementation

  ## resources:
  - [crc32](https://github.com/juancarlospaco/nim-crc32/blob/master/src/crc32.nim)

]#

func createCrcTable(): array[0 .. 255, uint32] =
  for i in 0.uint32 .. 255.uint32:
    var rem = i
    for j in 0 .. 7:
      if (rem and 1) > 0'u32:
        rem = (rem shr 1) xor uint32(0xedb88320)
      else:
        rem = rem shr 1
    result[i] = rem

template updateCrc32(c: char, crc: var uint32) =
  crc =
    (crc shr 8) xor static(createCrcTable())[uint32(crc and 0xff) xor uint32(ord(c))]

func crc32(input: string): uint32 =
  result = uint32(0xFFFFFFFF)
  for c in input:
    updateCrc32(c, result)
  result = not result

#[

  # base32 implementation

]#

proc initBase32DecTab(): array[256, uint8] =
  var a: array[256, uint8]

  # '0' ~ '9'
  #
  a[48] = 0
  a[49] = 1
  a[50] = 2
  a[51] = 3
  a[52] = 4
  a[53] = 5
  a[54] = 6
  a[55] = 7
  a[56] = 8
  a[57] = 9

  # 'a' ~ 'v'
  #
  a[97] = 10
  a[98] = 11
  a[99] = 12
  a[100] = 13
  a[101] = 14
  a[102] = 15
  a[103] = 16
  a[104] = 17
  a[105] = 18
  a[106] = 19
  a[107] = 20
  a[108] = 21
  a[109] = 22
  a[110] = 23
  a[111] = 24
  a[112] = 25
  a[113] = 26
  a[114] = 27
  a[115] = 28
  a[116] = 29
  a[117] = 30
  a[118] = 31

  result = a

const base32EncTab = "0123456789abcdefghijklmnopqrstuv"

const base32DecTab = initBase32DecTab()

proc base32Encode(raw: openArray[uint8]): string {.inline.} =
  var s = newStringOfCap(20)
  s.add base32EncTab[(raw[0] shr 3).uint32]
  s.add base32EncTab[((raw[1] shr 6) and 0x1F or (raw[0] shl 2) and 0x1F).uint32]
  s.add base32EncTab[((raw[1] shr 1) and 0x1F).uint32]
  s.add base32EncTab[((raw[2] shr 4) and 0x1F or (raw[1] shl 4) and 0x1F).uint32]
  s.add base32EncTab[(raw[3] shr 7 or (raw[2] shl 1) and 0x1F).uint32]
  s.add base32EncTab[((raw[3] shr 2) and 0x1F).uint32]
  s.add base32EncTab[(raw[4] shr 5 or (raw[3] shl 3) and 0x1F).uint32]
  s.add base32EncTab[(raw[4] and 0x1F).uint32]
  s.add base32EncTab[(raw[5] shr 3).uint32]
  s.add base32EncTab[((raw[6] shr 6) and 0x1F or (raw[5] shl 2) and 0x1F).uint32]
  s.add base32EncTab[((raw[6] shr 1) and 0x1F).uint32]
  s.add base32EncTab[((raw[7] shr 4) and 0x1F or (raw[6] shl 4) and 0x1F).uint32]
  s.add base32EncTab[(raw[8] shr 7 or (raw[7] shl 1) and 0x1F).uint32]
  s.add base32EncTab[((raw[8] shr 2) and 0x1F).uint32]
  s.add base32EncTab[((raw[9] shr 5) or (raw[8] shl 3) and 0x1F).uint32]
  s.add base32EncTab[(raw[9] and 0x1F).uint32]
  s.add base32EncTab[(raw[10] shr 3).uint32]
  s.add base32EncTab[((raw[11] shr 6) and 0x1F or (raw[10] shl 2) and 0x1F).uint32]
  s.add base32EncTab[((raw[11] shr 1) and 0x1F).uint32]
  s.add base32EncTab[((raw[11] shl 4) and 0x1F).uint32]
  result = s

proc base32Decode(s: string): array[12, uint8] {.raises: [ValueError].} =
  if s.len != 20:
    raise newException(ValueError, "failed to base32Decode, input length must be 20")

  for c in s:
    if c notin {'0' .. '9', 'a' .. 'v'}:
      raise newException(
        ValueError, "failed to base32Decode, input only allow chars [0-9 a-v]"
      )

  result[0] = base32DecTab[s[0].uint32] shl 3 or base32DecTab[s[1].uint32] shr 2
  result[1] =
    base32DecTab[s[1].uint32] shl 6 or base32DecTab[s[2].uint32] shl 1 or
    base32DecTab[s[3].uint32] shr 4
  result[2] = base32DecTab[s[3].uint32] shl 4 or base32DecTab[s[4].uint32] shr 1
  result[3] =
    base32DecTab[s[4].uint32] shl 7 or base32DecTab[s[5].uint32] shl 2 or
    base32DecTab[s[6].uint32] shr 3
  result[4] = base32DecTab[s[6].uint32] shl 5 or base32DecTab[s[7].uint32]
  result[5] = base32DecTab[s[8].uint32] shl 3 or base32DecTab[s[9].uint32] shr 2
  result[6] =
    base32DecTab[s[9].uint32] shl 6 or base32DecTab[s[10].uint32] shl 1 or
    base32DecTab[s[11].uint32] shr 4
  result[7] = base32DecTab[s[11].uint32] shl 4 or base32DecTab[s[12].uint32] shr 1
  result[8] =
    base32DecTab[s[12].uint32] shl 7 or base32DecTab[s[13].uint32] shl 2 or
    base32DecTab[s[14].uint32] shr 3
  result[9] = base32DecTab[s[14].uint32] shl 5 or base32DecTab[s[15].uint32]
  result[10] = base32DecTab[s[16].uint32] shl 3 or base32DecTab[s[17].uint32] shr 2
  result[11] =
    base32DecTab[s[17].uint32] shl 6 or base32DecTab[s[18].uint32] shl 1 or
    base32DecTab[s[19].uint32] shr 4

#[

  # XID implementation

  ## resources
  - [xid go](https://github.com/rs/xid)
  - [xid rust](https://github.com/kazk/xid-rs)

]#

proc md5sum(input: openArray[uint8]): MD5Digest =
  var md5Context: MD5Context
  md5Context.md5Init()
  md5Context.md5Update(input)
  md5Context.md5Final(result)

type XidError* = object of ValueError

type Xid* {.packed.} = object
  rawTime: array[4, uint8]
  rawMachineId: array[3, uint8]
  rawProcessId: array[2, uint8]
  rawCount: array[3, uint8]

proc loadMachineIdOnLinux(): seq[uint8] {.raises: [XidError, IOError, OSError].} =
  for path in ["/var/lib/dbus/machine-id", "/etc/machine-id"]:
    var fs: FileStream
    try:
      fs = openFileStream(path, fmRead)
      let content = fs.readAll().strip()
      if content != "":
        echo "XID: load machine id: " & content
        return cast[seq[uint8]](content)
      echo "XID: failed to load machine id, read `" & path &
        "` is blank, trying next path"
    except Exception:
      echo "XID: failed to load machine id, read `" & path & "` failed, trying next path"
    finally:
      if fs != nil:
        fs.close()
  raise newException(XidError, "XID: failed to load machine id")

proc loadMachineId(): array[3, uint8] {.raises: [XidError, IOError, OSError].} =
  let machineId =
    when defined(linux):
      loadMachineIdOnLinux()
    else:
      raise newException(XidError, "XID: unimplemented on the platform")
  let md5Digest = md5sum(machineId)
  result = [md5Digest[0], md5Digest[1], md5Digest[2]]

proc loadProcessId(): array[2, uint8] =
  var pid = getCurrentProcessId().uint32
  when defined(linux):
    var fs: FileStream
    var s =
      try:
        fs = openFileStream("/proc/self/cpuset", fmRead)
        fs.readAll().strip()
      except Exception:
        ""
      finally:
        if fs != nil:
          fs.close()
    echo "XID: read `/proc/self/cpuset`: " & s
    if s != "":
      pid = pid xor crc32(s)
  echo "XID: load process id: " & $pid
  result = [(pid shr 8).uint8, pid.uint8]

let
  rawMachineId = loadMachineId()
  rawProcessId = loadProcessId()

proc readTime(): array[4, uint8] {.inline.} =
  var ts = getTime().toUnix().uint32
  result = [(ts shr 24).uint8, (ts shr 16).uint8, (ts shr 8).uint8, ts.uint8]

proc initCounter(): Atomic[uint32] =
  var rand = initRand()
  result.store(rand.next().uint32)

var counter: Atomic[uint32] = initCounter()

proc nextCount(): array[3, uint8] {.inline.} =
  let old = counter.fetchAdd(1)
  result = [(old shr 16).uint8, (old shr 8).uint8, old.uint8]

proc initXid*(): Xid =
  ## init Xid
  ##
  runnableExamples:
    block:
      let xid = initXid()
      xid.debug()

  Xid(
    rawTime: readTime(),
    rawMachineId: rawMachineId,
    rawProcessId: rawProcessId,
    rawCount: nextCount(),
  )

proc parseXid*(s: string): Xid {.raises: [XidError].} =
  ## parse Xid from a string
  ##
  runnableExamples:
    block:
      let xid = parseXid("9m4e2mr0ui3e8a215n4g")
      xid.debug()

  try:
    let raw = base32Decode(s)
    result = cast[Xid](raw)
  except Exception as e:
    raise newException(XidError, "XID: failed to parse: " & e.msg)

proc castToXid*(raw: array[12, uint8]): Xid =
  ## cast a 12 bytes as Xid
  ##
  runnableExamples:
    block:
      let raw =
        [byte 0x4d, 0x88, 0xe1, 0x5b, 0x60, 0xf4, 0x86, 0xe4, 0x28, 0x41, 0x2d, 0xc9]
      let xid = castToXid(raw)
      xid.debug()

  cast[Xid](raw)

proc `$`*(xid: Xid): string =
  ## Xid base32 hex string repr
  ##
  runnableExamples:
    block:
      let xidBase32Hex = $initXid()
      echo xidBase32Hex

  base32Encode cast[array[12, uint8]](xid)

proc time*(xid: Xid): Time =
  ## resolve Time from Xid
  ##
  runnableExamples:
    block:
      let time = initXid().time()
      echo time

  let v = xid.rawTime
  let ts = (v[0].uint32 shl 24) + (v[1].uint32 shl 16) + (v[2].uint32 shl 8) + v[3]
  result = fromUnix(ts.int64)

proc machineId*(xid: Xid): uint32 =
  ## resolve machine-id uint32 value from Xid
  ##
  runnableExamples:
    block:
      let machineId = initXid().machineId()
      echo machineId

  let v = xid.rawMachineId
  result = (v[0].uint32 shl 16) + (v[1].uint32 shl 8) + v[2]

proc processId*(xid: Xid): uint16 =
  ## resolve process-id uint16 value from Xid
  ##
  runnableExamples:
    block:
      let processId = initXid().processId()
      echo processId

  let v = xid.rawProcessId
  result = (v[0].uint16 shl 8) + (v[1].uint16)

proc count*(xid: Xid): uint32 =
  ## resolve count uint32 value from Xid
  ##
  runnableExamples:
    block:
      let count = initXid().count()
      echo count

  let v = xid.rawCount
  result = (v[0].uint32 shl 16) + (v[1].uint32 shl 8) + v[2]

proc debug*(xid: Xid) =
  ## echo Xid debug info
  ##
  runnableExamples:
    block:
      let xid = initXid()
      xid.debug()

  echo "XID".alignLeft(15), " : ", xid.repr
  echo "XID string".alignLeft(15), " : ", $xid
  echo "XID time".alignLeft(15), " : ", $xid.time()
  echo "XID machineId".alignLeft(15), " : ", $xid.machineId()
  echo "XID processId".alignLeft(15), " : ", $xid.processId()
  echo "XID count".alignLeft(15), " : ", $xid.count()

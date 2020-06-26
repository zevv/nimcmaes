
import nimcmaes
import times
import os
import strscans
import boundarytransform
import math

# Simple PPM image library

type
  Ppm = ref object
    w, h: int
    data: seq[float]

  Color = object
    r, g, b, a: float


proc initColor(r, g, b, a: float): Color =
  result.r = r.clamp(0.0, 1.0)
  result.g = g.clamp(0.0, 1.0)
  result.b = b.clamp(0.0, 1.0)
  result.a = a.clamp(0.0, 1.0)

proc newPpm(): Ppm =
  Ppm()

proc newPpm(w, h: int): Ppm =
  Ppm(w: w, h: h, data: newSeq[float](w * h * 3))

proc copyInto(pin, pout: Ppm) =
  pout.w = pin.w
  pout.h = pin.h
  pout.data = pin.data

proc read(ppm: Ppm, fname: string) =
  let fd = open(fname, fmRead)
  let version = fd.readLine()
  let size = fd.readLine()
  let depth = fd.readLine()
  doAssert scanf(size, "$i $i", ppm.w, ppm.h)
  let n = ppm.w * 3
  var tmp = newSeq[uint8](n)
  for y in 0..<ppm.h:
    doAssert fd.readBytes(tmp, 0, n) == n
    for x in 0..<n:
      ppm.data.add tmp[x].float / 255.0
  fd.close()

proc write(ppm: Ppm, fname: string) =
  let fd = open(fname, fmWrite)
  fd.write("P6\n")
  fd.write($ppm.w & " " & $ppm.h & "\n")
  fd.write("255\n")
  let n = ppm.w * 3
  var tmp = newSeq[uint8](n)
  for y in 0..<ppm.h:
    for x in 0..<n:
      tmp[x] = uint8(ppm.data[x + y*n] * 255.0)
    doAssert fd.writeBytes(tmp, 0, n) == n
  fd.close()


proc clear(p: Ppm) =
  for i in 0 ..< p.w * p.h * 3:
    p.data[i] = 0.0

proc set(p: Ppm, x, y: int, c: Color) =
  if x >= 0 and x < p.w and y >= 0 and y < p.h:
    let o = (p.w * y + x) * 3
    let (a0, a1) = (c.a, 1.0 - c.a)
    p.data[o+0] = p.data[o+0]*a1 + c.r*a0
    p.data[o+1] = p.data[o+1]*a1 + c.g*a0
    p.data[o+2] = p.data[o+2]*a1 + c.b*a0

proc get(p: Ppm, x, y: int): Color =
  if x >= 0 and x < p.w and y >= 0 and y < p.h:
    let o = (p.w * y + x) * 3
    result.r = p.data[o+0]
    result.g = p.data[o+1]
    result.b = p.data[o+2]
    result.a = 1.0

proc box(p: Ppm, x, y, w, h: int, c: Color) =
  #echo "box ", x, ",", y, " | ", w, ",", h, " | ", $c
  for y in y .. (y+h):
    for x in x .. (x+w):
      p.set(x, y, c)

# Calculate the difference between two colors

proc `-`(c1, c2: Color): float =
  sqrt(pow(c1.r - c2.r, 2) + pow(c1.g - c2.g, 2) + pow(c1.b - c2.b, 2))

# Calculate the difference between two images

proc `-`(p1, p2: Ppm): float =
  doAssert p1.w == p2.w
  doAssert p1.h == p2.h
  var err: float
  for y in 0 ..< p1.h:
    for x in 0 ..< p1.w:
      err += pow(p1.get(x, y) - p2.get(x, y), 2)
  return sqrt(err)


let mona = newPpm()
mona.read("monalisa.ppm")

let cur = newPpm(mona.w, mona.h)
#cur.box(10, 10, 200, 200, initColor(0.0, 1.0, 0.0, 1.0))

let test = newPpm(mona.w, mona.h)


# This is the fit function: It is passed an number of floats which have some
# meaning for the problem you are trying to solve. This function should
# calculate the error for a target from the inputs for your problem. The closer
# to 0, the better the input values.

let 
  bt = boundaryTransform(0.0, 1.0)

proc fitFun(v: openArray[float]): float =
  cur.copyInto(test)
  
  test.box(
    (bt(v[0]) * mona.w.float).int, (bt(v[1]) * mona.h.float).int,
    (bt(v[2]) * mona.w.float).int, (bt(v[3]) * mona.h.float).int,
    initColor(bt(v[4]), bt(v[5]), bt(v[6]), bt(v[7]))
  )

  result = mona - test
  sleep 5
  #echo result


# Run the CMAES algorithm

while true:

  let
    start  = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]  # These are the start values
    stddev = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]  # And the expected standard deviation

  let xbest = cmaesRun(start, stddev, fitFun)
  echo xbest

  test.copyInto(cur)
  cur.write("out.ppm")

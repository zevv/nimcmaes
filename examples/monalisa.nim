
import nimcmaes
import strformat
import times
import os
import strscans
import boundarytransform
import math

# Simple PPM image library

type
  Ppm = ref object
    w, h: int
    data: seq[uint8]

  Color = object
    r, g, b, a: uint8


proc initColor(r, g, b, a: uint8): Color =
  result.r = r.clamp(0, 255)
  result.g = g.clamp(0, 255)
  result.b = b.clamp(0, 255)
  result.a = a.clamp(0, 255)

proc initColor(r, g, b, a: float): Color =
  initColor(uint8(r * 255), uint8(g * 255), uint8(b * 255), uint8(a * 255))

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
  let n = ppm.w * ppm.h * 3
  ppm.data.setlen(n)
  doAssert fd.readBytes(ppm.data, 0, n) == n
  fd.close()

proc write(ppm: Ppm, fname: string) =
  let fd = open(fname, fmWrite)
  fd.write(&"P6\n{ppm.w} {ppm.h}\n255\n")
  let n = ppm.w * ppm.h * 3
  doAssert fd.writeBytes(ppm.data, 0, n) == n
  fd.close()

proc newPpm(): Ppm =
  Ppm()

proc newPpm(w, h: int): Ppm =
  Ppm(w: w, h: h, data: newSeq[uint8](w * h * 3))

proc newPpm(fname: string): Ppm =
  new result
  result.read(fname)

proc clear(p: Ppm) =
  for i in 0 ..< p.w * p.h * 3:
    p.data[i] = 0

proc set(p: Ppm, x, y: int, c: Color) =
  if x >= 0 and x < p.w and y >= 0 and y < p.h:
    let 
      o = (p.w * y + x) * 3
      a0 = c.a.int
      a1 = 255 - a0
    p.data[o+0] = ((p.data[o+0].int * a1 + c.r.int * a0) /% 255).uint8
    p.data[o+1] = ((p.data[o+1].int * a1 + c.g.int * a0) /% 255).uint8
    p.data[o+2] = ((p.data[o+2].int * a1 + c.b.int * a0) /% 255).uint8

proc get(p: Ppm, x, y: int): Color =
  if x >= 0 and x < p.w and y >= 0 and y < p.h:
    let o = (p.w * y + x) * 3
    result.r = p.data[o+0]
    result.g = p.data[o+1]
    result.b = p.data[o+2]
    result.a = 255

proc box(p: Ppm, x, y, w, h: int, c: Color) =
  #echo "box ", x, ",", y, " | ", w, ",", h, " | ", $c
  for y in y .. (y+h):
    for x in x .. (x+w):
      p.set(x, y, c)

# Calculate the difference between two colors

proc `-`(c1, c2: Color): int =
  abs(c1.r.int - c2.r.int) + abs(c1.g.int - c2.g.int) + abs(c1.b.int - c2.b.int)

# Calculate the difference between two images

proc `-`(p1, p2: Ppm): int =
  doAssert p1.w == p2.w
  doAssert p1.h == p2.h
  
  var dLine = newSeq[int](p2.h)

  var y = 0
  while y < p1.h:
    var x = 0
    while x < p1.w:
      result += abs(p1.get(x, y) - p2.get(x, y))
      inc x, 2
    inc y, 2


let mona = newPpm("monalisa.ppm")

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

  result = sqrt(float(mona - test))
  #echo result


# Run the CMAES algorithm

var n = 0
var fitmin = float.high

while true:

  let
    start  = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]  # These are the start values
    stddev = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]  # And the expected standard deviation
  
  let cmaes = newCmaes(start, stddev, fitFun)
  cmaes.run()

  let fit = cmaes.fbest

  if fit < fitmin:
    echo fit
    discard fitFun(cmaes.xbest)
    test.copyInto(cur)
    let fname = &"out-{n:05d}.ppm"
    cur.write(fname)
    inc n
    fitmin = fit

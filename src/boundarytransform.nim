
import math

type
  BoundaryTransform* = proc(x: float): float


proc boundaryTransform*(lb, ub: float): BoundaryTransform =

  let
    al = min((ub - lb) / 2.0, (1.0 + abs(lb)) / 20.0)
    au = min((ub - lb) / 2.0, (1.0 + abs(ub)) / 20.0)
    xlow = lb - 2 * al - (ub - lb) / 2.0
    xup = ub + 2 * au + (ub - lb) / 2.0
    r = 2 * (ub - lb + al + au)

  return proc(x: float): float =

    var y = x

    if y < xlow:
      y += r * (1 + floor((xlow - y) / r))

    if y > xup:
      y -= r * (1 + floor((y - xup) / r))

    if y < lb - al:
      y += 2 * (lb - al - y)

    if y > ub + au:
      y -= 2 * (y - ub - au);

    if y < lb + al:
      y = lb + (y - (lb - al)) * (y - (lb - al)) / 4.0 / al

    elif y > ub - au:
      y = ub - (y - (ub + au)) * (y - (ub + au)) / 4.0 / au

    return y




import nimcmaes
import math

# This is the fit function: It is passed an number of floats which have some
# meaning for the problem you are trying to solve. This function should
# calculate the error for a target from the inputs for your problem. The closer
# to 0, the better the input values.

proc fitFun(v: openArray[float]): float =

  # Rosenbrock function

  let (x, y) = (v[0], v[1])
  result = pow(1.0 - x, 2) + 100.0 * pow(y - x * x, 2)



# Run the CMAES algorithm

let
  start  = [0.0, 0.0]  # These are the start values
  stddev = [1.0, 1.0]  # And the expected standard deviation

let xbest = cmaesRun(start, stddev, fitFun)
echo xbest

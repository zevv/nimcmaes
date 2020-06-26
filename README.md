
This is a minimal Nim binding for the C-CMA-ES library

> "_The CMA-ES (Covariance Matrix Adaptation Evolution Strategy) is an
  evolutionary algorithm for difficult non-linear non-convex black-box
  optimisation problems in continuous domain. It is considered as
  state-of-the-art in evolutionary computation and has been adopted as one of the
  standard tools for continuous optimisation in many (probably hundreds of)
  research labs and industrial environments around the world._"

![CMA-ES](/doc/cmaes.gif)

- http://cma.gforge.inria.fr/cmaesintro.html
- http://cma.gforge.inria.fr/cmaes_sourcecode_page.html
- https://github.com/cma-es/c-cmaes

## Introduction

The CMA-ES algorithm can be used to find solutions to any N-dimensional
optimization problem.

In practical terms:

- The user provides a fitness function which calculates the error output for a
  given problem with N continuous inputs

- The CMA-ES algorithm makes up values for the inputs, calls the fit function
  and inspects the returned error

- The input variables are adjusted depending on the error value

- Step 2 and 3 are repeated until the algorithm finds the best solution
  matching your error function


For now this library offers only the bare minimum functionality of the
underlying C library. Also, I do not actually understand any of the
implementation, I just use this library to solve real-world problems.


## Example

```nim
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
```

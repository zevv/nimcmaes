
import cmaes_api
import os
import sequtils

type
  
  FitFun* = proc(vs: openArray[float]): float

  CDoubleArray1D = ptr UncheckedArray[cdouble]
  CDoubleArray2D = ptr UncheckedArray[ptr UncheckedArray[cdouble]]

  Cmaes* = ref object
    evo: cmaes_t
    dim: int
    fitfun: FitFun
    funVals: ptr cdouble
    stopReason: string
    xbest: seq[float]



proc newCmaes*(xstart: openArray[float], stddev: openArray[float], fitFun: FitFun): Cmaes =

  doAssert xstart.len == stddev.len

  var xstartc, stddevc: seq[cdouble]
  for v in xstart: xstartc.add v.cdouble
  for v in stddev: stddevc.add v.cdouble
  
  let c = new Cmaes
  c.dim = xstart.len
  c.fitFun = fitFun
  
  cmaes_init_para(addr c.evo, c.dim.cint, xstartc[0].addr, stddevc[0].addr, 0, 0, "non")

  c.evo.sp.stopTolFun = 1.0e-2
  
  c.funVals = cmaes_init_final(addr c.evo)

  result = c


proc run*(c: Cmaes) =
    
  var vs = newSeq[float](c.dim)
  let funvals = cast[CDoubleArray1D](c.funvals)

  while cmaes_TestForTermination(c.evo.addr) == nil:

    let popSize = cmaes_Get(c.evo.addr, "lambda").int
    let pop = cast[CDoubleArray2D](cmaes_SamplePopulation(c.evo.addr))

    for i in 0..<popSize:
      for j in 0..<c.dim:
        vs[j] = pop[i][j]
      funVals[i] = c.fitfun(vs)

    discard cmaes_UpdateDistribution(c.evo.addr, c.funVals)
  
  let xmean = cast[CDoubleArray1D](cmaes_GetNew(c.evo.addr, "xmean"))
  
  for i in 0..<c.dim:
    c.xbest.add  xmean[i]
  
  c.stopReason = $cmaes_TestForTermination(c.evo.addr)

  cmaes_exit(c.evo.addr)


proc xbest*(c: Cmaes): seq[float] =
  return c.xbest


proc stopReason*(c: Cmaes): string =
  return c.stopReason


proc cmaesRun*(xstart: openArray[float], stddev: openArray[float], fitFun: FitFun): seq[float] =
  let cmaes = newCmaes(xstart, stddev, fitFun)
  cmaes.run()
  return cmaes.xbest


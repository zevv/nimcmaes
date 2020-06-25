
import cmaes_api
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



proc newCmaes*(xstart: openArray[float], stddev: openArray[float], fitFun: FitFun): Cmaes =

  doAssert xstart.len == stddev.len


  var xstartc, stddevc: seq[cdouble]
  for v in xstart: xstartc.add v.cdouble
  for v in stddev: stddevc.add v.cdouble
  
  let c = new Cmaes
  c.dim = xstart.len
  c.fitFun = fitFun
  c.funVals = cmaes_init(addr c.evo, c.dim.cint, xstartc[0].addr, stddevc[0].addr, 0, 0, "non")

  result = c


proc run*(c: Cmaes): seq[float] =
    
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
  
  c.stopReason = $cmaes_TestForTermination(c.evo.addr)
    
  let xmean = cast[CDoubleArray1D](cmaes_GetNew(c.evo.addr, "xmean"))
  result.setlen c.dim
  for i in 0..<c.dim:
    result[i] = xmean[i]


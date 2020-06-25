##  ---------------------------------------------------------
##  --- File: cmaes.h ----------- Author: Nikolaus Hansen ---
##  ---------------------- last modified: IX 2010         ---
##  --------------------------------- by: Nikolaus Hansen ---
##  ---------------------------------------------------------
##
##      CMA-ES for non-linear function minimization.
##
##      Copyright (C) 1996, 2003-2010  Nikolaus Hansen.
##      e-mail: nikolaus.hansen (you know what) inria.fr
##
##      License: see file cmaes.c
##
##


{.compile: "c/src/cmaes.c".}


type
  clock_t {.importc: "clock_t".} = distinct int
  time_t {.importc: "time_t".} = distinct int


type
  INNER_C_STRUCT_cmaes_81* {.bycopy.} = object
    flg*: cint
    val*: cdouble

  INNER_C_STRUCT_cmaes_97* {.bycopy.} = object
    flgalways*: cint
    modulo*: cdouble
    maxtime*: cdouble

  cmaes_random_t* {.bycopy.} = object
    startseed*: clong          ##  Variables for Uniform()
    aktseed*: clong
    aktrand*: clong
    rgrand*: ptr clong          ##  Variables for Gauss()
    flgstored*: cshort
    hold*: cdouble

  cmaes_timings_t* {.bycopy.} = object
    totaltime*: cdouble        ##  for outside use
    ##  zeroed by calling re-calling cmaes_timings_start
    totaltotaltime*: cdouble
    tictoctime*: cdouble
    lasttictoctime*: cdouble   ##  local fields
    lastclock*: clock_t
    lasttime*: time_t
    ticclock*: clock_t
    tictime*: time_t
    istic*: cshort
    isstarted*: cshort
    lastdiff*: cdouble
    tictoczwischensumme*: cdouble

  cmaes_readpara_t* {.bycopy.} = object
    filename*: cstring         ##  keep record of the file that was taken to read parameters
    flgsupplemented*: cshort   ##  input parameters
    N*: cint                   ##  problem dimension, must stay constant, should be unsigned or long?
    seed*: cuint
    xstart*: ptr cdouble
    typicalX*: ptr cdouble
    typicalXcase*: cint
    rgInitialStds*: ptr cdouble
    rgDiffMinChange*: ptr cdouble ##  termination parameters
    stopMaxFunEvals*: cdouble
    facmaxeval*: cdouble
    stopMaxIter*: cdouble
    stStopFitness*: INNER_C_STRUCT_cmaes_81
    stopTolFun*: cdouble
    stopTolFunHist*: cdouble
    stopTolX*: cdouble
    stopTolUpXFactor*: cdouble ##  internal evolution strategy parameters
    lambda*: cint              ##  -> mu, <- N
    mu*: cint                  ##  -> weights, (lambda)
    mucov*: cdouble
    mueff*: cdouble            ##  <- weights
    weights*: ptr cdouble       ##  <- mu, -> mueff, mucov, ccov
    damps*: cdouble            ##  <- cs, maxeval, lambda
    cs*: cdouble               ##  -> damps, <- N
    ccumcov*: cdouble          ##  <- N
    ccov*: cdouble             ##  <- mucov, <- N
    diagonalCov*: cdouble      ##  number of initial iterations
    updateCmode*: INNER_C_STRUCT_cmaes_97
    facupdateCmode*: cdouble   ##  supplementary variables
    weigkey*: cstring
    resumefile*: array[99, char]
    rgsformat*: cstringArray
    rgpadr*: ptr pointer
    rgskeyar*: cstringArray
    rgp2adr*: ptr ptr ptr cdouble
    n1para*: cint
    n1outpara*: cint
    n2para*: cint

  cmaes_t* {.bycopy.} = object
    version*: cstring          ##  char *signalsFilename;
    sp*: cmaes_readpara_t
    rand*: cmaes_random_t      ##  random number generator
    sigma*: cdouble            ##  step size
    rgxmean*: ptr cdouble       ##  mean x vector, "parent"
    rgxbestever*: ptr cdouble
    rgrgx*: ptr ptr cdouble      ##  range of x-vectors, lambda offspring
    index*: ptr cint            ##  sorting index of sample pop.
    arFuncValueHist*: ptr cdouble
    flgIniphase*: cshort       ##  not really in use anymore
    flgStop*: cshort
    chiN*: cdouble
    C*: ptr ptr cdouble          ##  lower triangular matrix: i>=j for C[i][j]
    B*: ptr ptr cdouble          ##  matrix with normalize eigenvectors in columns
    rgD*: ptr cdouble           ##  axis lengths
    rgpc*: ptr cdouble
    rgps*: ptr cdouble
    rgxold*: ptr cdouble
    rgout*: ptr cdouble
    rgBDz*: ptr cdouble         ##  for B*D*z
    rgdTmp*: ptr cdouble        ##  temporary (random) vector used in different places
    rgFuncValue*: ptr cdouble
    publicFitness*: ptr cdouble ##  returned by cmaes_init()
    gen*: cdouble              ##  Generation number
    countevals*: cdouble
    state*: cdouble            ##  1 == sampled, 2 == not in use anymore, 3 == updated
    maxdiagC*: cdouble         ##  repeatedly used for output
    mindiagC*: cdouble
    maxEW*: cdouble
    minEW*: cdouble
    sOutString*: array[330, char] ##  4x80
    flgEigensysIsUptodate*: cshort
    flgCheckEigen*: cshort     ##  control via cmaes_signals.par
    genOfEigensysUpdate*: cdouble
    eigenTimings*: cmaes_timings_t
    dMaxSignifKond*: cdouble
    dLastMinEWgroesserNull*: cdouble
    flgresumedone*: cshort
    printtime*: time_t
    writetime*: time_t         ##  ideally should keep track for each output file
    firstwritetime*: time_t
    firstprinttime*: time_t


##  ---------------------------------------------------------
##  ------------------ Interface ----------------------------
##  ---------------------------------------------------------

##  --- initialization, constructors, destructors ---

proc cmaes_init*(a1: ptr cmaes_t; dimension: cint; xstart: ptr cdouble;
                stddev: ptr cdouble; seed: clong; lambda: cint;
                input_parameter_filename: cstring): ptr cdouble {.importc.}
#proc cmaes_init_para*(a1: ptr cmaes_t; dimension: cint; xstart: ptr cdouble;
#                     stddev: ptr cdouble; seed: clong; lambda: cint;
#                     input_parameter_filename: cstring)
#proc cmaes_init_final*(a1: ptr cmaes_t): ptr cdouble
#proc cmaes_resume_distribution*(evo_ptr: ptr cmaes_t; filename: cstring)
#proc cmaes_exit*(a1: ptr cmaes_t)
###  --- core functions ---
#
proc cmaes_SamplePopulation*(a1: ptr cmaes_t): ptr ptr cdouble {.importc.}
proc cmaes_UpdateDistribution*(a1: ptr cmaes_t; rgFitnessValues: ptr cdouble): ptr cdouble {.importc.}
proc cmaes_TestForTermination*(a1: ptr cmaes_t): cstring {.importc.}

###  --- additional functions ---
#
#proc cmaes_ReSampleSingle*(t: ptr cmaes_t; index: cint): ptr ptr cdouble
#proc cmaes_ReSampleSingle_old*(a1: ptr cmaes_t; rgx: ptr cdouble): ptr cdouble
#proc cmaes_SampleSingleInto*(t: ptr cmaes_t; rgx: ptr cdouble): ptr cdouble
#proc cmaes_UpdateEigensystem*(a1: ptr cmaes_t; flgforce: cint)
###  --- getter functions ---
#

proc cmaes_Get*(a1: ptr cmaes_t; keyword: cstring): cdouble {.importc.}

#proc cmaes_GetPtr*(a1: ptr cmaes_t; keyword: cstring): ptr cdouble
###  e.g. "xbestever"
#
proc cmaes_GetNew*(t: ptr cmaes_t; keyword: cstring): ptr cdouble {.importc.}
###  user is responsible to free
#
#proc cmaes_GetInto*(t: ptr cmaes_t; keyword: cstring; mem: ptr cdouble): ptr cdouble
###  allocs if mem==NULL, user is responsible to free
###  --- online control and output ---
#
#proc cmaes_ReadSignals*(a1: ptr cmaes_t; filename: cstring)
#proc cmaes_WriteToFile*(a1: ptr cmaes_t; szKeyWord: cstring; output_filename: cstring)
#proc cmaes_SayHello*(a1: ptr cmaes_t): cstring
###  --- misc ---
#
#proc cmaes_NewDouble*(n: cint): ptr cdouble
###  user is responsible to free
#
#proc cmaes_FATAL*(s1: cstring; s2: cstring; s3: cstring; s4: cstring)

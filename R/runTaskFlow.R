#' Reproduce the Run
#'
#' Uses the ID of the run and tries to reproduce its results by downloading the flow and appling it to the respecitve task.
#'
#' @template arg_task
#' @param flow [\code{\link{OMLFlow}}]\cr
#'   Flow that is applied to the Task.
#' @param par.list [\code{list}|\code{\link{OMLRunParList}}]\cr
#'   Can be either a named list containing the hyperparameter values or a \code{\link{OMLRunParList}}.
#' @template arg_seed
#' @param predict.type [character(1)]\cr
#'   Optional. See \code{\link[mlr]{setPredictType}}. 
#'   Default is "response".
#' @template arg_verbosity
#' @return [\code{OMLMlrRun}], an \code{\link{OMLRun}}.
# @export
# @family run related functions
runTaskFlow = function(task, flow, par.list, seed = 1, predict.type = NULL, verbosity = NULL) {
  assertClass(task, "OMLTask")
  assertClass(flow, "OMLFlow")
  assertString(flow$name)
  assert(checkList(par.list), checkClass(par.list, "OMLRunParList"))
  par.names = extractSubList(flow$parameters, "name")
  assertSubset(names(par.list), par.names)
  assert(checkIntegerish(seed), checkClass(seed, "OMLSeedParList"))
  seed.pars = c("seed", "kind", "normal.kind")
  kind.var = c("kind", "normal.kind")

  if (!inherits(par.list, "OMLRunParList")) {
    par.list = convertListToOMLRunParList(par.list)
  }
  if (grepl("-v.[[:punct:]]", flow$external.version)) {
    seed.pars = c("openml.seed", "openml.kind", "openml.normal.kind")
    kind.var = c("openml.kind", "openml.normal.kind")
  } else {
    stop("This flow can't be run in R.")
  }
  
  # get task and flow
  #task = getOMLTask(run$task.id)
  #flow = getOMLFlow(run$flow.id)
  
  # make learner with parameters
  lrn = convertOMLFlowToMlrLearner(flow)

  # assign data type to learner parameters 
  par.vals = convertOMLRunParListToList(par.list)
  lrn.pars = par.vals[names(par.vals)%nin%seed.pars]
  lrn.pars.type = vcapply(getParamSet(lrn)$pars, function(x) x$type)[names(lrn.pars)]
  for (i in seq_along(lrn.pars)) {
    if (lrn.pars.type[i] == "integer") lrn.pars[[i]] = as.integer(lrn.pars[[i]])
    if (lrn.pars.type[i] == "numeric") lrn.pars[[i]] = as.numeric(lrn.pars[[i]])
    if (lrn.pars.type[i] == "logical") lrn.pars[[i]] = as.logical(lrn.pars[[i]])
    if (lrn.pars.type[i] == "discrete") lrn.pars[[i]] = as.character(lrn.pars[[i]])
  }
  lrn = do.call("setHyperPars", append(list(learner = lrn), list(par.vals = lrn.pars)))
  if (!is.null(predict.type)) lrn = setPredictType(lrn, predict.type = predict.type)
  
  # FIXME: warn if installed package version are not equal
  local.pkges = vcapply(c("mlr", lrn$package), function(x) sprintf("%s_%s", x, packageVersion(x)))
  flow.pkges = strsplit(flow$dependencies, ", ")[[1]]
  local.diff = setdiff(local.pkges, flow.pkges)
  if (length(local.diff) != 0) 
    messagef("Flow has been created with %s, but you have installed %s.", 
      collapse(setdiff(flow.pkges, local.pkges), ", "), collapse(local.diff, ", "))
  
  # execute setup.string
  ret = runTaskMlr(task = task, learner = lrn, verbosity = verbosity, seed = seed)
  #ret$run.id = run$run.id
  
  return(ret)
}


convertOMLFlowToMlrLearner = function(flow) {
  if (grepl("-v2[[:punct:]]", flow$external.version)) {
    lrn = readRDS(flow$binary.path)
  } else {
    lrn = makeLearner(flow$name)
  }
  return(lrn)
}
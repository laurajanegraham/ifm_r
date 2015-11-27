# Laura Graham 21/09/2013

ifm.sim.scenarios <- function(species, scenario, years, no.start.cons, reps) {
  # load required files
  load(paste0("data/", species, "/occupancy.rda"))
  ls.mod <- readOGR(paste0("data/",species), scenario, verbose=FALSE) # landscape data (specific to species habitat requirements)
  grid.poly <- readOGR("data", "grids")
  load("data/species.info.rda") # species details (minimum area, dispersal etc.)
  minarea <- as.numeric(as.character(sp.info[sp.info$species==species,3])) # get minimum area  
  ls.mod <- ls.mod[ls.mod$area_ha >= minarea,] 
  load("data/param.subset.rda") # list of grid cells contained within identified subset
                                # for parameterising
  species.group <- sp.info[sp.info$species==species, 7] # get species group as param subset depends on this
  param.subset <- param.subset[param.subset$sp.group==species.group, 1] # get list of grids in core area for model fitting
  
  # assign variables which are used in all runs
  A <- ls.mod$area_ha
  X <- ls.mod$X/1000
  Y <- ls.mod$Y/1000
  d <- dist(cbind(X, Y))
  alpha <- sp.info$alpha[sp.info$species==species]
  edis <- as.matrix(exp(-alpha*d))
  diag(edis) <- 0
  edis <- sweep(edis, 2, A, "*")
  
  # function to calculate patch areas - used at end
  patchAreas <- function(dfrm) {
    A <- dfrm[,1]
    dfrm <- apply(dfrm[,4:ncol(dfrm)], 2, function(x) x*dfrm[,1])
    dfrm <- data.frame(A, dfrm)
  }
  # function for simulation
  metastep <- function(pa, edis, E, y) {
    pa <- pa > 0
    if(any(pa)) {
      S <- rowSums(edis[, pa, drop=FALSE])
      C <- S^2/(S^2 + y^2)
      cond <- ifelse(pa, (1-C)*E, C)
      pa <- ifelse(runif(length(pa)) < cond, !pa, pa)  
    }
    as.numeric(pa)
  }
   # list for storing results
  
  for(sc in 1:no.start.cons){
    results <- list()
    # downscale using same method as for parameterisation.
    ds.survey <- ds.res[[sc]]
    ds.survey <- subset(ds.survey, survey_1==1)
    ds.survey <- ls.mod[ds.survey,]
    p <- ls.mod$buffer_ID %in% ds.survey$buffer_ID
    p <- as.numeric(p)
    S <- rowSums(sweep(edis, 2, p, "*")) 
    
    # parameters are taken a row at a time from the original parameter set
    # reason for doing this is because they are strongly correlated ~0.7-0.9
    # so cannot either take mean, or draw from rnorm()
    subset_list <- strsplit(param.subset, ", ", fixed=TRUE)
    subset_list <- do.call("rbind", subset_list)
    #sp.grids <-  subset(sp.rec,row.names(sp.rec) %in% subset_list)
    
    # create the subset of the landscape for parameterising
    grid.subset <- grid.poly[grid.poly$grid_ref %in% subset_list,] 
    habitat.subset.survey <- ds.res[[sc]][grid.subset,]
    habitat.subset.survey <- data.frame(habitat.subset.survey@data)
    habitat.subset.survey[is.na(habitat.subset.survey)] <- 0
    
    # PARAMETERISE
    params <- model.fit(species, habitat.subset.survey, ncol(habitat.subset.survey)-4)

    x <- as.numeric(as.character(params$x))
    e <- as.numeric(as.character(params$e))
    y <- as.numeric(as.character(params$y))
    
    
    E <- pmin(e/A^x, 1)
    # matrix for storing results of each replicate
    for(r in 1:reps){
      occup <- matrix(0, nrow=length(p), ncol=years + 4)
      
      # RUN IFM
      rownames(occup) <- ls.mod@data[,1]
      occup[, 1:3] <- as.matrix(ls.mod@data[,2:4])
      occup[, 4] <- p
      for(t in 1:years) occup[, t + 4] <- metastep(occup[, t + 3], edis, E, y)
      results[[r]] <- occup
    }
    
    
    # format the results such that there ends up with one dataframe showing the total area occupied
    # for each run at each time point.
    results <- lapply(results, patchAreas)
    results <- t(sapply(results, colSums))
    
    save(results, file=paste0("results/scenarios/", species, "_", scenario, "_", reps, "reps_", years, "years_ps", param.set, ".rda"))
  }  
}

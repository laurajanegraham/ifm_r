# load required packages
require("rgdal")

# load functions
source("R/ifm.sim.scenarios.R")
source("R/model.fit.R")


sp <- "marsh.tit"
scenarios <- c("s1_60_perc", "s3_60_perc")


load(paste0("results/downscaling/", sp, ".rda"))
for(s in scenarios){
  try(ifm.sim.scenarios(sp, s, 500, 50, ds.res))
}




# load required packages
require("rgdal")
require("rgeos")

# load all functions
source("R/ds.factors.R")
source("R/ds.run.R")
source("R/ifm.sim.R")
source("R/model.fit.R")

# run ifm sim and record run time
strt<-Sys.time()
ifm.sim(input[,1], 200, 500, 8, input[,2])
print(Sys.time()-strt)

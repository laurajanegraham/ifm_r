rm(list=ls())
require(rgdal)
require(rgeos)

lcm <- readOGR("data", "lcm")
lcm <- subset(lcm, select=c("INTCODE", "area_ha"))
names(lcm) <- c("lcm_class", "area_ha")
lcm.hab <- lcm[lcm$lcm_class %in% c(1,2,3,4,5,6,8,9,10,11),] 
lcm.hab$area_ha <- gArea(lcm.hab, byid=TRUE)/10000
lcm.hab <- lcm.hab[lcm.hab$area_ha >= 0.02,]
lcm.hab$ID <- lcm.hab$OBJECTID
source("R/s1.smallest.R")
source("R/s2.largest.R")
source("R/s3.habitat.rarity.gb.R")
source("R/s4.habitat.rarity.nott.R")
source("R/s5.devs.R")
s1(lcm.hab)
s2(lcm.hab)
s3(lcm.hab)
s4(lcm.hab)
s5(lcm.hab)

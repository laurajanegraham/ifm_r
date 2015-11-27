# Laura Graham 21/09/2013

# FUNCTION FOR PARAMETERISING, RETURNS PARAMETER VALUES FOR EACH METHOD OF DOWNSCALING
model.fit <- function(species, survey, no.survey) {
  params <- matrix(0, nrow = 10, ncol=4)
  colnames(params) <- c("downscaling", "x", "e", "y")
  pres.data <- c("rand", "dist", "log.dist", "str.dist", "ifm.dist", "area", "log.area"
                 , "logidw.logarea", "str.dist.logarea", "ifm.dist.area")
  load("data/species.info.rda")
  
  # assign variables which are used in all runs
  A <- survey$area_ha
  X <- survey$X/1000
  Y <- survey$Y/1000
  alpha <- sp.info$alpha[sp.info$species==species]
  d <- dist(cbind(X, Y))
  edis <- as.matrix(exp(-alpha*d))
  diag(edis) <- 0
  edis <- sweep(edis, 2, A, "*")
  
  
  
  p <- survey[,5:(no.survey+4)]
  P <- rowSums(p)
  S <- rowSums(sweep(edis, 2, P/no.survey, "*")) 
  # fit glm
  if(no.survey==1){
    mod <- glm(P ~ offset(2*log(S)) + log(A), family = binomial)
  } else {
    mod <- glm(cbind(P, no.survey-P) ~ offset(2*log(S)) + log(A), family = binomial)  
  }
  
  # get parameters
  beta <- coef(mod)
  x <- beta[2]
  A0 <- min(A[P>0])
  ey <- exp(-beta[1])
  e <- A0^x
  y <- sqrt(ey/e)
  
  params <- data.frame(x=x, e=e, y=y) 
  return(params)
}





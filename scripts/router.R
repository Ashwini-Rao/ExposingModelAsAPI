library(plumber)
API_model <- plumb("titanic_API.R")
API_model$run(port = 8000)


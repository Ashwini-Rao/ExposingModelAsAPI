#titanic_API.R

library("plumber")
titanic_model <- readRDS("random_forest_titanic_model.Rds")

#' Landing Page with a description
#' @get /welcome
#' @html
function(){
  "<html>
    <h1><center>
    <b>Predicting Survival on Titanic dataset using Random Forest</b></center>
    </h1>

    <body>
      </br>
      <p>This model predicts the Survival probability of the passengers on Titanic given the 
        Age (in years), Sex (male/female) and Pclass (ticket class).</p>
      <p>It also outputs the model accuracy.</p>
      </br></br>
      <p>Provide the the following inputs :</p>
      <p>Sex = male/female</p>
      <p>Pclass = 1/2/3</p>
      <p>Age = number between 0 to 100 or NA if Age is unknown</p>
      </br></br>
      <p>What can you expect?</p>
      <p>Survival Probability, a value <b>0</b> (not survived) or <b>1</b> (survived)</p>
      <p>Model Accuracy in %</p>
    </body>

  </html>"
}

#Transforming the input parameters
transformTitanicData <- function(input_titantic_data) {
    cleaned_titanic_data <- data.frame(
    Sex = factor(input_titantic_data$Sex, levels = c("male", "female")),
    Pclass = factor(input_titantic_data$Pclass, levels = c("1", "2", "3")),
    Age = factor(dplyr::if_else(input_titantic_data$Age < 18, "child", "adult", "NA"), 
                 levels = c("child", "adult", "NA"))
  )
}

#Validating the input
validate_input <- function(Sex, Pclass, Age)
{
  Sex = (Sex %in% c("male", "female"))
  Pclass = (Pclass %in% c(1,2,3))
  Age = (Age >= 0 && Age <= 100 | is.na(Age))
  if(all(c(Sex, Pclass, Age)))
  {
    return("OK")
  }
  else
  {
    errorStat <- "Sex must be either male or female,
                  Pclass must be either 1,2 or 3,
                  Age must be a number between 0 to 100 or NA"
    return(errorStat)
  }
}

library(jsonlite)
#' Pass the input parameters. Validate the inputs
#' @param Sex = "male/female"
#' @param Pclas = "1/2/3"
#' @param Age = "number between 0 and 100 or NA"
#' @get /survival
predict_survival <- function(Sex = NULL, Pclass = NULL, Age = NA) {
  age = as.integer(Age)
  pclass = as.integer(Pclass)
  sex = tolower(Sex)
  valid_input <- validate_input(sex, pclass, age)
  if (valid_input[1] == "OK") 
  {
    data <- data.frame(Age=age, Pclass=pclass, Sex=sex)
    clean_data <- transformTitanicData(data)
    prediction <- predict(titanic_model, clean_data, type = "response")
    result <- list(
      input = list(data),
      output = list("Survival Probability" = unbox(prediction),
                      "Model Accuracy" = print(msg)),
      status = 200
      )
  } 
  else 
  {
      result <- list(
      input = list(Age = Age, Pclass = Pclass, Sex = Sex), 
      output = list(input_error = valid_input), 
      status = 400 
      )
  }
  return(result)
}

#' Plot Conusion Matrix
#' @get /plot
#' @png
function()
{
  library(caret)
  cm <- confusionMatrix(test_predict_titanic, test_set$Survived)
  lvs <- c("Survived", "Not Survived")
  truth <- factor(rep(lvs, times = c(109,159)), levels = rev(lvs))
  pred <- factor(c(rep(lvs, times = c(52, 57)), rep(lvs, times = c(9, 150))), levels = rev(lvs))
  xtab <- table(pred, truth)
  cm <- confusionMatrix(pred, truth)
  cm$table
  fourfoldplot(cm$table, color = c("yellow", "red"), conf.level = 0, margin = 1, main = "Confusion Matrix")
}
  
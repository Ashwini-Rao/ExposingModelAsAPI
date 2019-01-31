titanic_data <- read.csv("dataset/train.csv")

#View the data types of variables
str(titanic_data)

#Preprocess the data, i.e clean the NA/missing values, convert all variables to factor 
#variables and include only the significant variables in the model.

changeTitanicData <- function(input_titantic_data) {
  cleaned_titanic_data <- data.frame(
    Survived = factor(input_titantic_data$Survived, levels = c(0, 1)),
    Sex = factor(input_titantic_data$Sex, levels = c("male", "female")),
    Pclass = factor(input_titantic_data$Pclass, levels = c("1", "2", "3")),
    Age = factor(dplyr::if_else(input_titantic_data$Age < 18, "child", "adult", "NA"), 
                 levels = c("child", "adult", "NA"))
  )
}

processed_titanic_data <- changeTitanicData(titanic_data) 

#Split the data into 2 sets - train and test
split_set <- sample(1:nrow(processed_titanic_data), size = floor(0.7*nrow(processed_titanic_data)))
train_set <- processed_titanic_data[split_set, ]
test_set <- processed_titanic_data[-split_set, ]

#Train the model using RandomForest algorithm
#Install 'RandomForest' package only for the first time
#install.packages('randomForest')
library(randomForest)

set.seed(415)
titanic_rf <- randomForest(Survived ~ Sex + Pclass + Age, data = train_set, importance = TRUE, na.action = NULL)

#Evaluate the model
test_predict_titanic <- predict(titanic_rf, newdata = test_set, type = "response") 

library(caret)

#Plot Confusion Matrix
cmatrix = confusionMatrix(test_predict_titanic, test_set$Survived)

lvs <- c("Survived", "Not Survived")
truth <- factor(rep(lvs, times = c(102,166)), levels = rev(lvs))
pred <- factor(c(rep(lvs, times = c(66, 36)), rep(lvs, times = c(14, 152))), levels = rev(lvs))
xtab <- table(pred, truth)
cm <- confusionMatrix(pred, truth)
cm$table
options(repr.plot.width=6, repr.plot.height=6)
fourfoldplot(cm$table, color = c("yellow", "red"), conf.level = 0, margin = 1, main = "Confusion Matrix")
#Print Model Accuracy
msg <- paste0("Accuracy: ", round(100 * sum(diag(cm$table))/sum(cm$table), 2), "%")
print(msg)

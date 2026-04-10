library(class)
library(gmodels)
library(readxl)
library(wordcloud)
library(tm)
library(e1071)
library(gmodels)
library(SnowballC)
library(caret)
library(klaR)
library(naivebayes)




spam <- read.csv("spam.csv")
spam


smspam <- read.table("SMSSpamCollection", sep = "\t", col.names = c("type", "text"), quote = "",fill = TRUE, stringsAsFactors = FALSE  )
smspam

write.csv(smspam, "sms_spam.csv", row.names = FALSE)
sms_spam <- read.csv("sms_spam.csv")
sms_spam
str(sms_spam)

sms_spam$type <- as.factor(sms_spam$type)

str(sms_spam$type)
table(sms_spam$type)


sms_cps <- Corpus(VectorSource(sms_spam$text))
sms_cps


print(sms_cps)
inspect(sms_cps[1:3])

#cleaning the the paragraphs
cps_clean <- tm_map(sms_cps, tolower)
cps_clean <- tm_map(cps_clean, removeNumbers)

stopwords()
cps_clean <- tm_map(cps_clean, removeWords, stopwords())
cps_clean <- tm_map(cps_clean, stemDocument)


cps_clean <- tm_map(cps_clean, removePunctuation)
cps_clean <- tm_map(cps_clean, stripWhitespace)

sms_dtm <- DocumentTermMatrix(cps_clean)
sms_dtm


sms_train <- sms_spam[1:4180, ]
sms_test <- sms_spam[4181:5574, ]
dtm_train <- sms_dtm[1:4180, ]
dtm_test <- sms_spam[4181:5574, ]


cps_train <- cps_clean[1:4180]
cps_test <- cps_clean[4181:5574]
cps_train

prop.table(table(sms_test$type))
prop.table(table(sms_train$type))

#cloud of frequent words
wordcloud(cps_train, min.freq = 40, random.order = FALSE)

spam <- subset(sms_train, type == "spam")
ham <- subset(sms_train, type == "ham")


wordcloud(spam$text, max.words = 40,random.order = FALSE)
wordcloud(ham$text, max.words = 40, random.order = FALSE, scale = c(1,0.5))
#finding frequent words that came at least 5 times 
sms_dict <- findFreqTerms(dtm_train, 5)


train1 <- DocumentTermMatrix(cps_train, 
                            list(dictionary = sms_dict))

test1 <- DocumentTermMatrix(cps_test,
                           list(dictionary = sms_dict))
                            
   
#converting datamatrix to yes and no
convert <- function(x){
  x <- ifelse(x > 0, 1, 0)
  x <- factor(x, levels = c(0,1), labels = c("No", "Yes"))
  return(x)
}


train1 <- apply(train1, MARGIN = 2, convert)
test1 <- apply(test1, MARGIN = 2, convert)
#training the model

sms_classifier <- naiveBayes(train1, sms_train$type)

sms_pred <- predict(sms_classifier, test1)
sms_pred

CrossTable(sms_pred, sms_test$type,
           prop.chisq = FALSE, prop.t = FALSE,
           dnn = c('predicted', 'actual'))


# Install if needed: install.packages("SnowballC")

# Insert this into your cleaning pipeline after removeWords



library(caret)

# Define a grid of values to test to tune to get best laplace
tune_grid <- expand.grid(laplace = c(0, 0.5, 1, 1.5, 2), # Laplace values
                         usekernel = FALSE, 
                         adjust = 1)

# Train using 10-fold cross-validation

# 1. Ensure the labels are a factor (very important for caret)
sms_train$type <- as.factor(sms_train$type)

# 2. Run the train function with forced data frame conversion
tuned_model <- caret::train(
  x = as.data.frame(train1), 
  y = sms_train$type, 
  method = "naive_bayes", 
  trControl = trainControl(method = "cv", number = 10),
  tuneGrid = tune_grid)

# 3. View the result
print(tuned_model)

sms_classifier2 <- naiveBayes(train1, sms_train$type,
                              laplace = 0.5)
sms_pred2 <- predict(sms_classifier2, test1)


CrossTable(sms_pred2, sms_test$type,
           prop.chisq = FALSE, prop.t = FALSE,
           dnn = c('predicted', 'actual'))

#improving performance

sms_classifier3 <- naiveBayes(train1, sms_train$type,
                              laplace = 1)
sms_pred3 <- predict(sms_classifier3, test1)
sms_pred3

CrossTable(sms_pred3, sms_test$type,
           prop.chisq = FALSE, prop.t = FALSE,
           dnn = c('predicted', 'actual'))

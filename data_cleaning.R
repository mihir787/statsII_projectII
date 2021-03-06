library("ggplot2")
library("dplyr")

#read file, NA values in file are denoted by question marks
train <- read.table("adult.data", sep = ",", header = FALSE, na.strings = "?", strip.white=TRUE)
test <- read.table("adult.test", sep = ",", header = FALSE, na.strings = "?", skip = 1, strip.white=TRUE)

#set column names
colnames(train) <- c("age", "workclass", "fnlwgt", "education", "education_num", "marital_status", "occupation", "relationship", "race", "sex", "capital_gain", "capital_loss", "hours_per_week", "native_country", "income")
colnames(test) <- c("age", "workclass", "fnlwgt", "education", "education_num", "marital_status", "occupation", "relationship", "race", "sex", "capital_gain", "capital_loss", "hours_per_week", "native_country", "income")
str(train)

#set test column
train$test <- FALSE
test$test <- TRUE

# update test income 
levels(test$income)[1] <- "<=50K"
levels(test$income)[2] <- ">50K"

#merge test and train
merged <- rbind(train, test)

#remove unnecessary columns, there is only one value thus is unncessary
merged$fnlwgt <- NULL

#Remove NAs
#based off visual inspection of the data, there are a number of NA values. Lets first find the number of rows with atleast one NA value
subsetOfNAData <- train[!complete.cases(train),]
summary(subsetOfNAData)
numberNARows <- nrow(train[!complete.cases(train),])
percentNARows <- (numberNARows / nrow(train)) * 100
percentNARows
# Based off the small percentage of NA data and the overall number of rows in the dataset (32561), I am going to make the decisison that removing the rows with NA values will be more beneficial then making assumptions on filling those values.
#remove NA rows
merged <- na.omit(merged)
#re-number row names of dataframe
row.names(merged) <- 1:nrow(merged)


# for each categorical variable we want to analyze if categories can be combined or if levels need to be recoded or dropped:

# I. for workclass:
summary(merged$workclass)
merged$workclass <- droplevels(merged$workclass)
levels(merged$workclass)

merged$workclass_category <- merged$workclass

# combine into Government job
merged$workclass_category <- gsub('Federal-gov', 'Government', merged$workclass_category)
merged$workclass_category <- gsub('Local-gov', 'Government', merged$workclass_category)
merged$workclass_category <- gsub('State-gov', 'Government', merged$workclass_category) 

# combine into Self-Employed job
merged$workclass_category <- gsub('Self-emp-inc', 'Self-Employed', merged$workclass_category)
merged$workclass_category <- gsub('Self-emp-not-inc', 'Self-Employed', merged$workclass_category)

merged$workclass_category <- as.factor(merged$workclass_category)


# II. for hours per week
summary(train$hours_per_week)
ggplot(train) + aes(x=hours_per_week, group=income, fill=income) + geom_histogram(binwidth = 5)

merged$hours_per_week_category[merged$hours_per_week < 30] <- "part_time"
merged$hours_per_week_category[merged$hours_per_week >= 30 & merged$hours_per_week <= 37] <- "fringe_fulltime"
merged$hours_per_week_category[merged$hours_per_week > 37 & merged$hours_per_week <= 45  ] <- "regular_fulltime"
merged$hours_per_week_category[merged$hours_per_week > 45 & merged$hours_per_week <= 60  ] <- "overtime"
merged$hours_per_week_category[merged$hours_per_week > 60] <- "extreme_overtime"
merged$hours_per_week_category <- as.factor(merged$hours_per_week_category)

# III. separate native region into column by global regions
east_asia <- c("Cambodia", "China", "Hong", "Laos", "Thailand", "Japan", "Taiwan", "Vietnam", "Philippines")
central_subcontinent_asia <- c("India", "Iran")
central_carribean_america <- c("Cuba", "Guatemala", "Jamaica", "Nicaragua", "Puerto-Rico",  "Dominican-Republic", "El-Salvador", "Haiti", "Honduras", "Mexico", "Trinadad&Tobago")
south_america <- c("Ecuador", "Peru", "Columbia")
western_europe <- c("England", "Germany", "Holand-Netherlands", "Ireland", "France", "Greece", "Italy", "Portugal", "Scotland")
eastern_europe <- c("Poland", "Yugoslavia", "Hungary")
united_states <- c("United-States", "Outlying-US(Guam-USVI-etc)", "Outlying-US")

merged$global_region[merged$native_country %in% east_asia] <- "east_asia"
merged$global_region[merged$native_country %in% central_subcontinent_asia] <- "central_subcontinent_asia"
merged$global_region[merged$native_country %in% central_carribean_america] <- "central_carribean_america"
merged$global_region[merged$native_country %in% south_america] <- "south_america"
merged$global_region[merged$native_country %in% western_europe] <- "western_europe"
merged$global_region[merged$native_country %in% eastern_europe] <- "eastern_europe"
merged$global_region[merged$native_country %in% united_states] <- "united_states"
merged$global_region[merged$native_country == "Canada"] <- "canada"
merged$global_region[merged$native_country == "South"] <- "country_labeled_as_south"
merged$global_region <- as.factor(merged$global_region)


# IV. look at capital gains and loses
non_zero_capital_gains_subset = subset(train, train$capital_gain != 0)
non_zero_capital_loss_subset = subset(train, train$capital_loss != 0)

summary_gain <- summary(non_zero_capital_gains_subset$capital_gain)
gain_low_cutoff <- as.integer(summary_gain[[2]])
gain_high_cutoff <- as.integer(summary_gain[[5]])

merged$capital_gain_category[merged$capital_gain == 0] <- "zero"
merged$capital_gain_category[merged$capital_gain > 0 & merged$capital_gain <= gain_low_cutoff] <- "low"
merged$capital_gain_category[merged$capital_gain > gain_low_cutoff & merged$capital_gain <= gain_high_cutoff] <- "medium"
merged$capital_gain_category[merged$capital_gain > gain_high_cutoff] <- "high"
merged$capital_gain_category <- factor(merged$capital_gain_category, ordered=TRUE, levels=c("zero", "low", "medium", "high"))

summary_loss <- summary(non_zero_capital_loss_subset$capital_loss)
loss_low_cutoff <- as.integer(summary_loss[[2]])
loss_high_cutoff <- as.integer(summary_loss[[5]])

merged$capital_loss_category[merged$capital_loss == 0] <- "zero"
merged$capital_loss_category[merged$capital_loss > 0 & merged$capital_loss <= loss_low_cutoff] <- "low"
merged$capital_loss_category[merged$capital_loss > loss_low_cutoff & merged$capital_loss <= loss_high_cutoff] <- "medium"
merged$capital_loss_category[merged$capital_loss > loss_high_cutoff] <- "high"
merged$capital_loss_category <- factor(merged$capital_loss_category, ordered=TRUE, levels=c("zero", "low", "medium", "high"))

# separate train and test sets
train <- subset(merged, merged$test == FALSE)
train$test <- NULL
  
test <- subset(merged, merged$test == TRUE)
test$test <- NULL
row.names(test) <- 1:nrow(test)

# write to csv
write.csv(train, "train.csv", row.names = FALSE)
write.csv(test, "test.csv", row.names = FALSE)


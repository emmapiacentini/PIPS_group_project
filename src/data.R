data_path <- if (file.exists("data/Teen_Mental_Health_Dataset.csv")) {
  "data/Teen_Mental_Health_Dataset.csv"
} else {
  "../data/Teen_Mental_Health_Dataset.csv"
}
data <- read.csv(data_path, stringsAsFactors = FALSE)
stopifnot(!anyNA(data))
data$gender <- factor(data$gender)
data$platform_usage <- factor(data$platform_usage,
                              levels = c("Other", "Both", "Instagram", "TikTok"))
summary(data[, c("age", "daily_social_media_hours", "sleep_hours", "anxiety_level")])

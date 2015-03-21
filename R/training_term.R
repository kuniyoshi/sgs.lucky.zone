library(lattice)
library(ggplot2)
library(xts)

read_ranking <- function(filename, ...) {
    ranking <- read.delim(filename, ...)
    ranking <- transform(ranking,
                         date_time = as.POSIXct(date_time,
                                                origin  = "1970-01-01",
                                                tz      = "Asia/Tokyo",
                                                format  = "%FT%T"))
    return (ranking)
}

get_datetime.str <- function(datetime.str) {
    return (as.POSIXct(datetime.str,
                       origin   = "1970-01-01",
                       tz       = "Asia/Tokyo",
                       format   = "%FT%T"))
}

lucky_zone <- data.frame(name   = c("high", "moderate", "low"),
                         higher = c("r20000", "r30000", "r50000"),
                         lower  = c("r20200", "r30200", "r50100"))

get_col_name <- function(zone_name, high_low) {
    name <- subset(lucky_zone, name == zone_name, select = high_low)[, 1]
    return (as.character(name))
}

subset.ranking <- function(ranking, from, to, target_zone) {
    ranking <- subset(ranking,
                      date_time >= from & date_time <= to)
    higher  <- get_col_name(target_zone, "higher")
    lower   <- get_col_name(target_zone, "lower")
    ranking <- transform(ranking, higher = ranking[[higher]], lower = ranking[[lower]])
    ranking <- subset(ranking, select = c("date_time", "higher", "lower"))
    return (ranking)
}

model.ranking <- function(ranking) {
    return (with(ranking, lm((higher + lower) / 2 ~ date_time)))
}

usage.predict <- function(from, to, filename = "data/2015-03.training_term", target_zone = "moderate", target_datetime) {
    ranking <<- read_ranking(filename)

    ranking.from    <- get_datetime.str(from)
    ranking.to      <- get_datetime.str(to)
    target_datetime <- get_datetime.str(target_datetime)
    ranking         <- subset.ranking(ranking, ranking.from, ranking.to, target_zone)

    cat("[ranking]\n")
    print(ranking)

    cat("\n")

    ranking.model   <- model.ranking(ranking)

    cat("[model]\n")
    print(summary(ranking.model))

    cat("\n")

    predicted_score <- predict(ranking.model,
                               data.frame(date_time = target_datetime),
                               interval = "prediction")

    cat("[predicted]\n")
    print(predicted_score)
}

load_score <- function() {
    score <- read.delim("score")
    return (score)
}

get_score_data_free <- function(score) {
    score <- unique(c(0, score))
    data_free <- expand.grid(score, score, score, score, score)
    data_free <- transform(as.data.frame(data_free),
                           sum=Var1 + Var2 + Var3 + Var4 + Var5,
                           games=sum(c(Var1, Var2, Var3, Var4, Var5) == 0))
    return (data_free)
}

craft_score <- function(target, score) {
    score <- unique(c(0, score))
    data_free <- get_score_data_free(score)

    if (!any(data_free$sum == target)) {
        return (NULL)
    }

    craft <- subset(data_free,
                    sum == target,
                    select=c("Var1", "Var2", "Var3", "Var4", "Var5"))


    return (craft)
}

usage.game <- function(now, target, in_rival_term=FALSE) {
    score <<- load_score()
}

#extract_ranking_score <- function(tt) {
#    ranking_score <- tt[names(tt) != "date_time" & names(tt) != "my_score" & names(tt) != "my_ranking"]
#    return (ranking_score)
#}
#
#plot_latest <- function(tt) {
#    latest_tt <- extract_ranking_score(tail(tt, 1))
#    x <- as.integer(substr(names(latest_tt), 2, nchar(names(latest_tt))))
#    y <- c(t(latest_tt))
#    plot(x, y, type="l")
#}
#
#extract_my_target_ranking <- function(tt) {
#    return (subset(tt, select=c("date_time", "r30000", "r30200")))
#}
#
#transform_target_ranking <- function(tt) {
#    tt.lower <- transform(subset(tt, select=c("date_time", "r30200")),
#                          ranking="r30200")
#    tt.lower <- subset(transform(tt.lower, score=r30200), select=c("date_time", "ranking", "score"))
#    tt.upper <- transform(subset(tt, select=c("date_time", "r30000")),
#                          ranking="r30000")
#    tt.upper <- subset(transform(tt.upper, score=r30000), select=c("date_time", "ranking", "score"))
#    border <- rbind(tt.lower, tt.upper)
#    return (border)
#}
#
#transform_to_xts <- function(tt) {
#    tt <- transform(tt, date_time=as.POSIXct(date_time, origin="1970-01-01", tz="Asia/Tokyo", format="%FT%T"))
#    tt.xts <- with(tt,
#                   as.xts(score, date_time, tzone="Asia/Tokyo"))
#    return (tt.xts)
#}
#
#usage <- function() {
#    tt          <<- read_data()
#    tt.target   <<- extract_my_target_ranking(tt)
#}

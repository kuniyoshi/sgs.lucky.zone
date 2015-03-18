library(lattice)
library(ggplot2)
library(xts)

read_data <- function(...) {
    tt <- read.delim("2015-03.training_term")
    tt <- transform(tt,
                    date_time=as.POSIXct(date_time, origin="1970-01-01", tz="Asia/Tokyo", format="%FT%T"))
    return (tt)
}

subset.tt <- function(tt, tt.from=tt.posixct, tt.to=max(tt$date_time)) {
    tt <- subset(tt,
                 date_time >= tt.from & date_time <= tt.to,
                 select=c("date_time", "r30000", "r30200"))
    return (tt)
}

split.tt <- function(tt) {
    tt.lower <- subset(transform(tt, score=r30200),
                       select=c("date_time", "score"))
    tt.upper <- subset(transform(tt, score=r30000),
                       select=c("date_time", "score"))
    return (list(lower=tt.lower, upper=tt.upper))
}

model.tt <- function(tt) {
    return (with(tt, lm(score ~ date_time)))
}

usage.predict <- function(from, to=NULL, target_date_time) {
    tt          <<- read_data()

    if (is.null(to)) {
        to <- max(tt$date_time)
    }

    tt.from     <<- as.POSIXct(from, origin="1970-01-01", tz="Asia/Tokyo", format="%FT%T")
    tt.to       <<- as.POSIXct(to,   origin="1970-01-01", tz="Asia/Tokyo", format="%FT%T")
    tt.subset   <<- subset.tt(tt, tt.from=tt.from, tt.to=tt.to)

    tt.lu       <<- split.tt(tt.subset)
    tt.lower    <<- tt.lu$lower
    tt.upper    <<- tt.lu$upper

    tt.lower.lm <<- model.tt(tt.lower)
    print("summary of lower:")
    print(summary(tt.lower.lm))
    tt.upper.lm <<- model.tt(tt.upper)
    print("summary of upper:")
    print(summary(tt.upper.lm))

    tt.lower.predicted <<- predict(tt.lower.lm,
                                   data.frame(date_time=target_date_time),
                                   interval="prediction")
    print("predicted loewr:")
    print(tt.lower.predicted)
    tt.upper.predicted <<- predict(tt.upper.lm,
                                   data.frame(date_time=target_date_time),
                                   interval="prediction")
    print("predicted upper:")
    print(tt.upper.predicted)
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

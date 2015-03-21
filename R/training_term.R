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

usage.predict <- function(from,
                          to,
                          filename      = "data/2015-03.training_term",
                          target_zone   = "moderate",
                          target_datetime) {
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

load_score <- function(filename, ...) {
    score <- read.delim(filename, ...)
    return (score)
}

get_score_data_free <- function(score) {
    score <- unique(c(0, score))
    data_free <- expand.grid(score, score, score, score, score) # TODO: need more count flexible way.
    data_free <- transform(as.data.frame(data_free),
                           sum      = Var1 + Var2 + Var3 + Var4 + Var5,
                           games    = sum(c(Var1, Var2, Var3, Var4, Var5) == 0))
    return (data_free)
}

craft_score <- function(score, available_score) {
    available_score <- unique(c(0, available_score))
    data_free       <- get_score_data_free(available_score)

    if (!any(data_free$sum == score)) {
        return (NULL)
    }

    crafted <- subset(data_free,
                      sum == score,
                      select = c("Var1", "Var2", "Var3", "Var4", "Var5"))

    crafted <- apply(unique(apply(apply(crafted, 1, sort), 1, paste)), 2, as.numeric)

    return (crafted)
}

get_score_description <- function(score, score_board) {
    score_board <- subset(score_board, score == score)
}

usage.game <- function(current_score,
                       target_score,
                       is_rival_time    = FALSE,
                       score_source     = "data/score") {
    score <<- load_score(score_source)
    score <- subset(score, rival == is_rival_time)

    crafted_score <- craft_score(target_score - current_score,
                                 score$score)

    return (crafted_score)
}


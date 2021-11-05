library(magrittr)
library(ggplot2)

orig <- read.csv("~sarahlotspeich/Dropbox/UNC/R-Ladies-Missing-Data-Nov-2021/filling-in-blanks/data/netflix_orig.csv")
orig <- orig[complete.cases(orig[, -c(4:5)]), ]

orig %>% dplyr::filter(kind %in% c("movie", "tv movie", "tv short")) -> orig_movie 

# MCAR - random sample
orig_movie %>% 
  dplyr::mutate(rating_mcar = ifelse(runif(n = nrow(orig_movie), min = 0, max = 1) > 0.8, NA, rating)) -> orig_movie

make_missing_figure <- function(var_miss, data) {
  data$missing <- factor(is.na(data[, var_miss]), levels = rev(c(TRUE, FALSE)), labels = rev(c("Missing", "Non-Missing")))
  
  data %>% 
    ggplot(aes(x = log(votes), fill = missing)) + geom_histogram() + theme_bw(base_size = 12) + 
    scale_fill_manual(values = rcartocolor::carto_pal(n = 4, name = "Safe"), "Status:") + 
    theme(legend.position = "top") -> fig_movie_mcar_1
  
  data %>% 
    ggplot(aes(x = runtime, fill = missing)) + geom_histogram() + theme_bw(base_size = 12) + 
    scale_fill_manual(values = rcartocolor::carto_pal(n = 4, name = "Safe"), "Status:") + 
    theme(legend.position = "top") -> fig_movie_mcar_2
  
  data %>% 
    dplyr::mutate(is_comedy = factor(is_comedy, levels = c(0, 1), labels = c("TRUE", "FALSE"))) %>%
    ggplot(aes(x = is_comedy, fill = missing)) + geom_bar() + theme_bw(base_size = 12) + xlab("Is comedy?") + 
    scale_fill_manual(values = rcartocolor::carto_pal(n = 4, name = "Safe"), "Status:") + 
    theme(legend.position = "top") -> fig_movie_mcar_3
  
  data %>% 
    dplyr::mutate(is_drama = factor(is_drama, levels = c(0, 1), labels = c("TRUE", "FALSE"))) %>%
    ggplot(aes(x = is_drama, fill = missing)) + geom_bar() + theme_bw(base_size = 12) + xlab("Is drama?") + 
    scale_fill_manual(values = rcartocolor::carto_pal(n = 4, name = "Safe"), "Status:") + 
    theme(legend.position = "top") -> fig_movie_mcar_4
  
  ggpubr::ggarrange(fig_movie_mcar_1, fig_movie_mcar_2, fig_movie_mcar_3, fig_movie_mcar_4, common.legend = TRUE)
}

# MAR - missingness depends on year 
orig_movie %>% 
  dplyr::mutate(rating_mar = ifelse(votes < 1000, NA, rating)) -> orig_movie

make_missing_figure(var_miss = "rating_mar", data = orig_movie)

# MNAR - movies with < 1000 votes don't have ratings (annonymity)
orig_movie %>% 
  dplyr::mutate(rating_mnar = ifelse(original_air_year > 2017, rating, NA)) -> orig_movie

make_missing_figure(var_miss = "rating_mnar", data = orig_movie)

# Fit complete-case 
cc_true <- lm(formula = rating ~ log(votes) + runtime + is_comedy + is_drama, data = orig_movie)
cc_mcar <- lm(formula = rating_mcar ~ log(votes) + runtime + is_comedy + is_drama, data = orig_movie)
cc_mar <- lm(formula = rating_mar ~ log(votes) + runtime + is_comedy + is_drama, data = orig_movie)
cc_mnar <- lm(formula = rating_mnar ~ log(votes) + runtime + is_comedy + is_drama, data = orig_movie)

orig %>% dplyr::filter(!(kind %in% c("movie", "tv movie", "tv short")),
                       original_air_year >= 1998)  -> orig_series 

# MCAR - random sample
orig_series %>% 
  dplyr::mutate(rating_mcar = ifelse(runif(n = nrow(orig_series), min = 0, max = 1) > 0.8, NA, rating)) -> orig_series

make_missing_figure(var_miss = "rating_mcar", data = orig_series)

# MAR - missingness depends on year 
orig_series %>% 
  dplyr::mutate(rating_mar = ifelse(votes < 1000, NA, rating)) -> orig_series

make_missing_figure(var_miss = "rating_mar", data = orig_series)

# MNAR - movies with < 1000 votes don't have ratings (annonymity)
orig_series %>% 
  dplyr::mutate(rating_mnar = ifelse(original_air_year > 2017, rating, NA)) -> orig_series

make_missing_figure(var_miss = "rating_mnar", data = orig_series)

orig_series %>% 
  dplyr::arrange(series_imdb_id, season, episode) -> orig_series

# Fit complete-case 
cc_true <- geepack::geese(formula = rating ~ log(votes) + runtime + is_comedy + is_drama, data = orig_series, id = series_imdb_id)
cc_mcar <- geepack::geese(formula = rating_mcar ~ log(votes) + runtime + is_comedy + is_drama, data = orig_series, id = series_imdb_id)
cc_mar <- geepack::geese(formula = rating_mar ~ log(votes) + runtime + is_comedy + is_drama, data = orig_series, id = series_imdb_id)
cc_mnar <- geepack::geese(formula = rating_mnar ~ log(votes) + runtime + is_comedy + is_drama, data = orig_series, id = series_imdb_id)

orig_movie %>% 
  dplyr::select(-original_air_year, -original_air_date, -season, -episode) %>%
  write.csv(file = "~sarahlotspeich/Dropbox/UNC/R-Ladies-Missing-Data-Nov-2021/filling-in-blanks/data/movies.csv", row.names = F)

orig_series %>% 
  dplyr::select(-original_air_year, -original_air_date) %>%
  write.csv(file = "~sarahlotspeich/Dropbox/UNC/R-Ladies-Missing-Data-Nov-2021/filling-in-blanks/data/series.csv", row.names = F)

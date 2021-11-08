# Filling in the Blanks: Multiply Imputing Missing Data in R
## Marissa Ashner, PhD(C) and Sarah Lotspeich, PhD
### Code for presentation for R-Ladies Research Triangle Park, North Carolina


```{r, eval = T}
# Load packages
library(magrittr)
library(dplyr)
library(geepack)
```

# Data 

## Background 

We use [Netflix data](https://data.world/hunterkempf/netflixocaug2020) from `data.world` as a motivating example for this activity. Specifically, we are interested in predicting the ratings of Netflix `movies` and `series` (separately) based on predictors: number of `votes` (log-transformed), `runtime`, `is_comedy` genre, and `is_drama` genre. 

In the `~/data/` sub-directory, we have included three versions of the `movies` and `series` data to demonstrate different types of missingness in the outcome variable, `rating`. For this exercise, we recommend choosing one to start. The variable `rating_miss` will contain missing data, while true `rating` will not.

  - `~/data/MCAR/`: missing completely at random (MCAR)
  - `~/data/MAR/`: missing at random (MAR)
  - `~/data/MNAR/`: missing not at random (MNAR)

## Movie Ratings

Variables included in the `movies` dataset are as follow: 

  - `series_name`: movie title
  - `rating`: mean audience rating between 0 and 10 (fully observed)
  - `votes`: number of audience votes for `rating`
  - `runtime`: run time (in minutes)
  - `is_comedy`: indicator of whether the movie genres included "comedy"
  - `is_drama`: indicator of whether the movie genres included "drama"
  - `rating_miss`: mean audience rating between 0 and 10 (with missing data)

```{r, eval = T}
movies <- read.csv("https://raw.githubusercontent.com/sarahlotspeich/filling-in-blanks/main/data/MCAR/movies.csv")
head(movies)
```

## Series Ratings

In addition to the same variables as above, the `series` dataset contains the following: 

  - `season`: series season
  - `episode`: series episode 

```{r, eval = T}
series <- read.csv("https://raw.githubusercontent.com/sarahlotspeich/filling-in-blanks/main/data/MCAR/series.csv")
head(series)
```

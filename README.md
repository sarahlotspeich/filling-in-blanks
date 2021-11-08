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
        series_name rating votes runtime is_comedy is_drama rating_miss
1      An Easy Girl    5.5  1519      92         1        1          NA
2       The Week Of    5.1 17594     116         1        0         5.1
3    Murder Mystery    6.0 94014      97         1        0         6.0
4        Sextuplets    4.4  6784      97         1        0         4.4
5 The Kissing Booth    6.0 60140     105         1        0         6.0
6      #REALITYHIGH    5.2  5332      99         1        1         5.2
```

## Series Ratings

In addition to the same variables as above, the `series` dataset contains the following: 

  - `season`: series season
  - `episode`: series episode 

```{r, eval = T}
series <- read.csv("https://raw.githubusercontent.com/sarahlotspeich/filling-in-blanks/main/data/MCAR/series.csv")
head(series)
     series_name series_num season episode rating votes runtime is_comedy is_drama rating_miss
1 13 Reasons Why          1      1       1    8.3  6952      54         0        1         8.3
2 13 Reasons Why          1      1       2    8.0  5803      52         0        1         8.0
3 13 Reasons Why          1      1       3    7.9  5453      57         0        1          NA
4 13 Reasons Why          1      1       4    8.1  5260      57         0        1         8.1
5 13 Reasons Why          1      1       5    8.2  5202      59         0        1         8.2
6 13 Reasons Why          1      1       6    8.0  5015      52         0        1         8.0
```

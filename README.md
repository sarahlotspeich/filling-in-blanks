# Filling in the Blanks: Multiply Imputing Missing Data in R
## Marissa Ashner, PhD(C) and Sarah Lotspeich, PhD
### Code for presentation for R-Ladies Research Triangle Park, North Carolina

```{r, eval = T}
# (If needed) Install packages
# install.packages(c("magrittr", "dplyr", "ggplot2", "geepack", "mice"))
```

```{r, eval = T}
# Load packages
library(magrittr)
library(dplyr)
library(ggplot2)
library(geepack)
library(mice)
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
# Read in movies data
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
# Read in series data
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

# Describing Missingness 

Since we only have missingness in `rating`, we can summarize this with a simple **percent missing**. Practice calculating the percent of missing `rating` variables below... 

```{r}
# Missingness in movie ratings
mean(is.na(movies$rating_miss))
[1] 0.2061856

# Missingness in series ratings
mean(is.na(series$rating_miss))
[1] 0.1970006
```

If we had multiple variables with missing data, we would want to consider something more sophisticated. For example, there are a number of neat `R` packages (like `naniar::gg_miss_upset()`) to help visualize **missingness patterns** across variables. 

# Models 

Fit the true models using complete data on everyone (hint: use the fully observed outcome `rating`).

## Predicting Movie Ratings with Linear Regression

We have independent observations on 97 Netflix movies. To predict ratings, we will fit a **normal linear regression** model: 

```{r}
# Fit the *true* (i.e., no missing data) movie ratings model using lm()
summary(lm(formula = rating ~ log(votes) + runtime + is_comedy + is_drama, 
           data = movies))
```

```{r}
Call:
lm(formula = rating ~ log(votes) + runtime + is_comedy + is_drama, 
    data = movies)

Residuals:
     Min       1Q   Median       3Q      Max 
-2.15013 -0.63526 -0.07633  0.53881  2.54139 

Coefficients:
             Estimate Std. Error t value Pr(>|t|)    
(Intercept)  6.132787   0.503494  12.180  < 2e-16 ***
log(votes)   0.227211   0.058889   3.858 0.000212 ***
runtime     -0.018322   0.004515  -4.058 0.000104 ***
is_comedy   -0.327467   0.234864  -1.394 0.166589    
is_drama     0.187928   0.228869   0.821 0.413701    
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

Residual standard error: 0.8971 on 92 degrees of freedom
Multiple R-squared:  0.1967,	Adjusted R-squared:  0.1618 
F-statistic: 5.633 on 4 and 92 DF,  p-value: 0.0004225
```

## Predicting Episode Ratings with Generalized Estimating Equations (GEE)

We have dependent (i.e., correlated within-series) observations on 279 Netflix shows. To predict ratings, we will fit a **Generalized Estimating Equations (GEE)**. For now you'll just have to trust us on this, but if you're interested in learning more about GEE here's a nice document from [Penn State](https://online.stat.psu.edu/stat504/lesson/12/12.1). 

```{r}
# Fit the *true* (i.e., no missing data) series episode ratings model using geese()
summary(geese(formula = rating ~ log(votes) + runtime + is_comedy + is_drama, 
              data = series, 
              id = series_num))
```

```{r}
Call:
geese(formula = rating ~ log(votes) + runtime + is_comedy + is_drama, 
    id = series_num, data = series)

Mean Model:
 Mean Link:                 identity 
 Variance to Mean Relation: gaussian 

 Coefficients:
              estimate      san.se        wald            p
(Intercept) 6.30605556 0.305648149 425.6690237 0.0000000000
log(votes)  0.12387523 0.034366026  12.9930251 0.0003126534
runtime     0.01096477 0.003011369  13.2577836 0.0002714504
is_comedy   0.10306925 0.143166353   0.5182941 0.4715702700
is_drama    0.44508262 0.176422884   6.3646047 0.0116419028

Scale Model:
 Scale Link:                identity 

 Estimated Scale Parameters:
             estimate     san.se     wald p
(Intercept) 0.6942684 0.05755642 145.5014 0

Correlation Model:
 Correlation Structure:     independence 

Returned Error Value:    0 
Number of clusters:   279   Maximum cluster size: 1011
```

# Simple Approaches *(for Independent or Dependent Data)*
## Complete Case Analysis
The **complete case analysis** simply excludes any subjects who have missing data in any of the variables of interest (outcome or predictors). Compare the complete case analysis in `movies` to the true model above.

```{r}
# Fit the complete case model for movie ratings using lm()
summary(lm(formula = rating_miss ~ log(votes) + runtime + is_comedy + is_drama, 
           data = movies))
```

```{r}
Call:
lm(formula = rating_miss ~ log(votes) + runtime + is_comedy + 
    is_drama, data = movies)

Residuals:
     Min       1Q   Median       3Q      Max 
-2.13752 -0.63781 -0.01549  0.60496  2.53750 

Coefficients:
             Estimate Std. Error t value Pr(>|t|)    
(Intercept)  6.418334   0.556331  11.537  < 2e-16 ***
log(votes)   0.173887   0.068527   2.538  0.01333 *  
runtime     -0.016215   0.005415  -2.994  0.00377 ** 
is_comedy   -0.330873   0.260432  -1.270  0.20800    
is_drama     0.138777   0.266709   0.520  0.60443    
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

Residual standard error: 0.8994 on 72 degrees of freedom
  (20 observations deleted due to missingness)
Multiple R-squared:  0.1283,	Adjusted R-squared:  0.07988 
F-statistic:  2.65 on 4 and 72 DF,  p-value: 0.04006
```

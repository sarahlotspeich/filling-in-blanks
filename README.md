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

## Single Imputation 

**Single imputation** usually involves "filling in the blanks" with a numerical summary of the non-missing values. 

For example, we might replace missing movie `rating_miss` with the mean or median. We can do this using `dplyr::mutate()`. 

```{r}
# Replace missing rating_miss values with the mean of the non-missing values 
movies %>% 
  dplyr::mutate(rating_imp = ifelse(is.na(rating_miss), 
                                    mean(rating_miss, na.rm = TRUE), 
                                    rating_miss)) -> movies
head(movies)
        series_name rating votes runtime is_comedy is_drama rating_miss rating_imp
1      An Easy Girl    5.5  1519      92         1        1          NA   6.180519
2       The Week Of    5.1 17594     116         1        0         5.1   5.100000
3    Murder Mystery    6.0 94014      97         1        0         6.0   6.000000
4        Sextuplets    4.4  6784      97         1        0         4.4   4.400000
5 The Kissing Booth    6.0 60140     105         1        0         6.0   6.000000
6      #REALITYHIGH    5.2  5332      99         1        1         5.2   5.200000
```

```{r}
# Fit the single imputation model (i.e., using your singly imputed rating value 
## from the previous chunk)
summary(lm(formula = rating_imp ~ log(votes) + runtime + is_comedy + is_drama, 
        data = movies))
```

```{r}
Call:
lm(formula = rating_imp ~ log(votes) + runtime + is_comedy + 
    is_drama, data = movies)

Residuals:
     Min       1Q   Median       3Q      Max 
-1.96885 -0.46802 -0.03898  0.49155  2.30436 

Coefficients:
             Estimate Std. Error t value Pr(>|t|)    
(Intercept)  6.298451   0.457326  13.772  < 2e-16 ***
log(votes)   0.119399   0.053489   2.232  0.02803 *  
runtime     -0.010854   0.004101  -2.647  0.00956 ** 
is_comedy   -0.219251   0.213327  -1.028  0.30675    
is_drama     0.058926   0.207882   0.283  0.77746    
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

Residual standard error: 0.8148 on 92 degrees of freedom
Multiple R-squared:  0.08586,	Adjusted R-squared:  0.04611 
F-statistic:  2.16 on 4 and 92 DF,  p-value: 0.07965
```

We could also get a little fancy and do *conditional* mean imputation by replacing missing ratings with group-specific means like mean rating for a comedy versus mean rating for a drama. 

# Simple Approaches *(for Dependent Data)*

The `series` dataset could be considered longitudinal (we have multiple episodes per series and these episodes are believed to be correlated). We can take advantage of the dependence in these data to do series-specific imputation, rather than overall as above.

Consider data on the Great British Baking Show.... there are 109 episodes. Of them, 22 are missing their `rating_miss`. We have two options: 

  1. Replace missing values with the average rating for an episode of the Great British Baking Show
  2. Assume that the missing value is the same as non-missing rating for the episode that came before it 

## Within-Series Single Imputation

```{r}
# Replace missing rating_miss values with the mean of the non-missing values *for the same series*
series %>% 
  dplyr::group_by(series_name) %>% 
  dplyr::mutate(rating_imp = ifelse(is.na(rating_miss), 
                                    mean(rating_miss, na.rm = TRUE), 
                                    rating_miss)) -> series
```

```{r}
# Check your imputations for the Great British Baking Show  
series %>% 
  dplyr::filter(series_name == "The Great British Baking Show") %>% 
  head()
    series_name                   series_num season episode rating votes runtime is_comedy is_drama rating_miss rating_imp
1 The Great British Baking Show        217      1       1    8.2    58      58         0        0        NA         8.21
2 The Great British Baking Show        217      1       2    8      38      58         0        0         8         8   
3 The Great British Baking Show        217      1       3    8.1    33      58         0        0         8.1       8.1 
4 The Great British Baking Show        217      1       4    8      32      52         0        0         8         8   
5 The Great British Baking Show        217      1       5    8      33      58         0        0        NA         8.21
6 The Great British Baking Show        217      1       6    8.2    30      58         0        0         8.2       8.2 
```

```{r}
# Fit the single imputation model (i.e., using your singly imputed rating value 
## from the previous chunk)
summary(geepack::geese(formula = rating_imp ~ log(votes) + runtime + is_comedy + is_drama, 
               data = series, 
               id = series_num))
```

```{r}
Call:
geepack::geese(formula = rating_imp ~ log(votes) + runtime + 
    is_comedy + is_drama, id = series_num, data = series)

Mean Model:
 Mean Link:                 identity 
 Variance to Mean Relation: gaussian 

 Coefficients:
              estimate      san.se        wald            p
(Intercept) 6.33885113 0.300512047 444.9357816 0.0000000000
log(votes)  0.12001612 0.033523938  12.8164908 0.0003435775
runtime     0.01073265 0.002959478  13.1517615 0.0002872491
is_comedy   0.08538074 0.144812107   0.3476242 0.5554610806
is_drama    0.45007802 0.183754852   5.9992642 0.0143118461

Scale Model:
 Scale Link:                identity 

 Estimated Scale Parameters:
             estimate     san.se     wald p
(Intercept) 0.6461798 0.05419907 142.1422 0

Correlation Model:
 Correlation Structure:     independence 

Returned Error Value:    0 
Number of clusters:   270   Maximum cluster size: 1011 
```

## Carry-Forward Imputation

```{r}
# Replace missing rating_miss values with the preceding non-missing value *for the same series*
series %>% 
  dplyr::group_by(series_num) %>% 
  dplyr::mutate(rating_imp = ifelse(is.na(rating_miss), 
                                    dplyr::lag(x = rating_miss, n = 1, default = NA), 
                                    rating_miss)) -> series
# Check your imputations for the Great British Baking Show
series %>% 
  dplyr::filter(series_name == "The Great British Baking Show") %>% 
  head()  
  series_name                   series_num season episode rating votes runtime is_comedy is_drama rating_miss rating_imp
1 The Great British Baking Show        217      1       1    8.2    58      58         0        0        NA         NA  
2 The Great British Baking Show        217      1       2    8      38      58         0        0         8          8  
3 The Great British Baking Show        217      1       3    8.1    33      58         0        0         8.1        8.1
4 The Great British Baking Show        217      1       4    8      32      52         0        0         8          8  
5 The Great British Baking Show        217      1       5    8      33      58         0        0        NA          8  
6 The Great British Baking Show        217      1       6    8.2    30      58         0        0         8.2        8.2  
```

```{r}
# Fit the single imputation model (i.e., using your singly imputed rating value 
## from the previous chunk)
summary(geepack::geese(formula = rating_imp ~ log(votes) + runtime + is_comedy + is_drama, 
               data = series, 
               id = series_num))
```

```{r}
Call:
geepack::geese(formula = rating_imp ~ log(votes) + runtime + 
    is_comedy + is_drama, id = series_num, data = series)

Mean Model:
 Mean Link:                 identity 
 Variance to Mean Relation: gaussian 

 Coefficients:
              estimate      san.se        wald            p
(Intercept) 6.30915603 0.307154813 421.9178380 0.0000000000
log(votes)  0.12395793 0.034312928  13.0506780 0.0003031746
runtime     0.01116104 0.003021178  13.6476165 0.0002205211
is_comedy   0.08922310 0.143918414   0.3843456 0.5352866869
is_drama    0.43690914 0.178660264   5.9803461 0.0144661634

Scale Model:
 Scale Link:                identity 

 Estimated Scale Parameters:
             estimate     san.se     wald p
(Intercept) 0.6766529 0.05379602 158.2091 0

Correlation Model:
 Correlation Structure:     independence 

Returned Error Value:    0 
Number of clusters:   270   Maximum cluster size: 980 
```

# Multiple Imputation 

Use subjects without missing data to fit the imputation model for `rating_miss` in the `movies` data. Save the model coefficients and their covariance matrix. 

```{r}
# Fit the imputation model for movies rating (complete-case) 
imp_mod <- lm(formula = rating_miss ~ log(votes) + runtime + is_comedy + is_drama, 
              data = movies)
# Save the imputation model coefficients
(imp_coeff <- imp_mod$coefficients)
```

```{r}
(Intercept)  log(votes)     runtime   is_comedy    is_drama 
 6.41833383  0.17388746 -0.01621476 -0.33087338  0.13877701 
```

```{r}
# Save the imputation model covariance matrix
imp_cov <- vcov(imp_mod)
```

```{r}
              (Intercept)    log(votes)       runtime    is_comedy      is_drama
(Intercept)  0.3095042533 -0.0184436224 -9.934479e-04 -0.064950367  0.0103304061
log(votes)  -0.0184436224  0.0046959176 -2.168729e-04 -0.001805841 -0.0013836084
runtime     -0.0009934479 -0.0002168729  2.932595e-05  0.000257734 -0.0003179052
is_comedy   -0.0649503672 -0.0018058410  2.577340e-04  0.067824794  0.0179655741
is_drama     0.0103304061 -0.0013836084 -3.179052e-04  0.017965574  0.0711337253
```

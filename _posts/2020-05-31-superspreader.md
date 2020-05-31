---
layout: post
title: "Superspreading and the Gini Coefficient"
tags: [rstats, dataviz, R, COVID-19, SARS-CoV-2, epidemic models]
#  bibliography: ~/Literature/Bibtex/jabref.bib
header-includes:
   - \usepackage{bm}
comments: true
editor_options:
  chunk_output_type: console
---



## Abstract:

We look at superspreading in infectious disease transmission from a statistical point of view. We characterise heterogeneity in the offspring distribution by the Gini coefficient instead of the usual dispersion parameter of the negative binomial distribution. This allows us to consider more flexible offspring distributions.

<center>
<img src="{{ site.baseurl }}/figure/source/2020-05-31-superspreader/PLOTMODIFIEDLORENZ-1.png" width="550">
</center>

{% include license.html %}

## Motivation

The recent Science report on [Superspreading during the COVID-19 pandemic](https://www.sciencemag.org/news/2020/05/why-do-some-covid-19-patients-infect-many-others-whereas-most-don-t-spread-virus-all) by Kai Kupferschmidt has made the dispersion parameter $k$ of the negative binomial distribution a hot quantity[^1] in the discussions of how to determine effective interventions. This short blog post aims at understanding the math behind statements such as “Probably about 10% of cases lead to 80% of the spread” and replicate them with computations in [R](https://www.r-project.org). 

**Warning**: This post reflects more my own learning process of what is superspreading than trying to make any statements of importance.

## Superspreading

@lloydsmith_etal2005 show that the 2002-2004 SARS-CoV-1 epidemic was driven by a small number of events where one case directly infected a large number of secondary cases - a so called superspreading event. This means that for SARS-CoV-1 the distribution of how many secondary cases each primary case generates is heavy tailed. More specifically, the [effective reproduction number](https://staff.math.su.se/hoehle/blog/2020/04/15/effectiveR0.html) describes the mean number of secondary cases a primary case generates during the outbreak, i.e. it is the mean of the offspring distribution. In order to address dispersion around this mean, @lloydsmith_etal2005 use the [negative binomial distribution](https://en.wikipedia.org/wiki/Negative_binomial_distribution) with mean $R(t)$ and over-dispersion parameter $k$ as a probability model for the offspring distribution. The number of offspring that case $i$, which got infected at time $t_i$, causes is given by
$$
Y_{i} \sim \operatorname{NegBin}(R(t_i), k),
$$
s.t. $\operatorname{E}(Y_{i}) = R(t_i)$ and $\operatorname{Var}(Y_{i}) = R(t_i) (1 + \frac{1}{k} R(t_i))$. This parametrisation makes it easy to see that the negative binomial model has an additional factor $1 + \frac{1}{k} R(t_i)$ for the variance, which allows it to have excess variance (aka. over-dispersion) compared to the Poisson distribution, which has $\operatorname{Var}(Y_{i}) = R(t_i)$. If $k\rightarrow \infty$ we get the Poisson distribution and the closer $k$ is to zero the larger the variance, i.e. the heterogeneity, in the distribution is. Note the deliberate use of the effective reproduction number $R(t_i)$ instead of the basic reproduction number $R_0$ (as done in @lloydsmith_etal2005) in the model. This is to highlight, that one is likely to observe clusters in the context of interventions and depletion of susceptibles.

That the dispersion parameter $k$ is making epidemiological fame is a little surprising, because it is a parameter in a specific parametric model. A parametric model, which might be inadequate for the observed data. A secondary objective of this post is thus to focus more on describing the heterogeneity of the offspring distribution using classical statistical concepts such as the [**Gini coefficient**](https://en.wikipedia.org/wiki/Gini_coefficient).

## Negative binomial distributed number of secondary cases


Let's assume $k=0.45$ as done in @adam_etal2020. This is a slightly higher estimate than the $k=0.1$ estimate by @endo_etal2020[^2] quoted in the Science article. We want to derive statements like "the x% most active spreaders infected y% of all cases" as a function of $k$. The PMF of the offspring distribution with mean 2.5 and dispersion 0.45 looks as follows:

```r
Rt <- 2.5
k  <- 0.45 

# Evaluate on a larger enough grid, so E(Y_t) is determined accurate enough
# We also include -1 in the grid to get a point (0,0) needed for the Lorenz curve
df <- data.frame(x=-1:250) %>% mutate(pmf= dnbinom(x, mu=Rt, size=k))
```
<img src="{{ site.baseurl }}/figure/source/2020-05-31-superspreader/PMFNEGBIN-1.png" style="display: block; margin: auto;" />

So we observe that 43% of the cases never manage to infect a secondary case, whereas some cases manage to generate more than 10 new cases. The mean of the distribution is checked empirically to equal the specified $R(t)$ of 2.5:

```r
sum(df$x * df$pmf)
```

```
## [1] 2.5
```

@lloydsmith_etal2005 define a **superspreader** to be a primary case, which generates more secondary cases than the 99th quantile of the Poisson distribution with mean $R(t)$. We use this to compute the proportion of superspreaders in our distribution:


```r
(superspreader_threshold <- qpois(0.99, lambda=Rt))
```

```
## [1] 7
```

```r
(p_superspreader <- pnbinom(superspreader_threshold, mu=Rt, size=k, lower.tail=FALSE))
```

```
## [1] 0.09539277
```

So 10% of the cases will generate more than 7 new cases. To get to statements such as "10% generate 80% of the cases" we also need to know how many cases those 10% generate out of the 2.5 average. 


```r
# Compute proportion of the overall expected number of new cases
df <- df %>% mutate(cdf = pnbinom(x, mu=Rt, size=k), 
                    expected_cases=x*pmf, 
                    prop_of_Rt=expected_cases/Rt,
                    cum_prop_of_Rt = cumsum(prop_of_Rt))

# Summarise
info <- df %>% filter(x > superspreader_threshold) %>% 
  summarise(expected_cases = sum(expected_cases), prop_of_Rt = sum(prop_of_Rt))
info
```

```
##   expected_cases prop_of_Rt
## 1       1.192786  0.4771144
```
In other words, the superspreaders generate  (on average) 1.19 of the 2.5 new cases of a generation, i.e. 48%.

These statements can also be made without formulating a superspreader threshold by graphing the cumulative share of the distribution of primary cases against the cumulative share of secondary cases these generate. This is exactly what the [Lorenz curve](https://en.wikipedia.org/wiki/Lorenz_curve) is doing. However, for outbreak analysis it appears clearer to graph the cumulative distribution in decreasing order of the number of offspring, i.e. following @lloydsmith_etal2005 we plot the cumulative share as $P(Y\geq y)$ instead of $P(Y \leq y)$. This is a variation of the Lorenz curve, but allows statements such as "the %x cases with highest number of offspring generate %y of the secondary cases".


```r
# Add information for plotting the modified Lorenz curve
df <- df %>% 
  mutate(cdf_decreasing = pnbinom(x-1, mu=Rt, size=k, lower.tail=FALSE)) %>%
  arrange(desc(x)) %>%  
  mutate(cum_prop_of_Rt_decreasing = cumsum(prop_of_Rt))
```


```r
# Plot the modified Lorenz curve as in Fig 1b of Lloyd-Smith et al. (2005)
ggplot(df, aes(x=cdf_decreasing, y=cum_prop_of_Rt_decreasing)) + geom_line() + 
  coord_cartesian(xlim=c(0,1)) + 
  xlab("Proportion of the infectious cases (cases with most secondary cases first)") + 
  ylab("Proportion of the secondary cases") +
  scale_x_continuous(labels=scales::percent, breaks=seq(0,1,length=6)) +
  scale_y_continuous(labels=scales::percent, breaks=seq(0,1,length=6)) +
  geom_line(data=data.frame(x=seq(0,1,length=100)) %>% mutate(y=x), aes(x=x, y=y), lty=2, col="gray") + ggtitle(str_c("Scenario: R(t) = ", Rt, ", k = ", k))
```

<img src="{{ site.baseurl }}/figure/source/2020-05-31-superspreader/PLOTMODIFIEDLORENZ-1.png" style="display: block; margin: auto;" />

Using the standard formulas to compute the [Gini coefficient](https://en.wikipedia.org/wiki/Gini_coefficient#Discrete_probability_distribution) for a discrete distribution with support on the non-negative integers, i.e. 
$$
G = \frac{1}{2\mu} \sum_{y=0}^\infty \sum_{z=0}^\infty f(y) f(z) |y-z|,
$$
where $f(y)$, $y=0,1,\ldots$ denotes the PMF of the distribution and $\mu=\sum_{y=0}^\infty y f(y)$ is the mean of the distribution. In our case $\mu=R(t)$. From this we get


```r
# Gini index for a discrete probability distribution
gini_coeff <- function(df) {
  mu <- sum(df$x * df$pmf)
  sum <- 0
  for (i in 1:nrow(df)) {
    for (j in 1:nrow(df)) {
      sum <- sum + df$pmf[i] * df$pmf[j] * abs(df$x[i] - df$x[j])
    }
  }
  return(sum/(2*mu))
}

gini_coeff(df)  
```

```
## [1] 0.704049
```

A plot of the relationship between the dispersion parameter and the Gini index, given a fixed value of $R(t)=2.5$, looks as follows
<img src="{{ site.baseurl }}/figure/source/2020-05-31-superspreader/PLOTGINIKRELATIONSHIP-1.png" style="display: block; margin: auto;" />

We see that the Gini index converges from above to the Gini index of the Poisson distribution with mean $R(t)$. In our case this limit is

```r
gini_coeff( data.frame(x=0:250) %>% mutate(pmf = dpois(x, lambda=Rt)))
```

```
## [1] 0.3475131
```

### Red Marble Toy Example
For the [toy example offspring distribution](https://youtu.be/fOHB6PtcoMU?t=1259) used by [Christian Drosten](https://twitter.com/c_drosten) in his Coronavirus Update podcast episode 44 on COVID-19 superspreading (in German).
The described hypothetical scenario is translated to an offspring distribution, where a primary case either generates 1 (with probability 9/10) or 10 (with probability 1/10) secondary cases:


```r
# Offspring distribution
df_toyoffspring <- data.frame( x=c(1,10), pmf=c(9/10, 1/10))

# Hypothetical outbreak with 10000 cases from this offspring distribution
y_obs <- sample(df_toyoffspring$x, size=10000, replace=TRUE, prob=df_toyoffspring$pmf)

# Fit the negative binomial distribution to the observed offspring distribution
# Note It would be better to fit the PMF directly instead of to the hypothetical
# outbreak data
(fit <- MASS::fitdistr(y_obs, "negative binomial"))
```

```
##       size          mu    
##   1.69483494   1.90263640 
##  (0.03724779) (0.02009563)
```

```r
# Note: different parametrisation of the k parameter
(k.hat <- 1/fit$estimate["size"])
```

```
##     size 
## 0.590028
```

In other words, when fitting a negative binomial distribution to these data (probably not a good idea) we get a dispersion parameter of 0.59. 
<img src="{{ site.baseurl }}/figure/source/2020-05-31-superspreader/PLOTNEGBINTOYPMF-1.png" style="display: block; margin: auto;" />

The Gini coefficient allows for a more sensible description for offspring distributions, which are clearly not negative-binomial. 

```r
gini_coeff(df_toyoffspring) 
```

```
## [1] 0.4263158
```


## Discussion

The effect of superspreaders underlines the stochastic nature of the dynamics of an person-to-person transmitted disease in a population. The dispersion parameter $k$ is conditional on the assumption of a given parametric model for the offspring distribution (negative binomial). The Gini index is an alternative characterisation to measure heterogeneity. However, in both cases the parameters are to be interpreted together with the expectation of the distribution. Estimation of the dispersion parameter is orthogonal to the mean in the negative binomial and its straightforward to also get confidence intervals for it. This is less straightforward for the Gini index. 

A heavy tailed offspring distribution can make the disease easier to control by
targeting intervention measures to restrict superspreading [@lloydsmith_etal2005]. The hope is that such interventions are "cheaper" than interventions which target the entire population of infectious contacts. However, the success of such a targeted strategy also depends on how large the contribution of superspreaders really is. Hence, some effort is needed to quantify the effect of superspreaders. Furthermore, the above treatment also underlines that heterogeneity can be a helpful feature to exploit when trying to control a disease. Another aspect of such heterogeneity, namely its influence on the threshold of herd immunity, has recently been invested by my colleagues at Stockholm University [@britton_etal2020]. 


[^1]: To be added to the list of characterising quantities such as doubling time, reproduction number, generation time, serial interval, ...
[^2]: @lloydsmith_etal2005 estimated $k=0.16$ for SARS-CoV-1.

## Literature


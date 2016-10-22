---
layout: post
title: "More Confidence in Intervals for Quantiles"
tags: [dataviz, rstats, stats]
bibliography: ~/Literature/Bibtex/jabref.bib
comments: true
---


$$
\newcommand{\bm}[1]{\boldsymbol{\mathbf{#1}}}
\DeclareMathOperator*{\argmin}{arg\,min}
\DeclareMathOperator*{\argmax}{arg\,max}
$$

## Abstract

We discuss how to compute compute intervals for the median or any
other quantile in R. In particular we are interested in the
interpolated order statistic approach as suggested by
@hettmansperger_sheather1986 and @nyblom1992. These suggestions
compute intervals that have very good coverage close to the nominal
level even in the small sample setting. A (tiny) R package
`quantileCI` is written implementing them in order to make the methods
available to a greater audience. A small simulation study is conducted
to show that these intervals have a coverage closer to the nominal level.

<center>
![]({{ site.baseurl }}/figure/source/2016-10-17-quantileCI/FIRSTPICTURE-1.png )
</center>

{% include license.html %}

## Introduction

Statistics 101 teaches that for a distribution, possibly contaminated with outliers, a robust measure of the central tendency is the median. Not knowing this fact can even make your analysis worthy to report in a [(German) newspaper](http://www.sueddeutsche.de/wirtschaft/heilbronn-dieser-mann-ist-so-reich-dass-statistiken-seines-wohnorts-wertlos-sind-1.2705044).

Higher quantiles of a distribution also have a long history as threshold for when to declare an observation to be an outlier. For example, growth curves for children illustrate how the quantiles of, e.g., [the BMI distribution develops by age](http://www.cdc.gov/growthcharts/data/set1clinical/cj41l024.pdf). **Obesity** is then for children defined as exceedance of the [97.7% quantile](http://www.who.int/growthref/bmifa_girls_z_5_19_labels.pdf?ua=1) of the distribution at a particular age. Quantile regression is a non-parametric method to compute such curves and the statistical community has been quite busy lately investigating new ways to compute such quantile regressions models.

The focus of this blog post is nevertheless the simplest setting: Given an iid. sample $\bm{x}$ of size $n$ from a univariate and absolutely continuous distribution $F$, how does one compute an estimate for the $p$-Quantile of $F$ together with a corresponding confidence interval for it?

### The Point Estimate

Computing the quantile in a sample with statistical software is discussed in the excellent survey of @hyndman_fan1996. The simplest estimator is based on the [order statistic](https://en.wikipedia.org/wiki/Order_statistic) of the sample, i.e. $x_{(1)} < x_{(2)} < \cdots < x_{(n)}$.
$$
\hat{x}_p = \min_{k} \left\{\hat{F}(x_{(k)}) \geq p\right\} = x_{(\lceil n \cdot p\rceil)},
$$
where $\hat{F}$ is the (empirical cumulative distribution)[https://en.wikipedia.org/wiki/Empirical_distribution_function] function of the sample. Since $\hat{F}$ has jumps of size $1/n$ the actual value of $\hat{F}(\hat{x}_{p})$ can actually be somewhat larger than the desired $p$. Therefore,
 @hyndman_fan1996 prefers estimators interpolating between the two values of the order statistic with $\hat{F}$ just below and just above $p$. It is interesting that even [20 years after](http://robjhyndman.com/hyndsight/sample-quantiles-20-years-later/), there still is no universally accepted way to do this in different statistical software and the `type` argument of the `quantile` function in R has been a close friend when comparing results with SPSS or Stata users. In what follows we will, however, stick with the simple $x_{(\lceil n \cdot p\rceil)}$ estimator stated above.

Below is illustrated how one would use R to compute the empirical, say, 80% quantile of a sample:


```r
##Make a tiny artificial dataset, say, it's the BMI z-score of 25 children
sort(x <- rnorm(25))
```

```
##  [1] -1.44090165 -1.40318433 -1.21953433 -0.95029549 -0.90398754 -0.66095890 -0.47801787
##  [8] -0.43976149 -0.36174823 -0.34116984 -0.33047704 -0.31576897 -0.28904542 -0.03789851
## [15] -0.03764990 -0.03377687  0.22121130  0.30331291  0.43716773  0.47435054  0.60897987
## [22]  0.64611097  1.20086374  1.52483138  2.67862782
```

```r
##Define the quantile we want to consider
p <- 0.8
##Since we know the true distribution we can easily find the true quantile
(x_p <- qnorm(p))
```

```
## [1] 0.8416212
```
We can now compute the estimate for the $p$-quantile in the population either manually or using the `quantile` function with `type=1`:

```r
c(quantile=quantile(x, type=1, prob=p), manual=sort(x)[ceiling(length(x)*p)])
```

```
## quantile.80%       manual 
##    0.4743505    0.4743505
```

### Confidence interval for the quantile

Besides the point estimate $\hat{x}_p$ we also would like to report a $(1-\alpha)\cdot 100\%$ confidence interval $(x_p^{\text{l}}, x_p^{\text{u}})$ for the desired population quantile. The interval $(x_p^{\text{l}}, x_p^{\text{u}})$ should, hence, fulfill the following condition:
$$
P( (x_p^{\text{l}}, x_p^{\text{u}}) \ni x_p) = 1 - \alpha,
$$
where we have used the "backwards" $\in$ to stress the fact that it's the interval which is random. Restricting the limits of this confidence intervals to be one of the realisations from the order statistics implies that we need to find indices $d$ and $e$ with $d<e$ s.t.
$$
P( x_{(d)} \leq x_p \leq x_{(e)}) \geq 1 - \alpha.
$$
Note that it may not be possible to achieve the desired coverage exactly in this case. For now we prefer the conservative choice of having to attain **at least** the desired coverage. Note that for $1\leq r \leq n$ we have
$$
\begin{align*}
P( x_{r} \leq x_p) &= P(\text{at least $r$ observations are smaller than or equal to $x_p$}) \\
      &= \sum_{k=r}^{n} P(\text{exactly $k$ observations are smaller than or equal to $x_p$}) \\
      &= \sum_{k=r}^{n} {n \choose k} P(X \leq x_p)^k (1-P(X \leq x_p))^{n-k} \\
      &= \sum_{k=r}^{n} {n \choose k} p^k (1-p)^{n-k} \\
      &= 1 - \sum_{k=0}^{r-1} {n \choose k} p^k (1-p)^{n-k}
\end{align*}
$$
In principle, we could now try out all possible $(d,e)$ combinations and for each interval investigate, whether it has the desired $\geq 1-\alpha/2$ property. If several combinations achieve this criterion we would, e.g., take the interval having minimal length. This is what the `MKmisc::quantileCI` function does. However, the number of pairs to investigate is of order $O(n^2)$, which for large $n$ quickly becomes lengthy to compute. Instead, we compute an **equi-tailed confidence interval** by finding two one-sided $1-\alpha/2$ intervals, i.e. we find $d$ and $e$ s.t. $P(x_{(d)} \leq x_p) = 1-\alpha/2$ and
$P(x_p \geq x_{(e)}) = 1-\alpha/2$. In other words,

$$
\begin{align*}
d &= \argmax P(x_{(r)} \leq x_p) \geq 1 - \frac{\alpha}{2} \\
  &= \texttt{qbinom(alpha/2, size=n, prob=p)} \\
e &= \argmin P(x_p \geq x_{(r)}) \geq 1 - \frac{\alpha}{2} \\
  &= \texttt{qbinom(1-alpha/2, size=n, prob=p) + 1}
\end{align*}
$$

Note that the problem can arise, that the above solutions are zero or
$n+1$, respectively. In this case one has to decide how to
proceed. For an illustration of the above in case of the median see
the [post ](http://freakonometrics.hypotheses.org/4199) by
[\@freakonometrics](https://twitter.com/freakonometrics).

When it comes to confidence interval for quantiles the set of alternative implementations in R is extensive. Searching for this on CRAN,  we found the following functionality:



| Package::Function   |  Version | Description                                            |
|---------------------|:--------:|--------------------------------------------------------|
| [`MKMisc::quantileCI`](http://finzi.psych.upenn.edu/R/library/MKmisc/html/quantileCI.html)| 0.993 | Implements an exact but very slow $O(n^2)$ search as well as an asymptotic method approximating the exact procedure. Do to the method being slow it is not investigated further. |
|   |   |  |
| [`jmuOutlier::quantileCI`](http://finzi.psych.upenn.edu/R/library/jmuOutlier/html/quantileCI.html)  |  1.1  | Implements the exact method. |
|   |   |  |
| [`envStats::eqnpar`](http://finzi.psych.upenn.edu/R/library/EnvStats/html/eqnpar.html)  | 2.1.1 | implements both an exact and an asymptotic interval  |
|   |   |  |
| [`asht::quantileTest`](http://finzi.psych.upenn.edu/R/library/asht/html/quantileTest.html)| 0.6 | also implements an exact method |
|   |   |  |
| [`Qtools::confint.midquantile`](http://finzi.psych.upenn.edu/R/library/Qtools/html/confint.midquantile.html) | 1.1 | operates on the mid-quantile (whatever that is). The method is not investigated further.
|   |   |  |
<p>



```r
as.numeric(MKmisc::quantileCI(x=x, prob=p, method="exact",conf.level=0.95)$CI)
as.numeric(MKmisc::quantileCI(x=x, prob=p, method="asymptotic",conf.level=0.95)$CI)
as.numeric(jmuOutlier::quantileCI(x=x, probs=p, conf.level=0.95)[1,c("lower","upper")])
as.numeric(EnvStats::eqnpar(x=x, p=p, ci=TRUE, ci.method="exact",approx.conf.level=0.95)$interval$limits)
as.numeric(EnvStats::eqnpar(x=x, p=p, ci=TRUE, ci.method="normal.approx",approx.conf.level=0.95)$interval$limits)
as.numeric(asht::quantileTest(x=x,p=p,conf.level=0.95)$conf.int)
```

```
## [1] -0.03377687  1.52483138
## [1] -0.03377687  1.52483138
## [1] -0.03377687  1.52483138
## [1] 0.2212113 2.6786278
## [1] -0.03377687  1.52483138
## [1] -0.03377687  2.67862782
```

An impressive number of similar, but yet, different results! To add to the confusion here is
our take at this as developed in the `quantileCI` package available from github:


```r
devtools::install_github("hoehleatsu/quantileCI")
```

The package provides three methods for computing confidence intervals for quantiles:

```r
quantileCI::quantile_confint_nyblom(x=x, p=p, conf.level=0.95,interpolate=FALSE)
quantileCI::quantile_confint_nyblom(x=x, p=p, conf.level=0.95,interpolate=TRUE)
quantileCI::quantile_confint_boot(x, p=p, conf.level=0.95,R=999, type=1)
```

```
## [1] -0.03377687  2.67862782
## [1] 0.07894831 1.54608644
## [1] -0.0376499  1.2008637
```

The first procedure with `interpolate=FALSE` implements the previously
explained exact approach, which is also implemented in some of the
other packages. However, when the `interpolate` argument is set to
`TRUE` (the default), an additional interpolation step between the two neighbouring order statistics is performed as suggested in the work of @nyblom1992, which extends work for the median by @hettmansperger_sheather1986. The last call in the above is to a basic bootstrap procedure, which resamples the data with replacement, computes the quantile using `type=1` and then reports the 2.5% and 97.5% percentiles of this bootstrapped distribution. Such percentiles of the basic bootstrap are a popular way to get confidence intervals for the quantile, e.g., this is what we have used in @hoehle_hoehle2009 for reporting robust accuracy measures of digital elevation models (DEMs). However, the bootstrap procedure is
not without problems (@someref).

## Small Simulation Study to Determine Coverage



We write a function, which for a given sample `x` computes two-sided confidence intervals for the p-Quantile using a selection of the above described procedures:

```r
quantile_confints(x, p=p, conf.level=0.95)
```

```
##   jmuOutlier_exact EnvStats_exact EnvStats_asymp asht_quantTest nyblom_exact
## 1      -0.03377687      0.2212113    -0.03377687    -0.03377687  -0.03377687
## 2       1.52483138      2.6786278     1.52483138     2.67862782   2.67862782
##   nyblom_interp        boot
## 1    0.07894831 -0.03377687
## 2    1.54608644  1.26565726
```

In order to evaluate the various methods and implementations we
conduct a Monte Carlo simulation study to assess each methods'
coverage. For this purpose we write a small wrapper function to
conduct the simulation study using parallel computation (see, e.g.,
this
[tutorial post](http://gforge.se/2015/02/how-to-go-parallel-in-r-basics-tips/)
on parallel computation). The function wraps the the
`quantileCI::qci_coverage_one_sim` function, which lets the user
define a simulation scenario (true underlying distribution, size of
the sample, etc.), then applies all confidence interval methods gathered in the above mentioned `quantile_confints` and finally assesses whether each confidence interval covers the true value or not.


```r
simulate.coverage_qci <- function(n=n,p=p,conf.level=0.9, nSim=10e3, ...) {
  ##Windows users: change to below lapply function or use snow.
  ##lapplyFun <- function(x, mc.cores=NA, ...) pblapply(x, ...)
  lapplyFun <- parallel::mclapply

  sims <- dplyr::bind_rows(
    lapplyFun(1L:nSim, function(i) {
      quantileCI::qci_coverage_one_sim(qci_fun=quantile_confints, n=n,p=p,conf.level=conf.level,...)
    }, mc.cores = parallel::detectCores() - 1)
  ) %>% summarise_each(funs(mean))
  return(sims)
}
```

We can now compare the coverage of the different implementation for the particular `n`=25 and `p`=0.8 setting:

```r
simulate.coverage_qci(n=25, p=0.8, conf.level=0.95)
```

```
##   jmuOutlier_exact EnvStats_exact EnvStats_asymp asht_quantTest nyblom_exact
## 1           0.9555         0.9472         0.9555         0.9782       0.9782
##   nyblom_interp   boot
## 1        0.9491 0.9207
```

Note that the
`nyblom_interp` procedure is closer to the nominal coverage than it's
exact cousin `nyblom_exact` and the worst results are obtained by the bootstrap percentile method.


```r
simulate.coverage_qci(n=11, p=0.5, conf.level=0.95)
```

```
##   jmuOutlier_exact EnvStats_exact EnvStats_asymp asht_quantTest nyblom_exact
## 1           0.9893         0.9359         0.9648         0.9893       0.9893
##   nyblom_interp   boot hs_interp
## 1        0.9494 0.9359    0.9494
```

We note that the `EnvStats_exact` procedure has a lower coverage than
the nominal required level, it thus implements a slightly
different procedure than described above. That coverage is less than
the nominal for an *exact* method is, however, somewhat surprising.

In this study for the median, the original
@hettmansperger_sheather1986 procedure implemented in `quantileCI` as
function `median_confint_hs` is also included in the comparison
(`hs_interp`).  Note that the @nyblom1992 procedure for `p=0.5` just
boils down to this approach. Since the neighbouring order statistics
are combined using a weighted mean, the actual level is just close to
the nominal level. It can, as observed for the above setting, be
slightly lower than the nominal level. The bootstrap method again
doesn't look too impressive.

We finally also add one of the scenarios from Table 1 of the
@nyblom1992 paper, which allows us to check our implementation against
the numerical integration to assess coverage in the paper.


```r
simulate.coverage_qci(n=11, p=0.25, conf.level=0.90)
```

```
##   jmuOutlier_exact EnvStats_exact EnvStats_asymp asht_quantTest nyblom_exact
## 1           0.9227         0.7629         0.8441         0.9227       0.9227
##   nyblom_interp   boot
## 1        0.9012 0.8789
```

In particular the results of `EnvStats_exact` look disturbing.
Finally, a setup with a large sample, but now with the t-distribution
with one degree of freedom:


```r
simulate.coverage_qci(n=101, p=0.9, rfunc=rt, qfunc=qt, conf.level=0.95, df=1)
```

```
##   jmuOutlier_exact EnvStats_exact EnvStats_asymp asht_quantTest nyblom_exact
## 1           0.9558         0.9375         0.9558         0.9558       0.9558
##   nyblom_interp   boot
## 1        0.9506 0.9348
```

Again the interpolation method provides the most convincing results.

# Conclusion and Future Work

Can we based on the above recommend one procedure to use in practice?
Well, even though the simulation study is small, the exact
`EnvStats::eqnpar` approach appears to yield below nominal coverage
intervals, sometimes even substantially. On the other hand,
`jmuOutlier_exact`, `asht_quantTest`, and `nyblom_exact` in all three
four cases provided above nominal level coverage (i.e. the intervals
are conservative in as much as they are too wide). Altogether, the
results of the exact confidence interval method varied somewhat
between the different R implementations. Part of the differences arise
from handling the discreteness of the procedure as well as the edge
cases. The basic bootstrap method is a simple approach, providing
acceptable, but not optimal coverage. In particular for very large $n$ or
for a large number of replication in the simulation study, the method
can be somewhat slow.

The @hettmansperger_sheather1986 and @nyblom1992 method, respectively,
appears to provide **very good coverage** close to the nominal
level. The method is fast to compute, available through the
`quantileCI` R package and would be our recommendation to use in
practice instead of the more conservative exact interval.


Altogether, we summarise our findings in the following illustration on
how to find 90% confidence intervals for the 80% quantile of the
standard normal distribution based on a sample of size $n$=25.


![](http://staff.math.su.se/hoehle/blog/figure/source/2016-10-17-quantileCI/FIRSTPICTURE-1.png)

# References



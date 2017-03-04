---
layout: post
title: "US Babyname Collisions 1880-2014"
tags: [rstats, stats, data journalism, onomastics]
bibliography: ~/Literature/Bibtex/jabref.bib
comments: true
---




## Abstract

We use US Social Security Administration data to compute the probability of a name clash in a class of year-YYYY born kids during the years 1880-2014.

<center>
![]({{ site.baseurl }}/figure/source/2017-03-01-morebabynames/COLLIDEPROBTS-1.png )
</center>

{% include license.html %}

## Introduction

After reading a cool post by [Kasia Kulma](https://kkulma.github.io/) on
how the release of [Disney films have an impact on girl namings in the
US](https://kkulma.github.io/2017-02-22-disney-names/), I became aware of the `babynames` package by Hadley Wickham. The package wraps the data by the
[USA social security administration](https://www.ssa.gov/oact/babynames/limits.html)
on the frequency of all baby names each year during the period 1880-2014 in the US. Because the data fit phenomenally in spirit to this blog's two previous posts on [onomastics](http://staff.math.su.se/hoehle/blog/2017/02/06/onomastics.html) and the [birthday problem with unequal probabilities](http://staff.math.su.se/hoehle/blog/2017/02/13/bday.html), we use the data to extend our name analyses in temporal fashion.



```r
library(babynames)
head(babynames,n=2)
```

```
## # A tibble: 2 × 5
##    year   sex  name     n       prop
##   <dbl> <chr> <chr> <int>      <dbl>
## 1  1880     F  Mary  7065 0.07238359
## 2  1880     F  Anna  2604 0.02667896
```

Check how many babies and how many unique first names are contained in the data each year:

```r
p1 <- babynames %>% group_by(year) %>% summarise(n=sum(n)) %>% ggplot(aes(x=year, y=n)) + geom_line() + xlab("Time (years)") + ylab("Number of babies")
p2 <- babynames %>% group_by(year) %>% summarise(n=n()) %>% ggplot(aes(x=year, y=n)) + geom_line() + xlab("Time (years)") + ylab("Number of unique names")
gridExtra::grid.arrange(p1, p2, ncol=2)
```

<img src="http://staff.math.su.se/hoehle/blog/figure/source/2017-03-01-morebabynames/UNIQUENAMES-1.png" style="display: block; margin: auto;" />

We see that the number of live-births remains at an *approximately* stable level the last 50 years, whereas the number of unique names kept increasing. Note that for reasons of privacy protection, only names with 5 or more occurrences in a given year, are contained in the data. We therefore investigate the proportion of babies, which apparently have been removed due to privacy protection of the names. This is done by investigating the sum of the proportions column for each year. If all names would be available, the sum per year would be 2 (1 for each gender).


```r
babynames %>% group_by(year) %>% summarise(prop=sum(prop)) %>% ggplot(aes(x=year, y=(2-prop)/2)) + geom_line() + xlab("Time (years)") + ylab("Proportion of the population removed") + scale_y_continuous(labels=scales::percent)
```

<img src="http://staff.math.su.se/hoehle/blog/figure/source/2017-03-01-morebabynames/PROPMISSING-1.png" style="display: block; margin: auto;" />
It becomes clear that a non-negligible part of the names are removed and the proportion appears to vary with time. As a simple fix, we re-scale the yearly proportions per year s.t. they really sum to one.


```r
babynames <- babynames %>% group_by(year) %>% mutate(p = n/sum(n))
```


### Birthday Problem with Unequal Occurrence Probabilities

The data are perfect for testing the
name-collision functionality from the previous
[Happy pbirthday class of 2016](http://staff.math.su.se/hoehle/blog/2017/02/13/bday.html) post. Since the writing of the post, the `pbirthday_up` function for computing the name collision probability, which is an instance of the birthday problem with unequal occurrence probabilities, has been assembled into a preliminary [`birthdayproblem`](https://github.com/hoehleatsu/birthdayproblem) R package available from github.


```r
devtools::install_github("hoehleatsu/birthdayproblem")
library(birthdayproblem)
```

We can now easily calculate for each year the probability that 2 or more kids in a class of $n\in \{20,25,30\}$ kids all born in a given year YYYY will have same first name:


```r
collision <- babynames %>% group_by(year) %>% do({
  n <- c(20L,25L,30L)
  p <- sapply(n, function(n) pbirthday_up(n=n, .$p ,method="mase1992")$prob)
  data.frame(n=n, p=p)
})
```
<img src="http://staff.math.su.se/hoehle/blog/figure/source/2017-03-01-morebabynames/COLLIDEPROBTS-1.png" style="display: block; margin: auto;" />

It looks like the name distribution has become more diverse
over time, since the collision probability reduces over time. However, some bias is to be expected due to the removal of names with frequencies below 5 in a given year.

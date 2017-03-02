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
on the frequency of all baby names each year during the period 1880-2014 in the US. For
reasons of privacy protection, only names with 5 or more occurrences in a given year, are contained in the data. 


```r
library(babynames)
```

Check how many unique names are contained in the data each year:

```r
babynames %>% group_by(year) %>% summarise(n=n()) %>% ggplot(aes(x=year, y=n)) + geom_line() + xlab("Time (years)") + ylab("Number of different names in the data")
```

<img src="http://staff.math.su.se/hoehle/blog/figure/source/2017-03-01-morebabynames/UNIQUENAMES-1.png" style="display: block; margin: auto;" />

We look at the proportion of babies, which apparently have been removed due to privacy protection of the names. This is done by investigating the sum of proportions for each year. If all names would be available, the sum would be 2 (1 for each gender).

<img src="http://staff.math.su.se/hoehle/blog/figure/source/2017-03-01-morebabynames/PROPMISSING-1.png" style="display: block; margin: auto;" />
It becomes clear that a non-negligible part of the data appear to have been removed. Due to these names being removed, we re-scale the yearly proportions s.t. they really sum to one.


```r
babynames <- babynames %>% group_by(year) %>% mutate(p = n/sum(n))
```


### Birthday Problem with Unequal Occurrence Probabilities

The data are perfect for testing the
name-collision functionality from the previous
[Happy pbirthday class of 2016](http://staff.math.su.se/hoehle/blog/2017/02/13/bday.html) post. Since the post, the `pbirthday_up` function for computing the name collision probability for the birthday problem with unequal occurrence probabilities, has been assembled into a preliminary `birthdayproblem` package.



We can now easily calculate for each year the probability that 2 or more kids in a class of $n\in \{20,25,30\}$ kids all born in a given year YYYY will have same first name:


<img src="http://staff.math.su.se/hoehle/blog/figure/source/2017-03-01-morebabynames/COLLIDEPROBTS-1.png" style="display: block; margin: auto;" />

It looks like the name distribution has become more diverse
over time, since the collision probability reduces over time. However, some bias is to be expected due to the removal of names with frequencies below 5 in a given year.

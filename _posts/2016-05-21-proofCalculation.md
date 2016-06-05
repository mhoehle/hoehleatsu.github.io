---
layout: post
title: "Right or Wrong? - Validate Numbers Like a Boss"
tags: [datascience, rstats, debugging]
comments: true
---



<br>
<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png"/></a><br/>
This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.

## Abstract

How does a statistician ensure that an analysis that comprises of outputting \\(M\\) results is
correct? Can this be done without manually checking each of the results? Some statistical
approaches for this task of **proof-calculation** are described -- e.g. capture-recapture
estimation and sequential decision making. 



# Introduction

One activity the public associates with **statistics** is the generation of large tables
containing a multitude of numbers on a phenomena of interest. Below an example containing the summary of [UK labour market statistics](https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/employmentandemployeetypes/bulletins/uklabourmarket/april2016) for the 3 months to February 2016 from the
Office for National Statistics:

![]({{ site.url }}/figure/source/2016-05-21-proofCalculation/unemployment-apr2016.png "Source: https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/employmentandemployeetypes/bulletins/uklabourmarket/april2016")

Another example is The German Federal Government’s [4th Report on Poverty and Wealth](http://www.bmas.de/DE/Service/Medien/Publikationen/a334-4-armuts-reichtumsbericht-2013.html). The report consists of a total of 549 pages with the pure table appendix fun starting on p. 518 including, e.g., age-adjusted ORs obtained from logistic regression modelling (p.523).

Even though dynamic report generation, graphical & interactive
visualizations have developed to a point making such tables
obsolete, this does not change the fact that the results still need to
be **correct**.  As a consequence, the results need to be validated to ensure
their correctness, sometimes even beyond any doubt! In what follow we
will use the term **result** to describe an output element of the
statistical analysis. In most cases results are numbers, but we shall
use the term number and result interchangeably. However, results
could also denote higher level output elements (e.g. tables, a
specific line in a graph).

Surprisingly, statistics students are taught very little on how to address such a problem
using what we do best: statistics. We teach about the median,
censoring & truncation, complex modelling and computer intensive inference methods. Maybe we even tell them about `knitr` as way to get the same results twice (a minimum requirement
to ensure correctness). However, spraying out numbers (even from the most beautiful model) is **not cool** if the initial data-munging went wrong or if your quotient is obtained by dividing with the wrong denominator .

The on-going discussion of **reproducible research** aims at the core of this problem: How to
ensure that your analysis re-producible and correct?
As modern statistics becomes more and more programming oriented it appears natural to seek inspiration from the discipline of **software testing**. Another entertaining branch is the concept of optimal **proofreading**. This dates back to the 1970-1980s,  where the problem is formulated as the search for an optimal stopping rules for the process of checking a text consisting of \\(M\\) words -- see for example Yang et al. (1982).
Periodically, the software development community re-visits these works -- for example by making it more accessible for computer scientists (Hayes, 2010).
Singpurwalla and Wilson (1999) give a thorough exposition of
treating uncertainty in the context of software engineering by 
interfacing between statistics and software engineering.

# Proofcalculation

The scientific method of choice to address validity is **peer
review**. This can go as far as having the reviewer implement the
analysis as a completely separate and independent process in order to
ensure that results agree. Reporting the results of clinical trials
have such independent implementations has part of the protocol. Such a
co-pilot approach fits nicely to the fact that real-life statistical
analysis rarely is a one-person activity anymore, but team work. There
might neither be a need nor resources to rebuild entire analyses, but
critical parts are nice to **double-check**.

Formalizing the task into mathematical notation let's assume the
report of interest consists of a total of \\(M\\) numbers. These numbers
would typically have a hierarchical structure, e.g., they relate to
various parts of the analysis or are part of individual tables.  Error
search is usually performed along the hierarchical structure.  Good
validation/proofcalculation strategies follow the principles of
software testing -- for example it may be worthwhile to remember
**Pareto's law**: 80 percent of the error are found in 20 percent of
the modules to test. Further hints on a well structured debugging
process can be found in Zeller (2009) where the quote on Pareto's law
is also from.

One crucial question is what exactly we mean by an **error**? A result
can be wrong, because of a bug in the code line computing it. Strictly
speaking **wrong** is just the (mathematical) black-and-white version
of the complex phenomena describing a misalignment between what is
perceived and what is desired by somebody. A more in-depth debate of
what's wrong is beyond the scope of this note, but there are
situations when a result is agreeably wrong. In the simplest case this
could be due to erroneous counting of the number of elements forming
the denominator of a ratio \\(x/y\\). More complicated cases could be the
use of a wrong regression model compared to what was described in the
methodology section (e.g. use of an extra unintended covariate). Even
worse are problems in the data-prepossessing step resulting in a wrong
data foundation and, hence, invalidating a large part of the
results. Altogether, a result be wrong in more than at the same time
and one error can invalidate several results. The \\(M\\) results are just
the final output -- what matters is what happens along your **analysis
pipeline**. Detecting a wrong result is thus merely a symptom of a
flawed pipeline. Isolating and fixing the bug causing the
error does not necessarily ensure that the number is correct then. 

We summarise the above discussion by making the following 
simplifying abstractions:

* The number of results which is wrong is a function of the number of errors \\(M\\). One error invalidates at least one result, but it can invalidate several jointly and errors can overlap thus invalidating the same number.

* We deliberately keep the definition of an error vague, but mean a mechanism which causes a result to be wrong. The simplest form of a result is a number. The simplest error is a number which is wrong.

* The hierarchical structure of the numbers and the intertwined code generating them is ignored. Instead, we simply assume there are \\(M\\) errors and assume that these errors are independent of each other.

We shall now describe an estimation approach a decision theoretic approach for the problem.

# Team Based Validation

Consider the situation where a team of two statisticians together validate the same report consisting of \\(M\\) numbers. Say the team use a fixed amount of time (e.g. one day)
trying to find as many errors in the numbers as possible. During the test period no errors are fixed -- this happens only after the end of the period. Let's assume that
 during the test period the two statistician found \\(n_1\\) and \\(n_2\\) wrong numbers,
respectively. Let \\(n_{11}\\) be the number of wrong numbers which were found by both statisticians. 

We  summarise the findings in the following alternative representation: Let \\(f_i, i=1,2\\) be the number of wrong numbers found by \\(i\\) of the testers, i.e.

$$
\begin{aligned}
f_1 &=(n_1-n_{11})+(n_2-n_{11})\\
f_2 &= n_{11}.
\end{aligned}
$$

These are the wrong numbers found by only one of the testers and by both testers, respectively.
Let \\(S=f_1+f_2\\) be the total number of erroneous numbers found in the test phase. Assuming that we in the subsequent debugging phase
are able to remove all these \\(S\\) errors, we are interested in estimating the number of remaining errors, i.e. \\(f_0\\) or, alternatively, the total number of errors \\(M=S+f_0\\).

Assume that during the 1 day of testing the result is as follows:


{% highlight r %}
testP <- data.frame(t(c(9,12,6)))
colnames(testP) <- c("01","10","11")
testP
{% endhighlight %}



{% highlight text %}
##   01 10 11
## 1  9 12  6
{% endhighlight %}
i.e. \\(n_1=9\\), \\(n_2=12\\) and \\(n_{11}=6\\). 
Hence, the total number of errors found so far is \\(S=27\\).

## Estimating the total number of wrong numbers

Estimating the total number of errors from the above data is a capture-recapture problem
with two time points (=sampling occasions).

### Lincoln-Petersen estimator
Under the simple assumption that the two statisticians are equally good at finding errors
and that the possible errors  have the same probability to be found (unrealistic?) a simple
capture-recapture estimate for the total number of errors is the so called [Lincoln-Petersen estimator](https://en.wikipedia.org/wiki/Mark_and_recapture#Lincoln.E2.80.93Petersen_estimator)):

$$
\hat{M} = \frac{n_1 \cdot n_2}{n_{11}}.
$$

Note that this estimator puts no upper-bound on \\(N\\). The estimator can be computed using, e.g., the [`CARE1`](https://cran.r-project.org/web/packages/CARE1/index.html) package:

{% highlight r %}
CARE1::estN.pair(testP)
{% endhighlight %}



{% highlight text %}
##  Petersen   Chapman        se       cil       ciu 
## 45.000000 42.428571  9.151781 32.259669 72.257758
{% endhighlight %}
This also provides a 95% confidence interval for \\(N\\) -- see the package documentation for details. To verify the computations one could alternatively compute the Lincoln-Petersen estimator manually:


{% highlight r %}
(Nhat <- (testP["01"]+testP["11"]) * (testP["10"]+testP["11"]) / testP["11"])
{% endhighlight %}



{% highlight text %}
##   01
## 1 45
{% endhighlight %}

Finally, an estimate on the number of errors left to find is \\(\hat{M}-S=18.0\\).

## Heterogeneous Sampling Probabilities

If one does not want to assume the equal catch-probabilities of the errors, a range of alternatives exists. One of them is the procedure by Chao (1984, 1987). Here, a non-parametric estimate of the total number of errors is given as:

$$
\hat{M} = S + \frac{f_1^2}{2 f_2}.
$$

An R implementation of the estimator is readily available as part of the [`SPECIES`](https://cran.r-project.org/web/packages/SPECIES/index.html) package.
For this, data first need to be stored as a table containing \\(f_1, f_2\\):

{% highlight r %}
testPaggr <- data.frame(j=1:2,n_j=as.numeric(c(sum(testP[1:2]),testP[3])))
testPaggr
{% endhighlight %}



{% highlight text %}
##   j n_j
## 1 1  21
## 2 2   6
{% endhighlight %}



{% highlight r %}
(N_est <- SPECIES::chao1984(testPaggr, conf=0.95))
{% endhighlight %}



{% highlight text %}
## $Nhat
## [1] 64
## 
## $SE
## [1] 22.78363
## 
## $CI
##      lb  ub
## [1,] 39 139
{% endhighlight %}
Again, estimator as well as a 95% confidence interval (based on a log-transform) are computed  -- see the package documentation for details.

<!-- ### Manual computation -->

<!-- Again, if the computation can of course also be done manually: -->
<!-- ```{r} -->
<!-- f <- testPaggr$n_j -->
<!-- S <- sum(f) -->
<!-- ceiling(S + f[1]^2/(2*f[2])) -->
<!-- ``` -->

# Knowing when to Stop

Whereas the above estimates are nice to know they give little guidance on how to decide between the two alternatives: continue validating numbers on day 2 or stop
the testing process and publish the report. We follow the work of Ferguson and Hardwick (1989) by solving the described sequential decision making problem within a decision theoretic framework: Let's assume that the cost of each round of proofcalculation costs an amount of \\(C_p>0\\) units and that each error undetected after \\(n\\) rounds of proofcalculation costs \\(c_n>0\\) units. Treating the total number of wrong results  \\(N\\) as a random variable and letting \\(X_1,\ldots,X_n\\), be the number of wrong results found in each of the proofcalculation rounds \\(1,\ldots,n\\), we know that \\(X_i\in N_0\\) and \\(\sum_{j=1}^n X_j \leq N\\). One then formulates the conditional expected loss after \\(n, n=0, 1, 2, \ldots,\\) rounds of proofcalculation as:

$$
Y_n = n C_p + c_n E(M_n|X_1,\ldots,X_n),
$$

where \\(M_n = M -(\sum_{j=1}^n X_j)\\).  If we further assume that in the \\((n+1)\\)'th proofcalculation round errors are detected independently of each other with probability \\(p_n, 0 \leq p_n \leq 1\\) and \\(p_n\\) being a known number we obtain that

$$
X_{n+1} \>|\> M, X_1,\ldots,X_n \sim \text{Bin}(M_n, p_n), \quad n=0,1,2,\ldots.
$$

Under the further assumption that \\(N\sim \text{Po}(\lambda)\\) with \\(\lambda>0\\) being known,  one can show that the loss function is independent of the observations (Ferguson and Hardwick, 1989), i.e.

$$
Y_n = n C_p + c_n \lambda \prod_{j=0}^{n-1} (1-p_j), \quad n=0,1,2,\ldots.
$$

The above Poisson assumption seems to be an acceptable approximation if the total number of results \\(M\\) is large and the probability of a result being wrong is low. In this case the optimal stopping rule is given as follows:

$$
n_{\text{stop}} = \min_{n\geq 0} Y_n.
$$

### Numerical example

We consider a setup where the costly errors have substantial ramifications and thus
are easy to detect early on. As time passes on the errors become
more difficult to detect. This is reflected by the subsequent choices of \\(p_n\\) and \\(c_n\\) -- see below. Furthermore, the expected number of bugs is taken to be the non-homogeneous capture-recapture estimate of the remaining errors. This coupling of the two procedures is somewhat pragmatic and ignores any uncertainty from the estimation stage.


{% highlight r %}
#Cost of one round of proofcalculation (say in number of working days)
Cp <- 1
#Cost of finding errors after n round of proofcalculation
cn <- function(n) 10*0.9^(2*(n+1))
#Expected number of errors
(lambda <- N_est$Nhat - sum(testP))
{% endhighlight %}



{% highlight text %}
## [1] 37
{% endhighlight %}



{% highlight r %}
#Probabilty of detecting an error in round j+1
pj <- function(j) {
  0.8^(j+1)
}
#Expected conditional loss as defined above
Yn <- Vectorize(function(n) {
  n*Cp + cn(n) * lambda * prod(1-pj(0:(n-1)))
})

#Make a data.frame with the results.
df <- data.frame(n=1:20) %>% mutate(Yn=Yn(n),cn=cn(n),pn=pj(n-1))
{% endhighlight %}

The above choice of parameters leads to the following functional forms:

![plot of chunk unnamed-chunk-7](http://hoehleatsu.github.io/figure/source/2016-05-21-proofCalculation/unnamed-chunk-7-1.png)



The optimal strategy is thus found as:

{% highlight r %}
df %>% filter(rank(Yn) == 1) %>% select(n,Yn)
{% endhighlight %}



{% highlight text %}
##   n       Yn
## 1 5 6.457426
{% endhighlight %}
In other words, one should test for \\(n_{\text{stop}}=5\\) rounds.

# Discussion

Is any of the above useful? 
Well, I have not heard about such approaches being used seriously in software engineering. The presented methods are more in the direction of  narrowing a complex problem down by assumptions in order to make the problem mathematically tractable. You may not agree with the assumptions as, e.g., Bolton (2010), yet, assumptions are a good way to get started. As long as they are made transparent.

The point is that statisticians appear to be very good at enlightening others about the virtues of statistics (repeat your measurements, have a sample plan, pantomimic act visualizing the horror of p-values, etc.). However, when it comes to our own analyses, we are surprisingly statistics-illiterate at times.


![]({{ site.url }}/figure/source/2016-05-21-proofCalculation/look_for_the_pattern-300px.png "Source: https://openclipart.org/detail/248382/dropping-numbers")

# Literature

* Bolton, M (2010). [Another Silly Quantitative Model](http://www.developsense.com/blog/2010/07/another-silly-quantitative-model/), Blog post, July 2010.

* Cook, JD (2010). [How many errors are left to find?](http://www.johndcook.com/blog/2010/07/13/lincoln-index/), Blog post, July 2010.

* Ferguson, TS and Hardwick JP (1989). [Stopping Rules For Proofreading](http://www.jstor.org/stable/3214037), J. Appl. Prob. 26:304-313.

* Hayes, B (2010). [The thrill of the chase](http://bit-player.org/2010/the-thrill-of-the-chase), Blog post, July 2010.

* Singpurwalla ND, Wilson SP (1999). [Statistical Methods in Software Engineering](http://www.springer.com/us/book/9780387988238), Springer.

* Yang MCK, Wackerly DD, Rosalsky A (1982). [Optimal Stopping Rules in Proofreading](http://www.jstor.org/stable/3213535),  Journal of Applied Probability
19(3), pp. 723-729

* Zeller, A (2009). [Why programs fail](http://www.whyprogramsfail.com/), Elsevier, 2009, 423 pages.

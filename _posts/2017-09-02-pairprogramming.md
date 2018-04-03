---
layout: post
title: "Pair Programming Statistical Analyses"
tags: [rstats, stats, quality]
bibliography: ~/Literature/Bibtex/jabref.bib
comments: true
---




## Abstract

Control calculation ping-pong is the process of iteratively
improving a statistical analysis by comparing results from two
independent analysis approaches until agreement. We use the `daff`
package to simplify the comparison of the two results and illustrate
its use by a case study with two statisticians ping-ponging an
analysis using dplyr and SQL, respectively.

<center>
![]({{ site.baseurl }}/figure/source/2017-09-02-pairprogramming/pingpong.png )
</center>
<br>
<FONT COLOR="bbbbbb">Clip art is based on work by
[Gan Khoon Lay](https://thenounproject.com/term/ping-pong/655102/)
available under a CC BY 3.0 US license.</FONT>

{% include license.html %}

## Introduction

If you are a statistician working in climate science, data driven
journalism, official statistics, public health, economics or any
related field working with *real* data, chances are that you have to
perform analyses, where you know there is zero tolerance for errors.
The easiest way to ensure the correctness of such an analysis is to
check your results over and over again (the **iterated 2-eye
principle**). A better approach is to pair-program the analysis by
either having a colleague read through your code (the **4-eye
principle**) or have a skilled colleague completely redo your analysis
from scratch using her favorite toolchain (the **2-mindset
principle**). Structured software development in the form of,
e.g. version control and unit tests, provides valuable inspiration on
how to ensure the quality of your code. However, when it comes to
pair-programming analyses, surprisingly many steps remain manual. The
`daff` package provides the equivalent of a `diff` statement on data
frames and we shall illustrate its use by automatizing the comparison
step of the control calculation ping-pong process.

## The Case Story

Ada and Bob have to calculate their country's quadrennial
official statistics on the total income and number of employed people
in
[fitness centers](https://www.destatis.de/DE/Publikationen/Qualitaetsberichte/Dienstleistungen/SonstDienstleistungsbereiche2010.pdf?__blob=publicationFile). A
sample of fitness centers is asked to fill out a questionnaire
containing their yearly sales volume, staff costs and number of
employees. The present exposition will for the sake of convenience
ignore the complex survey part of the problem and just pretend that the
sample corresponds to the population (complete inventory count).

### The Data

After the questionnaire phase, the following data are available to Ada
and Bob.

<table class="table table-striped" style="margin-left: auto; margin-right: auto;">
<thead><tr>
<th style="text-align:left;"> Id </th>
   <th style="text-align:right;"> Version </th>
   <th style="text-align:left;"> Region </th>
   <th style="text-align:right;"> Sales Volume </th>
   <th style="text-align:right;"> Staff Costs </th>
   <th style="text-align:right;"> People </th>
  </tr></thead>
<tbody>
<tr>
<td style="text-align:left;"> 01 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> A </td>
   <td style="text-align:right;"> 23000 </td>
   <td style="text-align:right;"> 10003 </td>
   <td style="text-align:right;"> 5 </td>
  </tr>
<tr>
<td style="text-align:left;"> 02 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> B </td>
   <td style="text-align:right;"> 12200 </td>
   <td style="text-align:right;"> 7200 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
<tr>
<td style="text-align:left;"> 03 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 19500 </td>
   <td style="text-align:right;"> 7609 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
<tr>
<td style="text-align:left;"> 04 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> A </td>
   <td style="text-align:right;"> 17500 </td>
   <td style="text-align:right;"> 13000 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
<tr>
<td style="text-align:left;"> 05 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> B </td>
   <td style="text-align:right;"> 119500 </td>
   <td style="text-align:right;"> 90000 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
<tr>
<td style="text-align:left;"> 05 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> B </td>
   <td style="text-align:right;"> 119500 </td>
   <td style="text-align:right;"> 95691 </td>
   <td style="text-align:right;"> 19 </td>
  </tr>
<tr>
<td style="text-align:left;"> 06 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> B </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 19990 </td>
   <td style="text-align:right;"> 6 </td>
  </tr>
<tr>
<td style="text-align:left;"> 07 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> A </td>
   <td style="text-align:right;"> 19123 </td>
   <td style="text-align:right;"> 20100 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
<tr>
<td style="text-align:left;"> 08 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> D </td>
   <td style="text-align:right;"> 25000 </td>
   <td style="text-align:right;"> 100 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
<tr>
<td style="text-align:left;"> 09 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> D </td>
   <td style="text-align:right;"> 45860 </td>
   <td style="text-align:right;"> 32555 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
<tr>
<td style="text-align:left;"> 10 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> E </td>
   <td style="text-align:right;"> 33020 </td>
   <td style="text-align:right;"> 25010 </td>
   <td style="text-align:right;"> 7 </td>
  </tr>
</tbody>
</table>

Here `Id` denotes the unique identifier of the sampled fitness center,
`Version` indicates the version of a center's questionnaire and
`Region` denotes the region in which the center is located. In case a
center's questionnaire lacks information or has inconsistent
information, the protocol is to get back to the center and have it
send a revised questionnaire. All Ada and Bob now need to do is
aggregate the data per region in order to obtain region stratified
estimates of:

* the overall number of fitness centres
* total sales volume
* total staff cost
* total number of people employed in fitness centres

However, the analysis protocol instructs that only fitness centers
with an annual sales volume larger than or equal to €17,500 are to be
included in the analysis. Furthermore, if missing values occur, they
are to be ignored in the summations. Since a lot of muscle will be
angered in case of errors, Ada and Bob agree on following the 2-mindset
procedure and meet after an hour to discuss their results. Here is what
each of them came up with.

### Ada

Ada loves the tidyverse and in particular `dplyr`. This is her solution:


```r
ada <- fitness %>% na.omit() %>% group_by(Region,Id) %>% top_n(1,Version) %>%
  group_by(Region) %>%
  filter(`Sales Volume` >= 17500) %>%
  summarise(`NoOfUnits`=n(),
            `Sales Volume`=sum(`Sales Volume`),
            `Staff Costs`=sum(`Staff Costs`),
            People=sum(People))
ada
```

```
## # A tibble: 4 x 5
##   Region NoOfUnits `Sales Volume` `Staff Costs` People
##   <chr>      <int>          <int>         <int>  <int>
## 1 A              3          59623         43103     16
## 2 B              1         119500         95691     19
## 3 D              1          45860         32555      9
## 4 E              1          33020         25010      7
```

### Bob

Bob has a dark past as a relational database management system (RDBMS)
developer and, hence, only recently experienced the joys of R. He
therefore chooses a no-SQL-server-necessary
[`SQLite` within R](https://www.r-bloggers.com/r-and-sqlite-part-1/)
approach. The hope is that in big data situation this might be a
little more speedy than base R:


```r
library(RSQLite)
## Create ad-hoc database
db <- dbConnect(SQLite(), dbname = file.path(filePath,"Test.sqlite"))
##Move fitness data into the ad-hoc DB
dbWriteTable(conn = db, name = "fitness", fitness, overwrite=TRUE, row.names=FALSE)
##Query using SQL
bob <- dbGetQuery(db, "
    SELECT Region,
           COUNT(*) As NoOfUnits,
           SUM([Sales Volume]) As [Sales Volume],
           SUM([Staff Costs]) AS [Staff Costs],
           SUM(People) AS People
    FROM fitness
    WHERE [Sales Volume] > 17500 GROUP BY Region
")
bob
```

```
##   Region NoOfUnits Sales Volume Staff Costs People
## 1   <NA>         1        19500        7609      2
## 2      A         2        42123       30103     13
## 3      B         2       239000      185691     19
## 4      D         2        70860       32655      9
## 5      E         1        33020       25010      7
```

*Update*: An alternative approach with less syntactic overhead would
have been the [`sqldf`](https://github.com/ggrothendieck/sqldf)
package, which has a standard SQLite backend and automagically handles
the import of the `data.frame` into the DB using the `RSQLite` pkg.


```r
##Load package
suppressPackageStartupMessages(library(sqldf))
##Ensure SQLite backend.
options(sqldf.driver = "SQLite")
##Same query as before
bob <- sqldf("
    SELECT Region,
           COUNT(*) As NoOfUnits,
           SUM([Sales Volume]) As [Sales Volume],
           SUM([Staff Costs]) AS [Staff Costs],
           SUM(People) AS People
    FROM fitness
    WHERE [Sales Volume] > 17500 GROUP BY Region
")
```

Even shorter is the
[direct use of SQL chunks](https://twitter.com/zevross/status/895663618158501888)
in knitr using the variable `db` as connection and using the chunk
argument `output.var=bob`:


```sql
SELECT Region,
       COUNT(*) As NoOfUnits,
       SUM([Sales Volume]) As [Sales Volume],
       SUM([Staff Costs]) AS [Staff Costs],
       SUM(People) AS People
FROM fitness
WHERE [Sales Volume] > 17500 GROUP BY Region
```

### The Ping-Pong Phase

After Ada and Bob each have a result, they compare their
resulting `data.frame` using the
[`daff`](https://cran.r-project.org/web/packages/daff/index.html)
package, which was recently presented by
[\@edwindjonge](https://twitter.com/edwindjonge) at the
[useR! 2017 conference](https://channel9.msdn.com/Events/useR-international-R-User-conferences/useR-International-R-User-2017-Conference/Daff-diff-patch-and-merge-for-dataframes).



```r
library(daff)
diff <- diff_data(ada, bob)
diff$get_data()
```

```
##    @@ Region NoOfUnits   Sales Volume   Staff Costs People
## 1 +++   <NA>         1          19500          7609      2
## 2  ->      A      3->2   59623->42123  43103->30103 16->13
## 3  ->      B      1->2 119500->239000 95691->185691     19
## 4  ->      D      1->2   45860->70860  32555->32655      9
## 5          E         1          33020         25010      7
```

After Ada's and Bob's serve, the two realize that their results just
agree for the region E.

*Note*: Currently, `daff` has the semi-annoying feature of not being
able to show all the diffs when printing, but just `n` lines of the
head and tail. As a consequence, for the purpose of this post, we
overwrite the printing function such that it always shows all rows
with differences.


```r
##Small helper function for better printing
print.data_diff <- function(x) x$get_data() %>% filter(`@@` != "")

diff %>% print()
```

```
##    @@ Region NoOfUnits   Sales Volume   Staff Costs People
## 1 +++   <NA>         1          19500          7609      2
## 2  ->      A      3->2   59623->42123  43103->30103 16->13
## 3  ->      B      1->2 119500->239000 95691->185691     19
## 4  ->      D      1->2   45860->70860  32555->32655      9
```

The two decide to first agree on the number of units per region.


```r
diff$get_data() %>% filter(`@@` != "") %>% select(`@@`, Region, NoOfUnits)
```

```
##    @@ Region NoOfUnits
## 1 +++   <NA>         1
## 2  ->      A      3->2
## 3  ->      B      1->2
## 4  ->      D      1->2
```

One obvious reason for the discrepancies appears to be that Bob has
results for an extra `<NA>` region. Therefore, Bob takes another look at his
management of missing values and decides to improve his code by:

#### Pong Bob

```sql
SELECT Region,
       COUNT(*) As NoOfUnits,
       SUM([Sales Volume]) As [Sales Volume],
       SUM([Staff Costs]) AS [Staff Costs],
       SUM(People) AS People
FROM fitness
WHERE ([Sales Volume] > 17500 AND REGION IS NOT NULL)
GROUP BY Region
```

```
##   @@ Region NoOfUnits   Sales Volume   Staff Costs People
## 1 ->      A      3->2   59623->42123  43103->30103 16->13
## 2 ->      B      1->2 119500->239000 95691->185691     19
## 3 ->      D      1->2   45860->70860  32555->32655      9
```

#### Ping Bob

Better. Now the `NA` region is gone, but still quite some differences
remain. *Note*: You may at this point want to stop reading and try
yourself to fix the analysis - the [data](https://github.com/hoehleatsu/hoehleatsu.github.io/blob/master/figure/source/2017-09-02-pairprogramming/fitness.csv) and [code](https://github.com/hoehleatsu/hoehleatsu.github.io/blob/master/_source/2017-09-02-pairprogramming.Rmd) are available from the
github repository.

#### Pong Bob

Now Bob notices that he forgot to handle the duplicate records and
apparently misunderstood the exact definition of the €17,500 exclusion limit.
His massaged SQL query looks as follows:



```sql
SELECT Region,
       COUNT(*) As NoOfUnits,
       SUM([Sales Volume]) As [Sales Volume],
       SUM([Staff Costs]) AS [Staff Costs],
       SUM(People) AS People
FROM (SELECT Id, MAX(Version), Region, [Sales Volume], [Staff Costs], People FROM fitness GROUP BY Id)
WHERE ([Sales Volume] >= 17500 AND REGION IS NOT NULL)
GROUP BY Region
```

```
##    @@ Region NoOfUnits Sales Volume  Staff Costs People
## 1 ...    ...       ...          ...          ...    ...
## 2  ->      D      1->2 45860->70860 32555->32655      9
```

#### Ping Ada

Comparing with Ada, Bob is sort of envious
that she was able to just use `dplyr`'s `group_by` and `top_n` functions.
However, `daff` shows that there still is one difference left. By
looking more carefully at Ada's code it becomes clear that she
accidentally leaves out one unit in region D. The reason is the too
liberate use of `na.omit`, which also removes the one entry with an
`NA` in one of the not so important columns. However, they discuss the
issue, if one really wants to include partial records or not, because
summation in the different columns then is over a different number of
units. After consulting with the standard operation procedure (SOP)
for these kind of surveys they decide to include the observation where
possible. Here is Ada's modified code:


```r
ada2 <- fitness %>% filter(!is.na(Region)) %>% group_by(Region,Id) %>% top_n(1,Version) %>%
  group_by(Region) %>%
  filter(`Sales Volume` >= 17500) %>%
  summarise(`NoOfUnits`=n(),
            `Sales Volume`=sum(`Sales Volume`),
            `Staff Costs`=sum(`Staff Costs`),
            People=sum(People))
(diff_final <- diff_data(ada2,bob3)) %>% print()
```

```
##    @@ Region NoOfUnits ... Staff Costs People
## 1 ...    ...       ... ...         ...    ...
## 2  ->      D         2 ...       32655  NA->9
```

#### Pong Ada
Oops, Ada forgot to take care of the `NA` in the summation:


```r
ada3 <- fitness %>% filter(!is.na(Region)) %>% group_by(Region,Id) %>% top_n(1,Version) %>%
  group_by(Region) %>%
  filter(`Sales Volume` >= 17500) %>%
  summarise(`NoOfUnits`=n(),
            `Sales Volume`=sum(`Sales Volume`),
            `Staff Costs`=sum(`Staff Costs`),
            People=sum(People,na.rm=TRUE))
diff_final <- diff_data(ada3,bob3)

##Check if the results really are the same
length(diff_final$get_data()) == 0
```

```
## [1] TRUE
```

Finally, their results agree and they move on to production and their
results are published in a
[nice report](https://www.destatis.de/DE/Publikationen/Thematisch/DienstleistungenFinanzdienstleistungen/KostenStruktur/KostenstrukturFitness2020163109004.pdf?__blob=publicationFile).

## Conclusion

As shown, the ping-pong game is quite manual and particularly
annoying, if at some point someone steps into the office with a
statement like *Btw, I found some extra questionnaires, which need to
be added to the analysis asap*. However, the two now aligned analysis
scripts and the corresponding daff-overlay could be put into a
script, which is triggered every time the data change. In case new
discrepancies emerge as `length(diff$get_data()) > 0`, the two could
then be automatically informed.

**Question 1**: Now the two get the same results, do you agree with
  them?


```
## # A tibble: 4 x 5
##   Region NoOfUnits `Sales Volume` `Staff Costs` People
##   <chr>      <int>          <int>         <int>  <int>
## 1 A              3          59623         43103     16
## 2 B              1         119500         95691     19
## 3 D              2          70860         32655      9
## 4 E              1          33020         25010      7
```

**Question 2**: Are you aware of any other good ways and tools to
  structure and automatize such a process? If so, please share your
  experiences as a Disqus comment below. Control calculations appear
  quite common, but little structured code support appears to be
  available for such processes.
<p>
<p>
<center>
![Daffodills](https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/A_Perfect_Pair_Daffodills_%28Narcissus%29_-_8.jpg/320px-A_Perfect_Pair_Daffodills_%28Narcissus%29_-_8.jpg)
</center>
<br>
<FONT COLOR="bbbbbb">Photo is copyright
[Johnathan J. Stegeman](https://en.wikipedia.org/wiki/Narcissus_(plant)#/media/File:A_Perfect_Pair_Daffodills_(Narcissus)_-_8.jpg)
under the [GNU Free Documentation License, version 1.2](https://commons.wikimedia.org/wiki/Commons:GNU_Free_Documentation_License,_version_1.2).</FONT>




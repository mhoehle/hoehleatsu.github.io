---
layout: post
title: "Did Mary and John go West?"
tags: [rstats, stats, data journalism, onomastics]
bibliography: ~/Literature/Bibtex/jabref.bib
comments: true
---




## Abstract

As a final post in the *baby-names-the-data-scientist's-way* series, we
use the US Social Security Administration 1910-2015 data to space-time
visualize for each the most popular baby name for girls and boys,
respectively. The code uses in parts the new simple features package
(`sf`) in order to to get some first experience with the package.

<center>
![]({{ site.baseurl }}/figure/source/2017-03-06-spacetimenames/US-babynames-spacetime.gif )
</center>

{% include license.html %}

## Introduction

After a series of posts on
[naming uncertainty](http://staff.math.su.se/hoehle/blog/2017/02/06/onomastics.html),
[name collisions in classrooms](http://staff.math.su.se/hoehle/blog/2017/02/13/bday.html)
and illustrating these
[name collisions over time](http://staff.math.su.se/hoehle/blog/2017/03/01/morebabynames.html),
it is time leave onomatology for now. However, the availability of the
US social security baby name data at
[state resolution](https://www.ssa.gov/oact/babynames/limits.html)
requires one last effort: visualizing the top names per state for the
years 1910-2015. Creating a map-based visualization also provides a
nice opportunity to experiment with the new `sf` (simple features)
package for spatial visualization.

## Data Dancing

We download the US social security data, which consists of a zip file
containing a bunch of 51 text files - one for each state.



We then read these individual text files and bind them together into one
large `data.frame`:

```r
##Get list of all file names containing state specific baby name data
fList <- list.files(path=file.path(filePath,"namesbystate"), pattern=".TXT")

##Read complete name list of each state
names <- purrr::map_df(fList, .f=function(f) {
  read_csv(file=file.path(filePath,"namesbystate",f), col_names=c("State","Sex","Year","Name","Count"),col_types=cols(col_character(), col_factor(c("M","F")), col_integer(), col_character(), col_integer()))
})

##Show result
head(names, n=4)
```

```
## # A tibble: 4 × 5
##   State    Sex  Year     Name Count
##   <chr> <fctr> <int>    <chr> <int>
## 1    AK      F  1910     Mary    14
## 2    AK      F  1910    Annie    12
## 3    AK      F  1910     Anna    10
## 4    AK      F  1910 Margaret     8
```

With the complete data in place, it's easy to compute the top
boy and girl name per state and year. For later use we convert this
information into long-format.


```r
##Find top-1 names for each state by gender. Data are already sorted.
topnames <- names %>% group_by(Year,State,Sex) %>% do({
  head(.,n=1) %>% dplyr::select(Name)
}) %>% spread(Sex, Name)
```

```
## Source: local data frame [4 x 4]
## Groups: Year, State [4]
## 
##    Year State     M     F
##   <int> <chr> <chr> <chr>
## 1  1910    AK  John  Mary
## 2  1910    AL James  Mary
## 3  1910    AR James  Mary
## 4  1910    AZ  John  Mary
```

## Map Massaging

For the map visualization we use an US map from the R package
[`fiftystater`](https://cran.r-project.org/web/packages/fiftystater/index.html)
where Alaska and Hawaii have been re-located as map-insets. The
process for doing the necessary transforms `sp`-style are described in
the package
[vignette](https://cran.r-project.org/web/packages/fiftystater/vignettes/fiftystater.html). We
store the output of this transformation as a shapefile `usa.shp` with
appropriate support files. Furthermore, a `lines.shp` shapefile was
created which contains information on where to put the text labels for
each state. This was easily edited interactively in
[QGIS](http://www.qgis.org/en/site/).

We then use the new `sf` package for loading these two shapefiles back
into R:

```r
suppressMessages(library("sf"))
usa <- st_read(file.path(filePath, "maps", "usa.shp"))
textplacement <- st_read(file.path(filePath, "maps", "lines.shp"))
```

The `textplacement` information is converted to a `data.frame` where
each row contains the state name and the coordinates of the start and
endpoint of each line-segment - this corresponds to text location and
geographical centroid of the region, respectively.


```r
location <- textplacement %>% split(.$State) %>% purrr::map_df(.f = function(x) {
  pos <- st_geometry(x)[[1]]
  data.frame(State=x$State, x1.loc=pos[1,1], x2.loc=pos[1,2], x1.center=pos[2,1],x2.center=pos[2,2])
}) %>% ungroup
```
(Note: Is there a fancier way to extract the coordinates for the
geometry of the `sf` objects while keeping the `data.frame` part
alongside?)



## State-Time Visualization

By using the `animation::saveGIF` function we create an animation of
the the top girl and boy name for each state for the sequence of years
1910-2015.




![]({{ site.baseurl }}/figure/source/2017-03-06-spacetimenames/US-babynames-spacetime.gif )

## State-Time Cartogram

We use the `Rcartogram` and `getcartr` packages to create an analogous cartogram
- see the previous
[Cartograms with R](http://staff.math.su.se/hoehle/blog/2016/10/10/cartograms.html)
post for further details.  The total number of births per state in a
given year is used as scaling variable for the cartogram.



![]({{ site.baseurl }}/figure/source/2017-03-06-spacetimenames/US-cartogram-babynames-spacetime.gif )

Its amazing to observe how births *go west* in the US during
the considered time period.

<!-- Note: This graphic is in need for some smart text placement, e.g., by
ensuring that the bound box of the text is not in conflict with any
other bounding box. -->

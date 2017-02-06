The analysis can even be taken one step further to illustrate
uncertainty in the Lorenz curve - here shown exemplarily for the
girls.

```{r, LORENZCURVE2, echo=FALSE, warning=FALSE, message=FALSE}
set.seed(123)
b_count <- boot::boot(kids, statistic=name_ranks, R=99, strata=kids$district,
                parallel="multicore",ncpus=3, return="count")

newborn2 <- newborn %>% arrange(firstname,sex) %>% select(firstname,sex) %>% mutate(isFemale = sex== "f")

##Plot
plot(Lc(name_ranks(kids, returns="count")[newborn2$isFemale]), col="darkred",lwd=2, # xlim=c(0.9,1),
     xlab="Cumulative share of female baby names", ylab="Cumulative share of total girl names",main="Lorenz curve (girls)")
for (i in seq_len(b_count$R)) {
  values <- b_count$t[i,newborn2$isFemale]
  lines(Lc(values), col=rgb(0.5,0.5,0.5,0.5))
}
lines(Lc(name_ranks(kids, returns="count")[newborn2$isFemale]), col="darkred")
legend(x="topleft",c("Point Estimate","99 Bootstrap Curves"),col=c("darkred",rgb(0.5,0.5,0.5,0.5)),fill=c(NA,rgb(0.5,0.5,0.5)),lwd=c(2,1))
```

Note that the figure shows one weakness of the current bootstrap
approach: only names available in the 2016 data can be
re-sampled. Uncommon names quickly do not end up in the bootstrap
re-sample (count = 0). Hence, the Lorenz curve of the re-samples is
far away from the actual observed curve for the smaller ranks. This
could be fixed in part by adding additional names from, say, 2015, to
the population of names to consider and use a parametric bootstrap
instead. However, the uncertainty does not appear to affect the shape
of the Lorenz curve much at the high cumulative proportions, which are
the interesting ones for our analysis.

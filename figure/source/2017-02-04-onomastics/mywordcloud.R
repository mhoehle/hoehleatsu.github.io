######################################################################
## Code take from the wordcloud package
## https://cran.r-project.org/web/packages/wordcloud/
##
## by Ian Fellows <ian at fellstat.com> available under the LGPL-2.1
## license
##
## Author: Michael Höhle <http://www.math.su.se/~hoehle>
## Date:   2016-03-21
##
## This code is similarly available under the LGPL-2.1 license
######################################################################

mywordcloud <- function (words, freq, scale = c(4, 0.5), min.freq = 3, max.words = Inf,
    random.order = TRUE, random.color = FALSE, rot.per = 0.1,
    colors = "black", ordered.colors = FALSE, use.r.layout = FALSE,
    fixed.asp = TRUE, offset=c(0,0), bbox, ...)
{
    if (!fixed.asp && rot.per > 0)
        stop("Variable aspect ratio not supported for rotated words. Set rot.per=0.")
    tails <- "g|j|p|q|y"
    last <- 1
    nc <- length(colors)
    if (missing(freq)) {
        if (!require("tm"))
            stop("freq must either be non-missing, or the tm package must be available")
        if (is.character(words) || is.factor(words)) {
            corpus <- Corpus(VectorSource(words))
            corpus <- tm_map(corpus, removePunctuation)
            corpus <- tm_map(corpus, function(x) removeWords(x,
                stopwords()))
        }
        else corpus <- words
        tdm <- TermDocumentMatrix(corpus)
        freq <- slam::row_sums(tdm)
        words <- names(freq)
    }
    if (ordered.colors) {
        if (length(colors) != 1 && length(colors) != length(words)) {
            stop(paste("Length of colors does not match length of words",
                "vector"))
        }
    }
    if (min.freq > max(freq))
        min.freq <- 0
    overlap <- function(x1, y1, sw1, sh1) {
        if (!use.r.layout)
            return(wordcloud:::.overlap(x1, y1, sw1, sh1, boxes))
        s <- 0
        if (length(boxes) == 0)
            return(FALSE)
        for (i in c(last, 1:length(boxes))) {
            bnds <- boxes[[i]]
            x2 <- bnds[1]
            y2 <- bnds[2]
            sw2 <- bnds[3]
            sh2 <- bnds[4]
            if (x1 < x2)
                overlap <- x1 + sw1 > x2 - s
            else overlap <- x2 + sw2 > x1 - s
            if (y1 < y2)
                overlap <- overlap && (y1 + sh1 > y2 - s)
            else overlap <- overlap && (y2 + sh2 > y1 - s)
            if (overlap) {
                last <<- i
                return(TRUE)
            }
        }
        FALSE
    }
    ord <- rank(-freq, ties.method = "random")
    words <- words[ord <= max.words]
    freq <- freq[ord <= max.words]
    if (ordered.colors) {
        colors <- colors[ord <= max.words]
    }
    if (random.order)
        ord <- sample.int(length(words))
    else ord <- order(freq, decreasing = TRUE)
    words <- words[ord]
    freq <- freq[ord]
    words <- words[freq >= min.freq]
    freq <- freq[freq >= min.freq]
    if (ordered.colors) {
        colors <- colors[ord][freq >= min.freq]
    }
    thetaStep <- 0.1
    rStep <- 0.05

#    plot.new()
#    op <- par("mar")
#    par(mar = c(0, 0, 0, 0))
#    if (fixed.asp)
#        plot.window(c(0, 1), c(0, 1), asp = 1)
#    else plot.window(c(0, 1), c(0, 1))
    normedFreq <- freq/max(freq)
    size <- (scale[1] - scale[2]) * normedFreq + scale[2]
    boxes <- list()

    for (i in 1:length(words)) {
        rotWord <- runif(1) < rot.per
        r <- 0
        theta <- runif(1, 0, 2 * pi)
        x1 <- 0.5
        y1 <- 0.5
        wid <- strwidth(words[i], cex = size[i], ...) / diff(bbox[1,])
        ht <- strheight(words[i], cex = size[i], ...) / diff(bbox[2,])

#        print(c(wid,ht))

        if (grepl(tails, words[i]))
            ht <- ht + ht * 0.2
        if (rotWord) {
            tmp <- ht
            ht <- wid
            wid <- tmp
        }
        isOverlaped <- TRUE
        while (isOverlaped) {
            if (!overlap(x1 - 0.5 * wid, y1 - 0.5 * ht, wid,
                ht) && x1 - 0.5 * wid > 0 && y1 - 0.5 * ht >
                0 && x1 + 0.5 * wid < 1 && y1 + 0.5 * ht < 1) {
                if (!random.color) {
                  if (ordered.colors) {
                    cc <- colors[i]
                  }
                  else {
                    cc <- ceiling(nc * normedFreq[i])
                    cc <- colors[cc]
                  }
                }
                else {
                  cc <- colors[sample(1:nc, 1)]
                }
#                print(c(x1+offset[1], y1+offset[2]))
                text((x1-0.5)*diff(bbox[1,])+offset[1], (y1-0.5)*diff(bbox[2,])+offset[2], words[i], cex = size[i], offset = 0,
                  srt = rotWord * 90, col = cc, ...)
                boxes[[length(boxes) + 1]] <- c(x1 - 0.5 * wid,
                  y1 - 0.5 * ht, wid, ht)
                isOverlaped <- FALSE
            }
            else {
                if (r > sqrt(0.5)) {
                  warning(paste(words[i], "could not be fit on page. It will not be plotted."))
                  isOverlaped <- FALSE
                }
                theta <- theta + thetaStep
                r <- r + rStep * thetaStep/(2 * pi)
                x1 <- 0.5 + r * cos(theta)
                y1 <- 0.5 + r * sin(theta)
            }
        }
    }
#    par(mar = op)
    invisible()
}

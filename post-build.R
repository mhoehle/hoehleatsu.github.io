library("knitr")
knitr::opts_knit$set(
                   base.dir = '/Users/hoehle/Sandbox/Blog/',
                   base.url = 'http://staff.math.su.se/hoehle/blog/'
                 )

##Make redirect file
redir <- function(url) {
paste0(
'<!DOCTYPE HTML>
<html lang="en-US">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="refresh" content="1; url=',url,'">
        <script type="text/javascript">
            window.location.href = "',url,'"
        </script>
        <title>Page Redirection</title>
    </head>
    <body>
        <!-- Note: do not tell people to \`click\` the link, just tell them that it is a link. -->
        If you are not redirected automatically, follow this <a href=\'http://example.com\'>link to example</a>.
    </body>
</html>')
}

##Make some redirects
dir.create(file.path(knitr::opts_knit$get("base.dir"),"_site","2017","02","11"))
writeLines(redir(url="../13/bday.html"), con=file(file.path(knitr::opts_knit$get("base.dir"),"_site","2017","02","11","bday.html")))

##Ping pong post
dir.create(file.path(knitr::opts_knit$get("base.dir"),"_site","2017","09","01"))
writeLines(redir(url="../02/pairprogramming.html"), con=file(file.path(knitr::opts_knit$get("base.dir"),"_site","2017","09","01","proofpingpong.html")))

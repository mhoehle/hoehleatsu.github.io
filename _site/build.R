local({
  # fall back on '/' if baseurl is not specified
  baseurl = servr:::jekyll_config('.', 'baseurl', '/')
  knitr::opts_knit$set(base.url = baseurl)
  # fall back on 'kramdown' if markdown engine is not specified
  markdown = servr:::jekyll_config('.', 'markdown', 'kramdown')
  # see if we need to use the Jekyll render in knitr
  if (markdown == 'kramdown') {
    knitr::render_jekyll()
  } else knitr::render_markdown()

  # input/output filenames are passed as two additional arguments to Rscript
  a = commandArgs(TRUE)
  d = gsub('^_|[.][a-zA-Z]+$', '', a[1])
  knitr::opts_chunk$set(
    fig.path   = sprintf('figure/%s/', d),
    cache.path = sprintf('cache/%s/', d)
  )
  # set where you want to host the figures (I store them in my Dropbox Public
  # folder, and you might prefer putting them in GIT)
  if (Sys.getenv('USER') %in% c('hoehle','me')) {
    # these settings are only for myself, and they will not apply to you, but
    # you may want to adapt them to your own website

    knitr::opts_knit$set(
##    base.dir = '/Users/hoehle/Sandbox/Blog/',
##    base.url = 'http://hoehleatsu.github.io/'
      base.dir = '/Users/hoehle/Sandbox/Blog/',
      base.url = 'http://staff.math.su.se/hoehle/blog/'
    )
  }
  knitr::opts_knit$set(width = 70)
  knitr::knit(a[1], a[2], quiet = TRUE, encoding = 'UTF-8', envir = .GlobalEnv)

  ##Make redirect file
  redir <- '<!DOCTYPE HTML>
<html lang="en-US">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="refresh" content="1; url=../13/bday.html">
        <script type="text/javascript">
            window.location.href = "../13/bday.html"
        </script>
        <title>Page Redirection</title>
    </head>
    <body>
        <!-- Note: do not tell people to \`click\` the link, just tell them that it is a link. -->
        If you are not redirected automatically, follow this <a href=\'http://example.com\'>link to example</a>.
    </body>
</html>'
  dir.create(file.path(knitr::opts_knit$get("base.dir"),"_site","2017","02","11"))
  writeLines(redir, con=file(file.path(knitr::opts_knit$get("base.dir"),"_site","2017","02","11","bday.html")))
})

#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
# Author: Michael Höhle <http://www.math.su.se/~hoehle>
# Date:   05 Jan 2019
# License: GNU General Public License (GPL v3 - https://www.gnu.org/licenses/gpl.html)

library(purrr)
library(shiny)
library(dplyr)
library(combinat)
library(magrittr)
library(ggplot2)
library(plotly)

##Global variable containing the hashmap to store the computed binary trees.
trees <- list()
trees[["0"]] <- NULL
trees[["1"]] <- list(list(val="node", left=NULL, right=NULL))
trees[["2"]] <- list(list(val=NULL, left=trees[["1"]][[1]], right=trees[["1"]][[1]]))

allBinTrees <- function(n) {
  ##Character version of n, which is used as hash key
  n_char <- as.character(n)
  
  ##Only compute something if n is not already in the tree list
  if (is.null(pluck(trees, n_char))) {
    trees[[n_char]] <<- list()
    for (i in 1:(n-1)) {
      j = n - i
      for (left_tree in allBinTrees(i)) {
        for (right_tree in allBinTrees(j)) {
          trees[[n_char]][[length(trees[[n_char]]) + 1]] <<- list(val=NULL, left=left_tree, right=right_tree)
        }
      }
    }
  } #end if not already in tree list
  ##Return result from our hashmap
  return(pluck(trees, n_char))
}

##Helper function to print a tree
tree2String <- function(tree) {
  ##If tree only consists of a leave
  if (is.character(tree$val)) return(tree$val)
  ##Make the string
  paste0("(", tree2String(tree$left), " op " , tree2String(tree$right), ")")
}

##Convention: Number the operators from left to right. We do the search
##and replace recursively. Any clever way to do this as a regexp?
addOpNumbers <- function(str, i=1) {
  if (!grepl(" op ", str)) return(str)
  ##Replace one "op"
  addOpNumbers( str=sub(" op ", paste0(" op",i," "), str), i=i+1)
}

##Convert the "node" placeholders into the variables a, b, c, ...
##Convention: Name the numbers from left to right by "a", "b", "c", ...
replaceNodes <- function(str, i=1) {
  if (!grepl("node", str)) return(str)
  ##Replace one "node"
  replaceNodes( str=sub("node", letters[i], str), i=i+1)
}

##Even more general helper function for numbers as well as operators
replace <- function(str, what) {
  if (length(what) == 0) return(str)
  replace( str=gsub(names(what)[1], what[1],  str), what=what[-1])
}


solve <- function(base_numbers, expr_result, operatorList) {
 
  ##Variables
  k <- length(base_numbers)
  
  ##Permuations of the base numbers
  perm <- combinat::permn(base_numbers) %>%
    map(setNames, nm=letters[seq_len(k)])
  
  ##Slim it?
  perm <- perm[!duplicated(map(perm, paste0, collapse=""))]
  
  ##Make all combinations of the operators
  opsList <- map( seq_len(k-1), function(.x) operatorList)
  operators <- cross(opsList) %>% map( setNames, nm=paste0("op",seq_len(k-1)))
  
  ##Make all possible brackets
  bracketing <- map_chr( allBinTrees(n=k),
                         ~ tree2String(.x) %>% addOpNumbers %>% replaceNodes)
  
  
  ##All combinations of the numbers, the order and the bracketing.
  ##Depending on the combinations this might take a while...
  combos <- cross3( perm, map( operators, unlist), bracketing) %>%
    map(setNames, c("numbers", "operators", "bracket"))

  ##Compute value of all combinations (with progress bar)
  res <- withProgress(
    message = 'Evaluating all combinations',
    detail = 'This might take a while...', value = 0, {
      res <- map(combos, .f=function(l) {
        incProgress(1/length(combos))
        l[["expr"]] <- l[["bracket"]] %>% replace(l[["numbers"]]) %>% replace(l[["operators"]])
        l[["value"]] <- eval(parse(text=l[["expr"]]))
        return(l)
      })
    })  
               
  ##Convert results to a data.frame
  df <- withProgress(
    message = 'Converting result to a data.frame',
    detail = 'This might take a while...', value = 0, {
      map_df(res, ~ { 
        incProgress(1/length(res))
        data.frame(expr=.x$expr, value=.x$value)
        })
    })

                 
  ##Match 24
  is_zero <- function(x) isTRUE(all.equal(x, 0))
  
  ##Only those with nice integers results
  df_int <- df %>%
    mutate(rounded = round(value, digits=0), diff=value - rounded) %>% rowwise %>% 
    filter(is_zero(diff))
  
  res <- list(combos=df_int %>% select(expr, value), 
              expr=df_int %>% filter(rounded==expr_result) %$% expr)
  
  return(res)
}

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Solving Math Puzzles"),
   #"A small app to brute force solve a particular type of math puzzle. See this ", a(href="", em("blog post")), "for details.", p(),
   #    
   # Show a plot of the generated distribution
   tabsetPanel(
     tabPanel("Main",
              h1(""), 
              fluidRow(
                column(1,textInput("no1", "Expression:", "8")),
                column(1,h3("op1")),
                column(1,textInput("no2", " ", "8")),
                column(1,h3("op2")),
                column(1,textInput("no3", " ", "3")),
                column(1,h3("op3")),
                column(1,textInput("no4", " ", "3")),
                column(1,h3("=")),
                column(1,textInput("res", "", "24"))
              ),
              fluidRow(
                column(4,selectInput("operators","Operators:",choices=c("+","-","*","/"), multiple=TRUE, selected=c("+","-","*","/")))
              ),
              fluidRow(
                column(8, ""),
                column(1, actionButton("goButton", "Solve!"))
              ),
              hr(),
              htmlOutput("result")
     ),# end tabPanel
     tabPanel("Detailed Table",  dataTableOutput("allCombosDF")),
     tabPanel("Histogram", plotlyOutput("allCombosHistogram"))
   ) #end tabSetPanel
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
  tags$head(tags$style(HTML('
        .skin-blue .container-fluid {
        background-color: #f4b943;
  }')))


  getBaseNumbers <- eventReactive(input$goButton, {
    as.numeric(c(input$no1, input$no2, input$no3, input$no4))
  })
  
  getResult <- eventReactive(input$goButton, {
    as.numeric(input$res)
  })
  
  getOperatorList <- eventReactive(input$operators, {
    input$operators
  })
  
  output$result <- renderUI({
    input$goButton
   
    ##Extract base numbers 
    base_numbers <- getBaseNumbers()
    expr_result <- getResult()
    operatorList <- getOperatorList()
    
    print(expr_result)
    print(base_numbers)
    print(operatorList)
    
    ##Solve the math puzzle
    solution <- suppressWarnings(solve(base_numbers = base_numbers, expr_result = expr_result, operatorList = operatorList))
    output$allCombosDF <- renderDataTable(solution$combos)
    
    output$allCombosHistogram <- renderPlotly({
      ##p <- ggplot(solution$combos, aes(x=value)) + geom_histogram(bins=50) + ylab("Number of combinations") + xlab("Value of expression")
      p <- ggplot(solution$combos, aes(x=value)) + geom_histogram(breaks=seq(floor(min(solution$combos$value))-0.5,ceiling(max(solution$combos$value))+0.5,by=1)) + ylab("Number of combinations") + xlab("Value of expression")
      plotly::ggplotly(p)
    })#,width=800, height=400, res=100)
    
    print(solution)
    HTML(paste0("<h3>Solution:</h3>",
                if (length(solution$expr)>0) {paste0(solution$expr, "  =  ", expr_result, collapse="<br>")} else {"No solution found!"},
                "<hr>"))
  }) #renderUI
  
  
}

# Run the application 
shinyApp(ui = ui, server = server)


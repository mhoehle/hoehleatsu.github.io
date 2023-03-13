# Code around the manuscript of Jehn et al (2021) 
# documented in https://arxiv.org/abs/2109.10700
library(furrr)

# Source simulation function
source("super6.R")

#' Find all situations where a continue vs. stop choice is to be made
#' for player 1.
#' 
#' See Jehn (2021), https://arxiv.org/pdf/2109.10700.pdf, for details.
#' @param n Total number of sticks currently (i+j+k)
#' @return A vector of strings describing the situations in i/j/k notation
#' where i is the number of occupied pits in the lid, j is the number of
#' sticks player 1 has and k is the number of sticks player 2 has. Note
#' i+j+k = n
#' 

situations <- function(n) {
  res <- NULL
  # Sticks in the Lid
  for (i in min(n,5):1) {
    # Player 1
    for (j in n:1) {
      # Player 2
      k <- n - i - j
      # Don't consider impossible situations or situations without a choice
      if (k>0  & !(i==0 & j==k)) {
        res <- append(res, str_c(c(i,j,k), collapse="/"))
      }
    }
  }
  return(res)
}

# Situations when there are 8 sticks
situations(n=8)


## Handle the large integers using the GMP library
library(gmp)

#' Encodes [A345383](https://oeis.org/A345383)
#' 
#' @param n Number of sticks
#' @returns a(n) from A345383
a <- function(n) {
  a <- as.bigz(c(0, 0, 1, 7, 63, 1023, 32760, 1048544, 33554304, 1073741312, 34359736320, 1099511619584, 35184370221056, 1125899873681408, 36028796752101376))
  if (n>=1 & n<=15) return(a[n]) else return(NA)
}


int_strategy_to_vec <- function(s) {
  str_split_1(as.character(s, b=2), pattern="") %>% as.integer()
}

#' Show the optimal stragegy for all situations with n sticks
optimal_strategy <- function(n) {
  
  tibble(situation= situations(n),
         continue = rev(int_strategy_to_vec(a(n))))
}

optimal_strategy(n=7)

(always <- tibble(filled_holes=0:5,   continue_prob=1))

## Jehn's optimal strategy for for two players
jehn <- function(player_idx, filled_holes, state_players) {
  # Some summaries
  sticks_left <- filled_holes + sum(state_players)
  my_sticks <- state_players[player_idx]
  other_sticks <- state_players[-player_idx]

  #Strategy for basic cases
  if (filled_holes <= 2) return(1)
  if (filled_holes == 5) return(0)
  #Complicated part of the strategy
  s_best <- optimal_strategy(n=sticks_left)
  state <- str_c(filled_holes, my_sticks, other_sticks, sep="/")
  action <- s_best %>% filter(situation == state) %>% 
    pull(continue)

  # Check if output fails (this should not happen).  
  if (length(action) == 0) { browser()}
  if (!is.numeric(action)) { browser()}
  
  # Done
  return(action)
} 

#two_players <- list(A=always, B=always)
# Simulate two players, one playing the optimal strategy
two_players <- list(A=always, B=jehn)
h <- simulate_super6(two_players, sticks=4)
h

winner <- function(H) {
  H %>% slice_tail(n=1) %>% pull(player)
}


#plan(multisession, workers = 4)

n_sims <- 1e3
sticks <- 4
games <- map(seq_len(n_sims), ~
      simulate_super6(players_strategy=two_players, sticks=sticks),
      .progress=TRUE,
      .options=furrr_options(seed=TRUE)
)

games_summary <- future_map(games, ~ tibble(
    beginner=.x %>% slice_head(n=1) %>% pull(player),
    winner=.x %>% slice_tail(n=1) %>% pull(player),
  ),
  .progress = TRUE
) %>%  bind_rows()

games_summary %>% summarise(p_win_beginner = mean(beginner == winner))
games_summary %>% summarise(p_begin_A = mean(beginner == "A"))
games_summary %>% summarise(p_win_A = mean(winner == "A"))

########################################################
## Some algebra of in Jehn et al. (2021)
########################################################
A <- matrix(c(6, -5, 1, 6), 2,2, byrow=TRUE)
y <- as.vector(c(1,6))

solve(A) %*% y
c(36/41, 35/41)


########################################################
## Initial code to unwrap [A345383](https://oeis.org/A345383)
## The integers of n>=11 are too big to be handled in R
## and we needed to change to GMP library (see blog post)
########################################################

library(R.utils)
#a(3): 1/1/1
a(3)
intToBin(1)
#a(4): 2/1/1, 1/2/1, 1/1/2
a(4)
intToBin(7)
get_strategy(4)

#a(5):
a(5)
intToBin(63)
get_strategy(5)
#a(6)
get_strategy(6)
#a(7)
get_strategy(7)


##


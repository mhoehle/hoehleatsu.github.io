# My own value iteration
library(tidyverse)

#' Find all situations where a continue vs. stop choice is to be made
#' for player 1.
#' 
#' See Jehn (2021), https://arxiv.org/pdf/2109.10700.pdf, for details.
#' 
#' @param n Total number of sticks currently (i+j+k)
#' @return A vector of strings describing the situations in i/j/k notation
#' where i is the number of occupied pits in the lid, j is the number of
#' sticks player 1 has and k is the number of sticks player 2 has. Note
#' i+j+k = n
#' 
situations <- function(n) {
  res <- NULL
  # Sticks in the Lid
  for (i in min(n,5):0) {
    # Sticks Player 1
    for (j in n:1) {
      # Sticks Player 2
      k <- n - i - j
      # Don't consider impossible situations or situations without a choice
      # if (k>0  & !(i==0 & j==k)) {
      #   res <- append(res, str_c(c(i,j,k), collapse="/"))
      # }
      if (i>=0  & !(j<=0 | k<=0)) {
        res <- append(res, str_c(c(i,j,k), collapse="/"))
      }
    }
  }
  return(res)
}


# Convert state specification as string 
state_str2num <- function(s) {
  return(str_split_1(s, pattern="/") %>% as.numeric())
}

state_num2idx <- function(s) {
  s_str <- str_c(s, collapse="/")
  
  idx <- which( s_str == states)
  if (length(idx) == 0) {
    stop(str_c("State ", s_str, " not presented in state space."))
  }
  return(idx[1])
}

swap <- function(state) {
  return(state[c(1,3,2,4)])
}
  
# Computes the reward for a given state encoded as numeric c(i,j,k)
R <- function(state) {
  # A terminal state
  if (state[2] == 0) return(1)
  if (state[3] == 0) return(-1)
  # Other state (nothing)
  return(0)
}

# How to handle future rewards of terminating states?
U <- function(state) {
  # Terminal state (no future returns)
  if (state[2] == 0) return(0)
  if (state[3] == 0) return(0)
  # A real state
  idx <- state_num2idx(state)
  return(U_vec[idx])
}

#' All states when there are n sticks in the game left
#' 
#' We distinguish between states with a choice if to throw the dice
#' and those without
#' 
#' @param n Number of sticks left in the game
#'    
make_states <- function(n) {
  states <- map(seq_len(n), ~ situations(n=.x)) %>% unlist() %>% unique()
  # The actual state contains an additional entry, if next move is to be forced
  # (because the first throw in a turn always needs to be made), i.e. s' = (s, {next_choose, next_forced})
  # Augment with round 1 indicator: must throw (0/1)
  states <- str_c(rep(states,each=2), "/", rep(c(0,1), times=length(states)))
  return(states)  
}

#' Find the optimal playing situation in a game with n sticks left
#' 
#' @param n Number of sticks left in the game
#' @return A tibble containing the optimal strategy for each state/situation
#' in the game together with the expected value when the end of the game
#' is given -1 or 1 and all steps in between have value 0. This translates
#' directly into winning probabilies (all assuming that the opponent is also
#' following the optimal strategy)      

optimal_strategy <- function(n) {
  # translate
  state_num2idx <- function(s) {
    s_str <- str_c(s, collapse="/")
    
    idx <- which( s_str == states)
    if (length(idx) == 0) {
      stop(str_c("State ", s_str, " not presented in state space."))
    }
    return(idx[1])
  }
  
  # How to handle future rewards of terminating states?
  U <- function(state) {
    # Terminal state (no future returns)
    if (state[2] == 0) return(0)
    if (state[3] == 0) return(0)
    # A real state
    idx <- state_num2idx(state)
    return(U_vec[idx])
  }
  
  states <- make_states(n) %>% sort(decreasing=TRUE)
  n_states <- length(states)
  ## Storage of the value function
  U_vec <- U_vec_prime <- rep(0, n_states) 
  ## Storage of the policy/strategy
  pi <- rep(NA, n_states)
  ## Loop controls
  stop <- FALSE
  epsilon <- 1e-10
  iter <- 0
  
  # Value iteration 
  while (!stop) {
    iter <- iter + 1
    Delta <- 0
    for (idx in seq_len(n_states)) {
      # Translate to integer configuration
      state <- state_str2num(states[idx])
      
      # The new states (might not be possible!)
      state_six      <- state + c(  0, -1, 0, 0)       ; state_six[4] = 0 #next move is decidable
      state_free     <- state + c(  1, -1, 0, 0)       ; state_free[4] = 0 #next move is decidable
      state_occupied <- swap(state + c( -1,  1, 0, 0)) ; state_occupied[4] = 1 #forced to throw in round 1
      state_swap     <- swap(state)                    ; state_swap[4] = 1 #forced to throw in round 1
      
      # Number of sticks in the lid
      i <- state[1]
      
      #Q(s, continue)
      qs_continue <- 
        1/6               * (R(state_six)  +  U(state_six)) + 
        (if (i<5) (5-i)/6 * (R(state_free) +  U(state_free)) else 0) + 
        (if (i>0) i/6     * (R(state_occupied) - U(state_occupied)) else 0)
      
      #Q(s, stop)
      qs_stop <- -(R(state_swap) + U(state_swap))
      
      # Updated value & strategy if there is a choice.
      if (state[4] == 0) {
        U_vec_prime[idx] <- max(qs_continue, qs_stop)
        pi[idx] <- qs_continue > qs_stop
      } else { #no choice
        U_vec_prime[idx] <- qs_continue
        pi[idx] <- 1
      }
      
      # Discrepancy
      #cat("iter = ", iter, " idx = ", idx, " Delta=", Delta, "\n")
      Delta <- max(Delta, abs(U_vec[idx] - U_vec_prime[idx]))
    }
    #Delta <-  max(abs(U_vec - U_vec_prime))
    #if (iter>=100) { browser() }
    # Update the value function
    U_vec <- U_vec_prime
    # Continue the value iteration?
    cat("iter = ", iter, ", Delta =", Delta, "\n")
    stop <- Delta <= epsilon
    
  }
  
  # Make a tibble containing the strategy
  strategy <- tibble(state=states, value=U_vec, strategy=pi, prob=1/2*U_vec+1/2) %>% 
    tidyr::separate_wider_delim(state, delim="/", names=c("i","j","k", "forced_move")) %>% 
    mutate(across(c(i,j,k, forced_move), as.numeric)) %>% 
    arrange(desc(i), desc(j), desc(k))
  
  return(strategy)
}

optimal_strategy(n=7)

#########################################################
# Compute probability of winning as start player
#########################################################

## Opening round one throw of the dice each, initially m sticks
m <- 4

# Function to find probability to win
p_win <- function(state) {
  optimal_strategy(sum(state)) %>% 
    filter(i == state[1] & j == state[2] & k == state[3] & forced_move) %>% 
    pull(prob)
}

# 1-5, 1-5 not equal: 2/(m-1)/(m-1) with probability 5/6*4/6
s_2mm1mm1 <- c(2,m-1,m-1)
p_2mm1mm1 <-  5/6*4/6
p_win_2mm1mm1  <- p_win(s_2mm1mm1)

# 1-5, 1-5 but equal: 0/(m-1)/(m+1) with probability 5/6*1/6
s_0mm1mp1 <- c(0,m-1,m+1)
p_0mm1mp1 <- 5/6*1/6
p_win_0mm1mp1 <- p_win(s_0mm1mp1)

# (6, 1-5) or (1-5, 6): 1/(m-1)/(m-1) with probability 1/6*5/6 + 5/6*1/6
s_1mm1mm1 <- c(1,m-1,m-1)
p_1mm1mm1 <- 1/6*5/6 + 5/6*1/6
p_win_1mm1mm1 <- p_win(s_1mm1mm1)

# (6,6): 0/(m-1)/(m-1) with probability 1/6*1/6
s_0mm1mm1 <- c(0, m-1, m-1)
p_0mm1mm1 <- 1/6*1/6
p_win_0mm1mm1  <- p_win(s_0mm1mm1 )

p_start_state <- c(p_2mm1mm1, p_0mm1mp1, p_1mm1mm1, p_0mm1mm1)
sum(p_start_state)
p_win <- c(p_win_2mm1mm1, p_win_0mm1mp1, p_win_1mm1mm1, p_win_0mm1mm1)
p_win

# Probabilty to win game as start player
sum(p_start_state * p_win)

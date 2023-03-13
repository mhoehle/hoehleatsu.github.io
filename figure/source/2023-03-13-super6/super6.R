library(tidyverse)

#' Simulate one game of Super6
#'
#' @param players_strategy Provide a named list with each player's strategy. The names contain the player's names.
#' @param sticks How many sticks per player
#' @param debug Debug mode (Default: FALSE)
#'
#' @return The history of the simulated game (state & actions)
#' 
simulate_super6 <- function(players_strategy, sticks=4, debug=FALSE) {
  players <- names(players_strategy)
  nPlayers <- length(players)

  ## To even out the advantage of beginning the game: Use some permutation of the players as play order
  player_order <- sample.int(nPlayers, size=nPlayers, replace=FALSE)

  ## Bookkeeping variable to store if hole is occupied
  hole <- rep(0, times=6) %>% setNames(1:6)

  ## Bookkeeping for each player how many sticks they have
  players_sticks <- rep(sticks, nPlayers) %>% setNames(players)

  round <- 1
  finished <- FALSE
  history <- NULL

  ## Loop until the game is finished
  while (!finished) {
    ## Let each player have its turn(s)
    for (p in player_order) {
      ## Reset turn and book-keeping variables
      turn <- 1
      loose_turn <- FALSE

      while (!loose_turn & !finished) {
        ## In the first round each player can only play once
        loose_turn <- (round == 1)

        ## Throw the dice
        dice_throw <- sample(1:6, size=1)
        ## What happens
        if (dice_throw == 6) {
          players_sticks[p] <- players_sticks[p] - 1
          hole[dice_throw] <- hole[dice_throw] + 1
        }
        if (dice_throw <= 5) {
          if (hole[dice_throw] == 0) {
            players_sticks[p] <- players_sticks[p] - 1
            hole[dice_throw] <- 1
          } else {
            decision <- "lost turn"
            loose_turn <- TRUE
            players_sticks[p] <- players_sticks[p] + 1
            hole[dice_throw] <- 0
          }
        }

        ## Check if game is done
        if (players_sticks[p] == 0) {
          finished <- TRUE
          decision <- "game over"
        } else {
          
          ## Decide if to continue if possible
          if (!loose_turn) {
            if (is.function(players_strategy[[p]])) {
              filled_holes <- sum(hole[1:5])
              state_players <- players_sticks
              if (any(players_sticks==0)) browser()
              ## Evaluate the strategy
              p_continue <- players_strategy[[p]](player_idx=p, filled_holes=filled_holes, state_players=state_players)    
            } else {
              ## Evaluation corresponds to a table lookup.
              p_continue <- players_strategy[[p]] %>%
                filter(filled_holes == sum(hole[1:5])) %>%
                pull(continue_prob)
            }
            
            loose_turn <- rbinom(n=1, size=1, prob=1-p_continue) == 1
            decision <- if (loose_turn) "stop turn" else "continue turn"
          } else {
            ## Case where turn is done (which is forced if round == 1)
            decision <- if (round == 1) "stop turn" else "lost turn"
          }
        }
        
        ##Add to history
        summary <- c(round=round, player=players[p], turn=turn, dice=dice_throw, hole=hole, sticks=players_sticks, decision=decision)
        history <- rbind(history, summary)

        turn <- turn + 1
      }

      if (debug) {
        cat("=============\n")
        cat(str_c("round ", round, " player: ", players[p], "\n"))
        cat("hole:\n")
        print(hole)
        print(players_sticks)
        cat("Loose turn=", loose_turn,"\n")
        cat("finished=", finished,"\n")
        cat("=============\n")
      }

      if (finished) break
    }
    round <- round + 1
  }

  ## Convert to data.frame and convert columns back to appropriate types
  h <- as.data.frame(history ) %>%
    mutate(across(-c(player, decision), as.numeric)) %>%
    mutate(decision = factor(decision))
  ## Don't do rownames
  rownames(h) <- NULL

  ## Done
  return(h)
}

if (FALSE) {
  # Test if the function works
  always <- tibble(filled_holes=0:5, continue_prob=1)
  h <- simulate_super6(list(A=always, B=always, C=always), sticks=4)
  h
}

# Python implementation of value iteration to find the optimal strategy in Super Six  
#
# Author: Michael Höhle
# Date:   2023-03-16
#
# Semi-manual translation of the R code in value_iteration.R to python with the 
# help of OpenAI's text-davinci-003 API playground feature https://platform.openai.com/playground/p/default-text-to-command?model=text-davinci-003.

import numpy as np
import pandas as pd

def make_situations(n):
    """Returns all situations in a game with n sticks left

    Parameters
    ----------
    n : int
        The number of sticks left in the game
    
    Returns
    -------
    list
        a list of with entries [i,j,k] 
    """
    res = []
    # Number of sticks in the lid
    for i in range(min(n,5),-1,-1):
        # Number of sticks of player 1
        for j in range(n,0,-1):
            # Number of sticks of player 2
            k = n - i - j
            # Only add valid states
            if (i>=0  and not (j<=0 or k<=0)):
                # Append the state as an array [i,j,k]
                res.append([i,j,k])
    return(res)


def make_states(n):
    """All states when there are n sticks in the game left

    We distinguish between states with a choice if to throw the dice and those without

    Parameters
    ----------
    n : int
        The number of sticks left in the game
    
    Returns
    -------
    list
        a list of with entries [i,j,k] 
    """   
    states = []
    for i in range(1,n+1):
        s = make_situations(i)
        # Make list comprehension which adds a fourth component indicating if the move is forced (0=no, 1=yes)
        for j in range(2):
            states.extend([x + [j] for x in s])
    # Sort the list
    states.sort(reverse=True)
    return(states)

def swap(state, forced_move = None):
    """
    Swap the number of sticks of player 1 and 2

    Parameters
    ----------
    state : vector of length 4
        The state of the game as a vector with 4 components

    forced_move : bool
        If the move is forced (i.e. the player has to swap the sticks)

    Returns
    -------
        The new state as a vector of length 4
    """
    res = [state[0], state[2], state[1], state[3]]
    if (forced_move != None):
        res[3] = forced_move
    return(res)

def add_state(state, Delta, forced_move = None):
    res = [sum(x) for x in zip(state, Delta)]
    if (forced_move != None):
        res[3] = forced_move
    return(res)


def R(state):
    """The immediate reward function
    
    Parameters
    ----------
    state : list
        The state of the game as a vector with 4 components
        
    Returns
    -------
    double The reward R(state), i.e. 1 if player 1 wins, -1 if player 2 wins, 0 otherwise
        
    """
    # A terminal state (player 1 = 0)
    if state[1] == 0:
        return 1
    # A terminal state (player 2 = 0)
    if state[2] == 0:
        return -1
    # Other state (nothing)
    return 0

def optimal_strategy(n, debug=False):
    """"Find the optimal strategy for a game with n sticks left
    """

    # Define local variables for the function
    states = make_states(n)
    n_states = len(states)
    ## Storage of the value function
    U_vec = np.zeros(n_states)
    U_vec_prime = np.zeros(n_states)
    ## Storage of the policy/strategy
    pi = np.full(n_states, np.nan)

    # Future reward function.
    # Note terminating states (i=0 or j=0) have zero future reward.
    # The function uses a local variable states and the value function uvec. Might want to add this to the arguments
    def U(state):
        # Terminal state (no future returns)
        if (state[1] == 0):
            return 0
        if (state[2] == 0):
            return 0
        # Find index of the element matching in states vector
        idx = states.index(state)
        # Return value function of the state
        return U_vec[idx]

    ## Loop controls
    stop = False
    epsilon = 1e-10
    iter = 0

    # Value iteration 
    while (stop == False):
        iter += 1
        Delta = 0
        for idx in range(n_states):
            # Translate to integer configuration
            state = states[idx]

            # The 4 possible moves

            # Do vector addition of the variable state and [0, -1, 0, 0]
            state_six = add_state(state,  [0, -1, 0, 0], forced_move=False)
            state_free = add_state(state, [1, -1, 0, 0], forced_move=False)       
            state_occupied = swap(add_state(state, [-1, 1, 0, 0], forced_move=True))
            state_swap     = swap(state, forced_move=True)                 
        
            # Number of sticks in the lid
            i = state[0]

            #Q(s, continue)
            qs_continue = (1/6  * (R(state_six)  +  U(state_six))) + \
                        ((5-i)/6 * (R(state_free) +  U(state_free)) if i<5 else 0) + \
                        (i/6     * (R(state_occupied) - U(state_occupied)) if i>0 else 0)

            #Q(s, stop)
            qs_stop = -(R(state_swap) + U(state_swap))

            # Updated value & strategy if there is a choice.
            if (state[3]==0):
                U_vec_prime[idx] = max(qs_continue, qs_stop)
                pi[idx] = qs_continue > qs_stop
            else: #no choice
                U_vec_prime[idx] = qs_continue
                pi[idx] = 1

            # Discrepancy  
            Delta = max(Delta, abs(U_vec[idx] - U_vec_prime[idx]))

        # Update the value function by copying the new values
        # Note: In NumPy, using "=" would only make a reference to the new vector
        # See https://www.geeksforgeeks.org/array-copying-in-python/
        U_vec = U_vec_prime.copy()

        # Continue the value iteration?  
        if (debug):
            print("iter = ", iter, ", Delta =", Delta)  
        stop = (Delta <= epsilon)

    # Make a tibble containing the strategy  
    strategy = pd.DataFrame({'state': states, 'value': U_vec, 'strategy': pi, 'prob': 1/2*U_vec+1/2})  
    # Split state column into 4 separate columns
    strategy[['i','j','k','l']] = pd.DataFrame(strategy.state.tolist(), index= strategy.index) 
    # Drop the state column
    strategy = strategy.drop(columns=['state'])
    # Convert strategy to boolean
    strategy['strategy'] = strategy['strategy'].astype(bool)
    # Change the order such that the i,j,k,forced_move columns are shown first
    cols = strategy.columns.tolist()
    cols = cols[-4:] + cols[:-4]
    strategy = strategy[cols]

    return(strategy)


#Test function
#make_situations(6)

# Find optimal strategy for game with 6 sticks left
s_best = optimal_strategy(7)
# Print full strategy without row number, https://stackoverflow.com/questions/52396477/printing-a-pandas-dataframe-without-row-number-index
# pd.set_option('display.max_rows', None)
# print(s_best.to_string(index=False))

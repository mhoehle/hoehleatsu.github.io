/*
 * Determine the probability to win from an i/j/k situation in the game of Super Six
 *
 * Author: Nuno Hultberg and Michael Höhle
 * Date: 2023-03-15
 * Encoding: UTF-8
*
 * Description:
 * ============
 * The present code is a modified, commented and slightly optimized version of the C++ code that
 * Nuno Hultberg posted as a comment at https://www.youtube.com/watch?v=yrYybddqRQs&lc=Ugxf9HO_ifM6z4g8f5N4AaABAg
 * For a description of Super Six and the notation used see the Appendix of the
 * Blog post "How to Win a Game (or More) of Super Six" at https://mhoehle.github.io/blog/2023/03/13/super6.html
 * The code uses an iterative minimax (?) approach to determine the probability to win 
 * if the game stops after h rounds. 
 * Note: It is implicitly assumed that the opposite player (Player 2) uses the
 * same optimal strategy that we try to find for Player 1.
 * 
 * Details:
 * ========
 * Let P_h(i,j,k, "continue") and P_h(i,j,k, "stop") be the probability to win 
 * after h turns from an i/j/k situation if you choose to roll the dice or stop, 
 * respectively. Here, i is the number of sticks in the lid and j, k is the number
 * of sticks in the hand of player 1 and player 2, respectively. 
 * 
 * For each throw of the dice there are three situations to consider
 *  1. you roll a six (probability 1/6) 
 *  2. (if j<5) you hit a free spot (probability (5-j)/6)
 *  3. (if j>0) you hit an occupied spot (probability j/6)
 *
 * As part of the calculations one needs to know what happens if Player 1
 * looses their turn (i.e. either by hitting an occupied spot or by voluntarily deciding to stop)
 * This depends on the strategy played by Player 2. For simplicity we will assume
 * that Player 2 plays the same optimal strategy as Player 1. 
 * 
 * At each decision point, Player 1 has the choice between the actions "continue" and "stop".
 * Player 2 will choose the action, which maximizes the probability to win, i.e.
 * a^* = argmax_{a \in \{continue, stop}} P_h(i,j,k,a)
 * 
 * Several additional aspects matter though:
 * a) Say Player 1 is in a i/j/k situation. If they stop, then Player 2 will
 *    be facing an i/k/j situation. The probability that Player 2 will win
 *    is thus P_h(i,k,j, "continue") or P_h(i,k,j, "stop"), respectively.
 * b) After h rounds the game might not be finished yet. Hence, it can happend that
 *    neither of the two player wins after h rounds. In other words
 *    max(P_h(i,j,k, "continue") + P_h(i,j,k, "stop") < 1
 *  Let D_h(i,j,k, "continue") and
 *    D_h(i,j,k, "stop") be the probabilities that a game is actually finished
 *    after h rounds. 
 * 
 * player cannot decide whether to throw the dice or not (decision has to be THROW). It is unclear if this is covered by
 * the recursive computations.
 */

#include <iostream>
#include <iomanip>  
#include <iterator>
#include <algorithm>

//using namespace std::cout;

// Maximum number of rounds to consider
const int MAX_ROUNDS = 10000;
// Maximum number of active sticks for a player
const int MAX_STICKS = 16;
// Maximum number of pits in the lid
const int MAX_PITS = 5;
// Define the names of the actions
std::string action_names[2] = { "continue", "stop"};

int main() {
    // Define done & results data structure (MAX_STICKS+1) x (MAX_PITS+1) x (MAX_STICKS+1)
    // done is the probably that the game is done after h rounds
    // results is the value function after h rounds
    double (*results)[MAX_PITS+1][MAX_STICKS+1][2] = new double [MAX_STICKS+1][MAX_PITS+1][MAX_STICKS+1][2]();
    double (*resultsnew)[MAX_PITS+1][MAX_STICKS+1][2] = new double [MAX_STICKS+1][MAX_PITS+1][MAX_STICKS+1][2]();
    double (*done)[MAX_PITS+1][MAX_STICKS+1][2] = new double [MAX_STICKS+1][MAX_PITS+1][MAX_STICKS+1][2]();
    double (*donenew)[MAX_PITS+1][MAX_STICKS+1][2] = new double [MAX_STICKS+1][MAX_PITS+1][MAX_STICKS+1][2]();
    
    // Initialize the data structures
    // The format is [lid] [player 1] [player 2] [continue / stop]
    // Looping variables are not used consistently. Rather confusing. j=1, because we only consider states where player 1 needs an action
    for(int i=0; i<=MAX_STICKS;i++) {
        for(int j=1; j<=MAX_STICKS;j++) {
            // The game is done if player 1 has 0 sticks, utility is 1 no matter the action
            results[0][i][j][0]=1;
            results[0][i][j][1]=1;
            done[0][i][j][0]=1;
            done[0][i][j][1]=1;
            // The game is done if the 2nd player has 0 sticks. The utlity for player 1 is 0 then.
            // so no need to set the results[0][i][j][0]=0 values as they are inited with value 0
            done[j][i][0][0]=1;
            done[j][i][0][1]=1;
            
            // Mirror variables for the new data structures (not sure why they are needed)
            resultsnew[0][i][j][0]=1;
            resultsnew[0][i][j][1]=1;
            donenew[0][i][j][0]=1; 
            donenew[0][i][j][1]=1;
            donenew[j][i][0][0]=1;
            donenew[j][i][0][1]=1;
        }
    }
    
    
    int h = 0;
    // Loop over the number of interations in the game
    while(h < MAX_ROUNDS){
        //std::cout << "4/1/1 after h = " << h << " rounds: " << done[1][4][1][0] << std::endl;

        // Number of sticks that player 1 has
        for(int i=1; i<=MAX_STICKS;i++){
            // Number of sticks in the lid
            for(int j=0; j<=MAX_PITS;j++){
                // Number of sticks of player 2 has.
                for(int k=1; k<=MAX_STICKS;k++) {
                    // Result for situation j+1/i-1/k: one stick from player 1 moves to lid
                    int action_idx_tolid = results[i - 1][j + 1][k][1] > results[i - 1][j + 1][k][0];
                    double old_tolid = results[i - 1][j + 1][k][action_idx_tolid];
                    double olddone_tolid = done[i - 1][j + 1][k][action_idx_tolid];

                    // Result for situation j/i-1/k: one stick from player 1 goes into hole 6
                    int action_idx_tohole = results[i - 1][j][k][1] > results[i - 1][j][k][0];
                    double old_tohole = results[i - 1][j][k][action_idx_tohole];
                    double olddone_tohole = done[i - 1][j][k][action_idx_tohole];

                    // Update states
                    resultsnew[i][j][k][0] = ((5.0 - j) / 6.0) * old_tolid + (1.0 / 6.0) * old_tohole + (j / 6.0) * (done[k][j - 1][i + 1][0] - results[k][j - 1][i + 1][0]);
                    resultsnew[i][j][k][1] = done[k][j][i][0] - results[k][j][i][0];
                    donenew[i][j][k][0] = ((5.0 - j) / 6.0) * olddone_tolid + (1.0 / 6.0) * olddone_tohole + (j / 6.0) * done[k][j - 1][i + 1][0];
                    donenew[i][j][k][1] = done[k][j][i][0];      
                }
        
            }
        }
        done = donenew;
        results = resultsnew;
        h++;
    }

    // Done, show results for the situation with 4 sticks in the lid and up
    // to a total of 11 sticks for one player
    char config[15];
    for(int i=1; i<=11;i++){
        for(int j=1; j<=11-i+1;j++) {
            int action_idx = results[i][4][j][0] > results[i][4][j][1] ? 0 : 1;
            sprintf(config, "%d/%d/%d", 4, i, j);
            std::cout << std::setw(8) << std::setfill(' ') << config <<  ", " 
                 << std::fixed << std::setprecision(6) << results[i][4][j][0] << ", " 
                 << std::fixed << std::setprecision(6) << results[i][4][j][1] << ", " 
                 << action_names[action_idx] <<  std::endl;
        }
    }

    
    // Show some specific results
    std::cout << std::endl << "Specific combinations:" << std::endl;
    std::cout << "4/1/1: " << results[1][4][1][0] <<"," <<results[1][4][1][1] << std::endl;
    std::cout << "3/5/5: " << results[5][3][5][0] <<"," <<results[5][3][5][1] << std::endl;
    std::cout << "3/6/6: " << results[6][3][6][0] <<"," <<results[6][3][6][1] << std::endl;
    std::cout << "5/1/1: " << results[1][5][1][0] <<"," <<results[1][5][1][1] << std::endl;

    // Test for two target values.
    char res[80];
    sprintf(res, "%.3f", results[1][4][1][0]);
    if (res != std::string("0.524")) {
        std::cerr << "Result for 4/1/1 is not correct." << std::endl;
    }
    sprintf(res, "%.3f", results[1][5][1][0]);
    if (res != std::string("0.451")) {
        std::cerr << "Result " << res << " for 5/1/1 is not correct." << std::endl;
    }
}


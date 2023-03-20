/*
 * Nuno Hultberg at https://www.youtube.com/watch?v=yrYybddqRQs&lc=Ugxf9HO_ifM6z4g8f5N4AaABAg
 * writes:
 * 
 * I have decided to "resubmit" the answer as there were some flaws, the code 
 * changes and the output, but the implications stay intact. I think you have 
 * probably done a similar mistake to me since my "first solution" doesn't give
 * the right decimals.  I do inductively decide the chance of winning if we limit
 * the number of rounds to h, assuming everybody after that uses the same strategy.
 * This is the optimal strategy whenever the number of rounds is less than h.
 * Regardless of strategy used we may limit the chance that the game has 
 * more than h rounds. I gave a very ineffective bound, but enough to decide 
 * the strategy when the difference between the chance of winning is <= 0.01.
 * In particular this is enough to disprove Theorem 4 rigorously. This is what I
 * do in the introduction to the last submission. For guarantees for smaller 
 * differences we may just set h higher and use the same idea. In the end I 
 * compute the chances for [5][3][5] and [6][3][6]
 * 
 * I will go slowly through the code:
 * At the beginning I set the chance of winning after 0 rounds to be 1 
 * for [0][i][j] and 0 otherwise.
 * Similarly I set the chance of being done.
 * 
 * In every iteration of the while-loop we compute the chance of winning 
 * if the game is artificially terminated in h+1 rounds depending on the chosen
 * strategy. I think it is best to just read the modified code inside the while
 * loop. It is important to see that this is not some sort of gradient descent,
 * but has everything to do with the number of decision situations. That's it!
 */

#include<iostream>

using namespace std;

int main(){
    double (*results)[20][20][2] = new double [20][20][20][2]();
    double (*resultsnew)[20][20][2] = new double [20][20][20][2]();
    double (*done)[20][20][2] = new double [20][20][20][2]();
    double (*donenew)[20][20][2] = new double [20][20][20][2]();
    
    for(int i=0; i<=16;i++){
        for(int j=1; j<=16;j++){
        results[0][i][j][0]=1;
        results[0][i][j][1]=1;
        resultsnew[0][i][j][0]=1;
        resultsnew[0][i][j][1]=1;
        done[0][i][j][0]=1;
        done[0][i][j][1]=1;
        done[j][i][0][0]=1;
        done[j][i][0][1]=1;
        donenew[0][i][j][0]=1;
        donenew[0][i][j][1]=1;
        donenew[j][i][0][0]=1;
        donenew[j][i][0][1]=1;
        }
    }
    
    int h = 0;
    while(h<10000){
    for(int i=1; i<=16;i++){
        for(int j=0; j<=5;j++){
            for(int k=1; k<=16;k++){
                if(j==5){
                    double old = results[i-1][j][k][1];
                    double olddone = done[i-1][j][k][1];
                    if(results[i-1][j][k][0]>=results[i-1][j][k][1]){
                    old = results[i-1][j][k][0];
                    olddone = done[i-1][j][k][0];
                    }
                    resultsnew[i][j][k][0]=(1.0/6.0)*old+(5.0/6.0)*(done[k][j-1][i+1][0]-results[k][j-1][i+1][0]);
                    resultsnew[i][j][k][1]=done[k][j][i][0]-results[k][j][i][0];
                    donenew[i][j][k][0]=(1.0/6.0)*olddone + (5.0/6.0)*done[k][j-1][i+1][0];
                    donenew[i][j][k][1]=done[k][j][i][0];
                }
                else if(j==0){                    
                    double old_1 = results[i-1][j+1][k][1];
                    double olddone_1 = done[i-1][j+1][k][1];    
                    if(results[i-1][j+1][k][0]>=results[i-1][j+1][k][1]){
                    old_1 = results[i-1][j+1][k][0];
                    olddone_1 = done[i-1][j+1][k][0];
                    }                
                    double old_2 = results[i-1][j][k][1];
                    double olddone_2 = done[i-1][j][k][1]; 
                    if(results[i-1][j][k][0]>=results[i-1][j][k][1]){
                    old_2 = results[i-1][j][k][0];
                    olddone_2 = done[i-1][j][k][0];
                    }
                    resultsnew[i][j][k][0]=((5.0-j)/6.0)*old_1 + (1.0/6.0)*old_2;
                    resultsnew[i][j][k][1]=done[k][j][i][0]-results[k][j][i][0];
                    donenew[i][j][k][0]=((5.0-j)/6.0)*olddone_1 + (1.0/6.0)*olddone_2;
                    donenew[i][j][k][1]=done[k][j][i][0];
                }
                else{
                    double old_1 = results[i-1][j+1][k][1];
                    double olddone_1 = done[i-1][j+1][k][1];  
                    if(results[i-1][j+1][k][0]>=results[i-1][j+1][k][1]){
                        old_1 = results[i-1][j+1][k][0];
                        olddone_1 = done[i-1][j+1][k][0];
                    }

                    double old_2 = results[i-1][j][k][1];
                    double olddone_2 = done[i-1][j][k][1]; 
                    if(results[i-1][j][k][0]>=results[i-1][j][k][1]){
                        old_2 = results[i-1][j][k][0];
                        olddone_2 = done[i-1][j][k][0];
                    }

                    resultsnew[i][j][k][0]=((5.0-j)/6.0)*old_1 + (1.0/6.0)*old_2+(j/6.0)*(done[k][j-1][i+1][0]-results[k][j-1][i+1][0]);
                    resultsnew[i][j][k][1]=done[k][j][i][0]-results[k][j][i][0];
                    donenew[i][j][k][0]=((5.0-j)/6.0)*olddone_1 + (1.0/6.0)*olddone_2+(j/6.0)*done[k][j-1][i+1][0];
                    donenew[i][j][k][1]=done[k][j][i][0];
                }
                    
            }
    
        }
    }
    done = donenew;
    results = resultsnew;
    h++;
    }
    for(int i=1; i<=11;i++){
        for(int j=1; j<=11-i+1;j++){
        cout<<i<<","<<j<<","<<results[i][4][j][0]<<","<<results[i][4][j][1]<<endl;
        }
    }
    cout<<results[1][4][1][0]<<","<<results[1][4][1][1]<<endl;
    cout<<results[5][3][5][0]<<","<<results[5][3][5][1]<<endl;
    cout<<results[6][3][6][0]<<","<<results[6][3][6][1]<<endl;
}


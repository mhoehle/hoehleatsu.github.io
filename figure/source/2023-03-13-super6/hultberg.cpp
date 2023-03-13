/** From the answer of Nuno Hultberg on
    https://www.youtube.com/watch?v=yrYybddqRQs
**/

#include<iostream>
  
using namespace std;

int main(){
  double (*results)[20][20][2] = new double [20][20][20][2]();
  double (*resultsnew)[20][20][2] = new double [20][20][20][2]();
  
  for(int i=0; i<=16;i++){
    for(int j=1; j<=16;j++){
      results[0][i][j][0]=1;
      results[0][i][j][1]=1;
    }
  }
  for(int i=0; i<=16;i++){
    for(int j=1; j<=16;j++){
      resultsnew[0][i][j][0]=1;
      resultsnew[0][i][j][1]=1;
    }
  }
  int h = 0;
  while(h<10000){
    for(int i=1; i<=16;i++){
      for(int j=0; j<=5;j++){
        for(int k=1; k<=16;k++){
          if(j==5){
            double old = max(results[i-1][j][k][0],results[i-1][j][k][1]);
            resultsnew[i][j][k][0]=(1.0/6.0)*old+(5.0/6.0)*(1.0-results[k][j-1][i+1][0]);
            resultsnew[i][j][k][1]=1.0-results[k][j][i][0];
          }
          else if(j==0){
            double old_1 = max(results[i-1][j+1][k][0],results[i-1][j+1][k][1]);
            double old_2 = max(results[i-1][j][k][0],results[i-1][j][k][1]);
            
            resultsnew[i][j][k][0]=((5.0-j)/6.0)*old_1 + (1.0/6.0)*old_2;
            resultsnew[i][j][k][1]=1.0-results[k][j][i][0];
          }
          else{
            double old_1 = max(results[i-1][j+1][k][0],results[i-1][j+1][k][1]);
            double old_2 = max(results[i-1][j][k][0],results[i-1][j][k][1]);
            resultsnew[i][j][k][0]=((5.0-j)/6.0)*old_1 + (1.0/6.0)*old_2+(j/6.0)*(1.0-results[k][j-1][i+1][0]);
            resultsnew[i][j][k][1]=1.0-results[k][j][i][0];
          }
          
        }
        
      }
    }
    results = resultsnew;
    h++;
  }
  for(int i=1; i<=11;i++){
    for(int j=1; j<=11-i+1;j++){
      cout<<i<<","<<j<<","<<results[i][4][j][0]<<","<<results[i][4][j][1]<<endl;
    }
  }
}

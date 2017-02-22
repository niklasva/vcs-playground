#include <iostream>
#include <cmath>
using namespace std;

/*                     ##/
                     ## //
                   ##   //    
                 ##     //   
            y  ##       // h
             ##         //   
           ##           //  
         ## v)          //
       ##/////////////////
        
          y = h / sin v    */
int main()
{
    int v {0};
    int h {0};
    cin >> h >> v;
    
    double ladder = h / sin (v * M_PI / 180);
    cout << ceil(ladder) << endl;

    return 0;
}
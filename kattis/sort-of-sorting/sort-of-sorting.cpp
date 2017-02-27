#include <iostream>
#include <vector>
#include <iterator>
#include <algorithm>

using namespace std;

struct 
{
    bool operator()(string a, string b)
    {           
        // Sortera bara enligt de två första tecknen.
        return a.substr(0,2) < b.substr(0,2);
    }
    
} sort_of_sort;

int main()
{
    int count;
    string delim {""};
    while(cin >> count)
    {
        if (count == 0)
            break;

        vector<string> students;
    
        // Fyll vector students med count st. namn från inläsningsströmmen.
        copy_n(istream_iterator<string>{cin}, count, back_inserter(students));

        // Sortera med funktionsobjektet sort_of_sort.
        stable_sort(students.begin(), students.end(), sort_of_sort);

        cout << delim;
        delim = "\n";
        copy(students.begin(),students.end(), ostream_iterator<string>(cout, "\n"));
    }

    return 0;
}
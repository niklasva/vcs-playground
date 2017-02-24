#include <iostream>
#include <vector>
#include <iterator>
#include <algorithm>

using namespace std;

struct 
{
    bool operator()(string a, string b)
    {   
        if (a[0] < b[0])
        {
            return true;
        }
        if (a[0] == b[0])
        {
            if (a[1] < b[1])
                return true;
        }        
        return false;
    }
    
} sort_of_sort;

struct 
{
    bool operator()(string a)
    {   
        // Se till att namnet uppfyller kraven.
        if (a.size() < 2 || a.size() > 20)
        {
            return true;
        }
        for (char c : a)
        {
            if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')))
            {
                return true;
            }
        }
        return false;
    }
    
} check_name;

int main()
{
    int count;
    unsigned test_count {0};
    string delim {""};
    while(cin >> count)
    {
        if (count == 0)
            break;

        else if (count < 0 || count > 200) // Ignorera nästa testfall om count är felaktig.
        {
            // Släng bort resten av testfallet.
            while (true)
            {
                string next;
                next = cin.peek();
                // Kolla om kommande tecken från strömmen är en siffra.
                if (find_if(next.begin(), next.end(), [](char c) { return !isdigit(c); }) == next.end())
                    // Ja? - Börja med nästa testfall.
                    break;
                    // Nej? - Extrahera.
                cin.get();
            }
            continue;
        }
        
        ++test_count;
        if (test_count > 500) // För många testfall. Stäng ner programmet.
            break;

        vector<string> students;
    
        /*
        // Fyll vector students med count st. namn från inläsningsströmmen.
        copy_n(istream_iterator<string>{cin}, count, back_inserter(students));
        */
        for (int i = 0; i < count; ++i)
        {
            cin >> ws;
            string name;
            getline(cin, name);
            if (!check_name(name))      // Den kanske bara inte ska lägga till namnet om det är felaktigt
                students.push_back(name);
        }

        /*
        // Släng bort testfallet om namnet är fel.
        if (any_of(students.begin(), students.end(), check_name))
            continue;
        */

        // Sortera med funktionsobjektet sort_of_sort.
        sort(students.begin(), students.end(), sort_of_sort);

        cout << delim;
        delim = "\n";
        copy(students.begin(),students.end(), ostream_iterator<string>(cout, "\n"));
    }

    return 0;
}
#include<bits/stdc++.h>
using namespace std;


mt19937 rnd(time(nullptr));
const string lorem = "Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod "
                         "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
                         "veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
                         "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
                         "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
                         "occaecat cupidatat non proident sunt in culpa qui officia deserunt "
                         "mollit anim id est laborum.";
vector < string > words;
inline string get_random_text(){
    random_shuffle(words.begin(), words.end());
    string s;
    int x = rnd() % 241 + 10;
    for(int i = 0; i < words.size(); i++){
        if(s.size() + words[i].size() <= x){
            s += words[i];
        }
    }
    if(s.back() == ' '){
        s.pop_back();
    }
    return s;
}


int main(){
    string s;
    for(int i = 0; i < lorem.size(); i++){
        s += lorem[i];
        if(lorem[i] == ' '){
            words.push_back(s);
            s = "";
        }
    }
    s += ' ';
    words.push_back(s);
    freopen("messages.txt", "w", stdout);
    for(int i = 1; i <= 5000; i++){
        int x = rnd() % 100 + 1,
            y = rnd() % 100 + 1;
        if(x == y){
            i--;
            continue;
        }
        cout << x << "," << y << "," << get_random_text() << "\n";
    }
}


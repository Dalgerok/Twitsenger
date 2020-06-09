#include<bits/stdc++.h>
using namespace std;



const string lorem = "Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod "
                         "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
                         "veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
                         "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
                         "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
                         "occaecat cupidatat non proident sunt in culpa qui officia deserunt "
                         "mollit anim id est laborum.";
vector < string > words;

mt19937 rnd(time(nullptr));

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
    ///ios_base::sync_with_stdio(0);cin.tie(0);cout.tie(0);
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
    freopen("posts.txt", "w", stdout);
    int n = 100;
    int x = 0;
    for(int i = 1; i <= 500; i++){
        int x = rnd() % n + 1;
        int y = rnd() % i + 1;
        if(rand() % 3 != 0){
            cout << x << "," << get_random_text() << "2020-01-08 04:05:06 << "," << "\n";
        }
        else{
            cout << x << "," << get_random_text() << "," << y << "\n";
        }
    }
}

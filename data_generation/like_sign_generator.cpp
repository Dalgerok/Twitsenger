#include<bits/stdc++.h>
using namespace std;


mt19937 rnd(time(nullptr));

int main(){
    freopen("likesign.txt", "w", stdout);
    map < pair < int, int >, bool > q;
    for(int i = 1; i <= 1000; i++){
        int x = rnd() % 100 + 1, y = rnd() % 500 + 1;
        auto it = make_pair(x, y);
        while(q.find(it) != q.end()){
            x = rnd() % 100 + 1, y = rnd() % 500 + 1;
            it = make_pair(x, y);
        }
        q[make_pair(x, y)] = q[make_pair(y, x)] = true;
        cout << x << "," << y << "\n";
    }
}

#include<bits/stdc++.h>
using namespace std;


mt19937 rnd(time(nullptr));

int main(){
    //ios_base::sync_with_stdio(0);cin.tie(0);cout.tie(0);
    freopen("friendship.txt", "w", stdout);
    int n = 100;
    //int Z = 1000;
    //int sum_mn = 0, sum_mx = 0;
    while(true){
        map < pair < int, int >, bool > q;
        for(int i = 1; i <= n; i++){
            q[make_pair(i, i)] = true;
        }
        vector < pair < int, int > > ans;
        int deg[n + 1];
        memset(deg, 0, sizeof(deg));
        for(int i = 1; i <= 1200; i++){
            int x = rnd() % n + 1, y = rnd() % n + 1;
            auto it = make_pair(x, y);
            while(q.find(it) != q.end()){
                x = rnd() % n + 1;
                y = rnd() % n + 1;
                it = make_pair(x, y);
            }
            q[make_pair(x, y)] = q[make_pair(y, x)] = true;
            deg[x]++;
            deg[y]++;
            ans.push_back(make_pair(x, y));
        }
        int mn = +1e9, mx = -1e9;
        for(int i = 1; i <= n; i++){
            mn = min(mn, deg[i]);
            mx = max(mx, deg[i]);
        }
        if(mn == 13 && mx == 35){
            for(auto it : ans){
                if(it.first == it.second){
                    exit(1337);
                }
                cout << it.first << "," << it.second << endl;
            }
            return 0;
        }
        //sum_mn += mn;
        //sum_mx += mx;
        //cout << mn << " " << mx << "\n";
    }
    /// sum_mn / 1000 = 13, sum_mx / 1000 = 35
}

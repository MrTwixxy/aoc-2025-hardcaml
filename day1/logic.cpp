#include <bits/stdc++.h>

using namespace std;

int new_counter(int previous, int val) {
  int next = (previous += val) % 100;
  if (next < 0)
    next += 100;
  return next;
}

void solve() {
  // This script requires you to add the number of lines at the top of the file
  int n;
  cin >> n;

  int part1 = 0;
  int part2 = 0;

  int position = 50;

  for (int i = 0; i < n; i++) {
    char d;
    int val;

    cin >> d >> val;

    bool positive = false;
    if (d == 'R')
      positive = true;

    if (d == 'L')
      val *= -1;

    part2 += abs(val) / 100;

    val = val % 100;

    int new_pos = new_counter(position, val);

    if (new_pos == 0)
      part1++;

    if (position != 0 && new_pos != 0 && !positive && new_pos > position)
      part2++;
    if (position != 0 && new_pos != 0 && positive && new_pos < position)
      part2++;

    if (position != 0 && new_pos == 0)
      part2++;

    position = new_pos;
  }

  cout << part1 << endl;
  cout << part2 << endl;
}

signed main() {
  ios::sync_with_stdio(0);
  cin.tie(0);

  //   int t;
  //   cin >> t;
  //   for (int i = 0; i < t; i++)
  solve();

  return 0;
}
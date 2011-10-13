// 带路径压缩的并查集,用于动态维护查询等价类
// 图论算法中动态判点集连通常用
// 维护和查询复杂度略大于O(1)
// 集合元素取值1..MAXN-1(注意0不能用!),默认不等价

const int MAXN = 100000;

#include <cstring>
#define _run(x) for(; p[t = x]; x = p[x], p[t] = (p[x] ? p[x] : x))
#define _run_both _run(i); _run(j)

class DSet {
public:
	int p[MAXN],t;
	
	void init() {
		memset(p, 0, sizeof(p));
	}

	void setFriend(int i, int j) {
		_run_both;
		p[i] = (i == j ? 0 : j);
	}

	bool isFriend(int i, int j) {
		_run_both;
		return i == j && i;
	}
};

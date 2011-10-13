//无向图最小生成树,prim算法,邻接阵形式,复杂度O(n^2)
//返回最小生成树的长度,传入图的大小n和邻接阵mat,不相邻点边权INF
//可更改边权的类型,pre[]返回树的构造,用父结点表示,根节点(第一个)pre值为-1
//必须保证图的连通的!
const int MAXN = 200;
const int INF = 1000000000;

template <class elemType>
elemType prim(int n, const elemType mat[][MAXN], int * pre) {
	elemType mind[MAXN], ret = 0;
	int v[MAXN], i, j, k;
	for (i = 0; i<n; i++) {
		mind[i] = INF;
		v[i] = 0;
		pre[i] = -1;
	}
	for (mind[j = 0] = 0; j<n; j++) {
		for (k = -1, i = 0; i<n; i++) {
			if (!v[i] && (k == -1 || mind[i]<mind[k])) {
				k = i;
			}
		}
		v[k] = 1;
		ret += mind[k];
		for (i = 0; i < n; i++) {
			if (!v[i] && mat[k][i] < mind[i]) {
				mind[i] = mat[pre[i] = k][i];
			}
		}
	}
	return ret;
}

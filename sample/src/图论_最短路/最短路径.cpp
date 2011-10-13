//单源最短路径,用于路权相等的情况,dijkstra优化为bfs,邻接表形式,复杂度O(m)
//求出源s到所有点的最短路经,传入图的大小n和邻接表list,边权值len
//返回到各点最短距离mind[]和路径pre[],pre[i]记录s到i路径上i的父结点,pre[s]=-1
//可更改路权类型,但必须非负且相等!
const int MAXN = 200;
const int INF = 1000000000;

struct Edge {
	int from, to;
	Edge * next;
};

template <class elemType> void dijkstra(int n, const Edge * list[], elemType len, int s, elemType * mind, int * pre) {
	Edge * t;
	int i, que[MAXN], f = 0, r = 0, p = 1, L = 1;
	for (i = 0; i<n; i++) {
		mind[i] = INF;
	}
	mind[que[0] = s] = 0;
	pre[s] = -1;
	for (; r <= f; L++, r = f + 1, f = p - 1) {
		for (i = r; i <= f; i++) {
			for (t = list[que[i]]; t; t = t->next) {
				if (mind[t->to] == INF) {
					mind[que[p++] = t->to] = len * L;
					pre[t->to] = que[i];
				} 
			} 
		}
	}
}

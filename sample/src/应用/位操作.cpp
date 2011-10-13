// 遍历一个掩码的所有子集掩码,不包括0和其自身
// 传入表示超集的掩码
void iterateSubset(int mask)
{
	for(int sub = (mask - 1) & mask; sub > 0; sub = (sub - 1) & mask)
	{
		int incsub = ~sub & mask; // 递增顺序的子集
		// gogogo
	}
}

// 求一个32位整数二进制1的位数
// 初始化函数先调用一次

int ones[256];

void initOnes()
{
	for (int i = 1; i < 256; ++i)
		ones[i] = ones[i & (i - 1)] + 1;
}

int countOnes(int n)
{
	return ones[n & 255] + ones[(n >> 8) & 255] + ones[(n >> 16) & 255] + ones[(n >> 24) & 255];
}

// 求一个32位整数二进制1的位数的奇偶性
// 偶数返回0,奇数返回1
int parityOnes(unsigned n)
{
	n ^= n >> 1;
	n ^= n >> 2;
	n ^= n >> 4;
	n ^= n >> 8;
	n ^= n >> 16;
	return n & 1; // n的第i位是原数第i位到最左侧位的奇偶性
}



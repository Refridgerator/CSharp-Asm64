#define _USE_MATH_DEFINES
#include <math.h>

//extern "C"
//{
	//int zero();
	//double ht_asm(double* data, double* result, int size);
	//double rmse_asm(double* data1, double* data2, int size);
//}

void ht_cpp(double* data, double* result, int n)
{
	double phi = 2.0 * M_PI / n;
	for (int i = 0; i < n; ++i)
	{
		double sum = 0.0;
		for (int j = 0; j < n; ++j)
		{
			double w = phi * i * j;
			sum += data[j] * (cos(w) + sin(w));
		}
		result[i] = sum / sqrt(n);
	}
}


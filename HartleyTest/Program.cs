using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace HartleyTest
{
    class Program
    {
        [DllImport("ht.dll")]
        private static extern void ht_cpp(IntPtr data, IntPtr result, int size);
        [DllImport("ht.dll")]
        private static extern void ht_asm(IntPtr data, IntPtr result, int size);

        static void ht_csharp(double[] data, double[] result)
        {
            int n = data.Length;
            double phi = 2.0 * Math.PI / n;
            for (int i = 0; i < n; ++i)
            {
                double sum = 0.0;
                for (int j = 0; j < n; ++j)
                {
                    double w = phi * i * j;
                    sum += data[j] * (Math.Cos(w) + Math.Sin(w));
                }
                result[i] = sum / Math.Sqrt(n);
            }
        }


        static double MeanSquaredError(double[] data1, double[] data2)
        {
            double sum = 0;
            for (int i = 0; i < data1.Length; i++)
            {
                double df = data1[i] - data2[i];
                sum += df * df;
            }
            return Math.Sqrt(sum);
        }

        static void Main(string[] args)
        {
            double[] data_src = new double[10000];
            for (int i = 0; i < data_src.Length; i++)
                data_src[i] = i + 1;
            double[] data_in = new double[data_src.Length];
            double[] data_out = new double[data_src.Length];

            Stopwatch sw = new Stopwatch();

            // ассемблер
            Array.Copy(data_src, data_in, data_src.Length);
            sw.Restart();
            unsafe
            {
                fixed (double* pdata_in = &data_in[0])
                fixed (double* pdata_out = &data_out[0])
                {
                    ht_asm(new IntPtr(pdata_in), new IntPtr(pdata_out), data_in.Length);
                    ht_asm(new IntPtr(pdata_out), new IntPtr(pdata_in), data_in.Length);
                }
            }
            var sw_asm = sw.ElapsedMilliseconds / 1000.0;
            var err_asm = MeanSquaredError(data_src, data_in);
            Console.WriteLine("   asm : {0}\terr : {1:0.0000000000e+00}", sw_asm, err_asm);

            // c++
            Array.Copy(data_src, data_in, data_src.Length);
            sw.Restart();
            unsafe
            {
                fixed (double* pdata_in = &data_in[0])
                fixed (double* pdata_out = &data_out[0])
                {
                    ht_cpp(new IntPtr(pdata_in), new IntPtr(pdata_out), data_in.Length);
                    ht_cpp(new IntPtr(pdata_out), new IntPtr(pdata_in), data_in.Length);
                }
            }
            var sw_cpp = sw.ElapsedMilliseconds / 1000.0;
            var err_cpp = MeanSquaredError(data_src, data_in);
            Console.WriteLine("   cpp : {0}\terr : {1:0.0000000000e+00}", sw_cpp, err_cpp);

            // c#
            Array.Copy(data_src, data_in, data_src.Length);
            sw.Restart();
            ht_csharp(data_in, data_out);
            ht_csharp(data_out, data_in);
            var sw_csharp = sw.ElapsedMilliseconds / 1000.0;
            var err_csharp = MeanSquaredError(data_src, data_in);
            Console.WriteLine("csharp : {0}\terr : {1:0.0000000000e+00}", sw_csharp, err_csharp);

            // относительное время
            Console.WriteLine();
            Console.WriteLine("csharp/asm : {0:0.0}", sw_csharp / sw_asm);
            Console.WriteLine("csharp/c++ : {0:0.0}", sw_csharp / sw_cpp);
            Console.WriteLine("   c++/asm : {0:0.0}", sw_cpp / sw_asm);
            // ожидание завершения
            Console.ReadLine();
        }
    }
}

using System;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

if (await Task.Run(() => 6 * 7) != 42)
    throw new Exception("Task failed");
if (SHA256.HashData(Encoding.UTF8.GetBytes("smoke")).Length != 32)
    throw new Exception("SHA256 failed");
Console.WriteLine(42.ToString("N2", CultureInfo.GetCultureInfo("en-US")));
Console.WriteLine("dotnet smoke ok");

using System;
using System.Security.Cryptography;
using System.Text;
using Windows.Security.Cryptography;
using Windows.Security.Cryptography.DataProtection;

namespace KhandobaSecureDocs.Services
{
    public class EncryptionService
    {
        // AES-256-GCM encryption (like CryptoKit)
        public async Task<byte[]> EncryptAES256GCMAsync(byte[] data, byte[] key)
        {
            using var aes = Aes.Create();
            aes.Key = key;
            aes.Mode = CipherMode.GCM;
            aes.GenerateIV();

            using var encryptor = aes.CreateEncryptor();
            using var ms = new System.IO.MemoryStream();

            // Write IV
            ms.Write(aes.IV, 0, aes.IV.Length);

            // Encrypt data
            using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
            {
                await cs.WriteAsync(data, 0, data.Length);
            }

            // Get authentication tag (GCM)
            var tag = aes.Tag;
            ms.Write(tag, 0, tag.Length);

            return ms.ToArray();
        }

        public async Task<byte[]> DecryptAES256GCMAsync(byte[] encryptedData, byte[] key)
        {
            using var aes = Aes.Create();
            aes.Key = key;
            aes.Mode = CipherMode.GCM;

            // Extract IV (first 12 bytes for GCM)
            var iv = new byte[12];
            Array.Copy(encryptedData, 0, iv, 0, 12);
            aes.IV = iv;

            // Extract tag (last 16 bytes)
            var tag = new byte[16];
            Array.Copy(encryptedData, encryptedData.Length - 16, tag, 0, 16);
            aes.Tag = tag;

            // Extract ciphertext (middle part)
            var ciphertext = new byte[encryptedData.Length - 12 - 16];
            Array.Copy(encryptedData, 12, ciphertext, 0, ciphertext.Length);

            using var decryptor = aes.CreateDecryptor();
            using var ms = new System.IO.MemoryStream(ciphertext);
            using var cs = new CryptoStream(ms, decryptor, CryptoStreamMode.Read);
            using var result = new System.IO.MemoryStream();

            await cs.CopyToAsync(result);
            return result.ToArray();
        }

        // Windows Data Protection API (DPAPI)
        public async Task<byte[]> EncryptWithDPAPIAsync(byte[] data)
        {
            var provider = new DataProtectionProvider("LOCAL=user");
            var buffer = CryptographicBuffer.CreateFromByteArray(data);
            var encryptedBuffer = await provider.ProtectAsync(buffer);

            CryptographicBuffer.CopyToByteArray(encryptedBuffer, out byte[] encrypted);
            return encrypted;
        }

        public async Task<byte[]> DecryptWithDPAPIAsync(byte[] encryptedData)
        {
            var provider = new DataProtectionProvider("LOCAL=user");
            var buffer = CryptographicBuffer.CreateFromByteArray(encryptedData);
            var decryptedBuffer = await provider.UnprotectAsync(buffer);

            CryptographicBuffer.CopyToByteArray(decryptedBuffer, out byte[] decrypted);
            return decrypted;
        }

        // Derive key from password
        public byte[] DeriveKeyFromPassword(string password, byte[] salt, int iterations = 10000)
        {
            using var rfc2898 = new Rfc2898DeriveBytes(
                Encoding.UTF8.GetBytes(password),
                salt,
                iterations
            );
            return rfc2898.GetBytes(32); // 256-bit key
        }

        // Hash password
        public string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hash);
        }
    }
}


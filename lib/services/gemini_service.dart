import 'package:google_generative_ai/google_generative_ai.dart';

// Custom exception for invalid API keys
class InvalidApiKeyException implements Exception {
  final String message;
  InvalidApiKeyException(this.message);

  @override
  String toString() => message;
}

class GeminiService {
  Future<String> improveText({
    required String apiKey,
    required String text,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('API key tidak ditemukan. Harap masukkan API Key Anda.');
    }
    if (text.trim().isEmpty) {
      throw Exception('Catatan tidak boleh kosong.');
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final prompt = '''
Berikut ini adalah catatan kuliah mingguan yang ditulis secara acak dan tidak terstruktur oleh mahasiswa. Tugas Anda adalah menyusunnya ulang menjadi catatan yang rapi, terstruktur, dan mudah dipahami oleh mahasiswa lain.

Silakan lakukan hal berikut:

1. Rapikan struktur penulisan menjadi paragraf yang logis dan jelas
2. Tambahkan heading/subjudul jika diperlukan
3. Gunakan bahasa semi-formal yang jelas namun tidak kaku
4. Jika terdapat informasi yang tidak lengkap, **lengkapi atau perjelas informasinya berdasarkan pengetahuan umum yang benar**
5. **Tulis rumus matematika langsung dalam bentuk teks biasa, bukan dalam format LaTeX atau HTML**
6. **Jangan gunakan simbol markdown seperti `#`, `*`, `-`, atau tag khusus lainnya**
7. Hasil akhir berupa teks paragraf biasa, bukan markdown

Berikut isi catatan mentahnya:
$text


''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        return response.text!;
      } else {
        throw Exception('Gagal mendapatkan respons dari AI. Coba lagi.');
      }
    } on Exception catch (e) {
      // The Gemini API throws an exception that contains "API key not valid" for bad keys.
      if (e.toString().toLowerCase().contains('api key not valid')) {
        throw InvalidApiKeyException('API Key tidak valid. Silakan masukkan kembali.');
      }
      // You can add more specific error handling here based on Gemini API documentation
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }
} 
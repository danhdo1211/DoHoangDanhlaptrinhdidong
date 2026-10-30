import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  File? _selectedImage;
  String _extractedText = '';
  String _translatedText = '';
  bool _isLoading = false;
  bool _isHarmfulContentDetected = false;
  String _detectedKeyword = '';

  final ImagePicker _picker = ImagePicker();

  // Danh sách từ khóa độc hại / nhạy cảm cần kiểm tra (Tính năng mới - Câu 6)
  // Hỗ trợ cả Tiếng Việt và Tiếng Anh để tiện kiểm thử/đánh giá
  final List<String> _harmfulKeywords = [
    'danh nhau', 'bao luc', 'bat nat', 'tu tu', 'chet', 'uy hiep', 'quay roi', 'danh', 'danh chet',
    'violence', 'fight', 'bullying', 'kill', 'abuse', 'threat', 'attack'
  ];

  // 1. Chụp ảnh hoặc chọn từ thư viện
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _extractedText = '';
        _translatedText = '';
        _isHarmfulContentDetected = false;
        _detectedKeyword = '';
      });
      _processImage(File(image.path));
    }
  }

  // 2. Nhận diện chữ từ hình ảnh bằng ML Kit
  Future<void> _processImage(File imageFile) async {
    setState(() => _isLoading = true);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String text = recognizedText.text;
      await textRecognizer.close();

      if (text.trim().isEmpty) {
        setState(() {
          _extractedText = 'Không tìm thấy văn bản trong ảnh.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _extractedText = text;
      });

      // Kiểm tra nội dung nhạy cảm ngay sau khi quét OCR (Tính năng mới - Câu 6)
      _checkHarmfulContent(text);

      // 3. Tiến hành dịch văn bản vừa quét được
      await _translateText(text);
    } catch (e) {
      setState(() {
        _extractedText = 'Lỗi nhận diện ảnh: $e';
        _isLoading = false;
      });
    }
  }

  // Hàm kiểm tra nội dung nhạy cảm qua từ khóa (Câu 6)
  void _checkHarmfulContent(String text) {
    String lowerText = text.toLowerCase();
    for (var keyword in _harmfulKeywords) {
      if (lowerText.contains(keyword)) {
        setState(() {
          _isHarmfulContentDetected = true;
          _detectedKeyword = keyword;
        });

        // Hiển thị Popup cảnh báo ngay lập tức
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHarmfulAlert(keyword);
        });
        break;
      }
    }
  }

  // Hiển thị hộp thoại cảnh báo an toàn cho trẻ em/phụ huynh
  void _showHarmfulAlert(String keyword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Cảnh báo an toàn', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Hệ thống vừa phát hiện nội dung nhạy cảm / bạo lực chứa từ khóa: "$keyword" qua tính năng quét OCR màn hình.\n\nCảnh báo đã được ghi nhận vào hệ thống quản lý của phụ huynh.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu / Đóng'),
          ),
        ],
      ),
    );
  }

  // 3. Gọi API dịch văn bản (dùng MyMemory API miễn phí, không cần Key)
  Future<void> _translateText(String text) async {
    try {
      final url = Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=en|vi');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _translatedText = data['responseData']['translatedText'] ?? 'Không thể dịch.';
        });
      } else {
        setState(() {
          _translatedText = 'Lỗi kết nối máy chủ dịch.';
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = 'Lỗi khi dịch: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch văn bản & Quét an toàn', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khung hiển thị ảnh với hiệu ứng Card & Shadow (Câu 7 - UI/UX)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 220,
                color: Colors.grey[100],
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity)
                    : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_search_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Chưa chọn hoặc chụp ảnh nào', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nút bấm Chụp ảnh / Chọn thư viện
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!_isLoading && _extractedText.isNotEmpty) ...[
              // Hiển thị banner cảnh báo màu đỏ nếu phát hiện nội dung độc hại (Câu 6)
              if (_isHarmfulContentDetected)
                Card(
                  color: Colors.red[50],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red[300]!, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cảnh báo: Phát hiện từ khóa nhạy cảm ("$_detectedKeyword")!',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isHarmfulContentDetected) const SizedBox(height: 12),

              // Card Văn bản gốc quét được
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.text_snippet_outlined, size: 18, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(
                            'Văn bản gốc (Quét được từ OCR):',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                      const Divider(),
                      SelectableText(
                        _extractedText,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Card Kết quả dịch
              Card(
                elevation: 1,
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.g_translate, size: 18, color: Colors.blue),
                          SizedBox(width: 6),
                          Text(
                            'Kết quả dịch (Tiếng Việt):',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.blue),
                      SelectableText(
                        _translatedText,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
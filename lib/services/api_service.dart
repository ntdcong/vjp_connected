import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/business.dart';
import '../models/message.dart';

class ApiService {
static String get baseUrl {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        // Check if running on emulator by checking localhost
        bool isEmulator = false;
        try {
          final socket = Socket.connect('10.0.2.2', 8000, timeout: Duration(seconds: 1));
          socket.then((value) {
            value.destroy();
            isEmulator = true;
          });
        } catch (_) {
          isEmulator = false;
        }
        
        return isEmulator 
            ? 'http://10.0.2.2:8000/api/v1'      // Android emulator
            : 'http://192.168.0.161:8000/api/v1'; // Real device
      } else if (Platform.isIOS) {
        return 'http://localhost:8000/api/v1';    // iOS simulator
      }
    }
    return 'http://localhost:8000/api/v1';        // Web
  }

  static String sanitizeUrl(String? url) {
    if (url == null) return '';
    return url.contains('<br />') ? url.replaceAll('<br />', '').trim() : url;
  }

  // Lưu token cho các request yêu cầu xác thực
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Headers cho các request yêu cầu xác thực
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Authentication API
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final requestBody = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    print('Register request: $requestBody');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('Register response status code: ${response.statusCode}');
      print('Register response full: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('Register exception: $e');
      return {'status': 'error', 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final requestBody = {'email': email, 'password': password};
    print('Login request: $requestBody');
    print('Login URL: ${Uri.parse('$baseUrl/auth/login')}');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Thêm timeout để tránh chờ quá lâu

      print('Login response status code: ${response.statusCode}');
      print('Login response full: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Hiển thị token nhận được
          print('Token nhận được: ${data['data']['token']['access_token']}');
          await saveToken(data['data']['token']['access_token']);
        }
        return data;
      } else {
        print('Login failed with status code: ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'Đăng nhập thất bại với mã lỗi: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Login exception: $e');
      return {'status': 'error', 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // User API
  Future<User> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: await getAuthHeaders(),
    );

    final data = jsonDecode(response.body);
    return User.fromJson(data['data']);
  }

  // Business API
  Future<List<Business>> getAllBusinesses() async {
    try {
      print('Đang tải getAllBusinesses từ: $baseUrl/businesses');
      final response = await http
          .get(Uri.parse('$baseUrl/businesses'))
          .timeout(const Duration(seconds: 10));

      print('getAllBusinesses status code: ${response.statusCode}');
      print('getAllBusinesses response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['status'] != 'success') {
        throw Exception('API trả về lỗi: ${data['message']}');
      }

      // Xử lý trường hợp data là null hoặc không phải danh sách
      if (data['data'] == null) {
        return [];
      }

      // Log dữ liệu đầu tiên để debug
      if ((data['data'] as List).isNotEmpty) {
        print('Business đầu tiên: ${data['data'][0]}');
      }

      return (data['data'] as List)
          .map((businessJson) => Business.fromJson(businessJson))
          .toList();
    } catch (e) {
      print('Error in getAllBusinesses: $e');
      throw Exception('Không thể tải danh sách doanh nghiệp: $e');
    }
  }

  Future<Business> getBusinessById(int id) async {
    try {
      print(
        'Đang tải getBusinessById với id=$id từ: $baseUrl/businesses/detail?id=$id',
      );
      final response = await http
          .get(Uri.parse('$baseUrl/businesses/detail?id=$id'))
          .timeout(const Duration(seconds: 10));

      print('getBusinessById status code: ${response.statusCode}');
      print('getBusinessById response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['status'] != 'success') {
        throw Exception('API trả về lỗi: ${data['message']}');
      }

      if (data['data'] == null) {
        throw Exception('Không tìm thấy thông tin doanh nghiệp với ID: $id');
      }

      return Business.fromJson(data['data']);
    } catch (e) {
      print('Error in getBusinessById: $e');
      throw Exception('Không thể tải thông tin doanh nghiệp: $e');
    }
  }

  Future<List<Business>> getBusinessesByOwner() async {
    try {
      print('Đang tải getBusinessesByOwner từ: $baseUrl/businesses/owner');
      final headers = await getAuthHeaders();
      print('Auth Headers: $headers');

      final response = await http
          .get(Uri.parse('$baseUrl/businesses/owner'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('getBusinessesByOwner status code: ${response.statusCode}');
      print('getBusinessesByOwner response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['status'] != 'success') {
        throw Exception('API trả về lỗi: ${data['message']}');
      }

      // Xử lý trường hợp data là null hoặc không phải danh sách
      if (data['data'] == null) {
        return [];
      }

      // Log dữ liệu đầu tiên để debug
      if ((data['data'] as List).isNotEmpty) {
        print('Owner Business đầu tiên: ${data['data'][0]}');
      }

      return (data['data'] as List)
          .map((businessJson) => Business.fromJson(businessJson))
          .toList();
    } catch (e) {
      print('Error in getBusinessesByOwner: $e');
      throw Exception('Không thể tải danh sách doanh nghiệp của bạn: $e');
    }
  }

  Future<Map<String, dynamic>> createBusiness(
    Map<String, dynamic> businessData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/businesses/create'),
      headers: await getAuthHeaders(),
      body: jsonEncode(businessData),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateBusiness(
    Map<String, dynamic> businessData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/businesses/update'),
      headers: await getAuthHeaders(),
      body: jsonEncode(businessData),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteBusiness(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/businesses/delete'),
      headers: await getAuthHeaders(),
      body: jsonEncode({'id': id}),
    );

    return jsonDecode(response.body);
  }

  // Message API
  Future<List<Conversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversations'),
      headers: await getAuthHeaders(),
    );

    final data = jsonDecode(response.body);
    return (data['data'] as List)
        .map((conversationJson) => Conversation.fromJson(conversationJson))
        .toList();
  }

  Future<List<Message>> getConversation(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversation?user_id=$userId'),
      headers: await getAuthHeaders(),
    );

    final data = jsonDecode(response.body);
    return (data['data'] as List)
        .map((messageJson) => Message.fromJson(messageJson))
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    int receiverId, {
    String? content,
    File? image,
  }) async {
    final uri = Uri.parse('$baseUrl/messages/send');
    final request = http.MultipartRequest('POST', uri);

    // Thêm headers
    final headers = await getAuthHeaders();
    request.headers.addAll(headers);

    // Thêm receiver_id
    request.fields['receiver_id'] = receiverId.toString();

    // Thêm content nếu có
    if (content != null && content.isNotEmpty) {
      request.fields['content'] = content;
    }

    // Thêm image nếu có
    if (image != null) {
      final stream = http.ByteStream(image.openRead());
      final length = await image.length();
      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: image.path.split('/').last,
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteMessage(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/messages/delete'),
      headers: await getAuthHeaders(),
      body: jsonEncode({'id': id}),
    );

    return jsonDecode(response.body);
  }

  // Kiểm tra trạng thái kết nối của API server
  Future<bool> checkApiConnection() async {
    try {
      print('Device Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other'}');
      print('Is Web: $kIsWeb');
      print('Checking API connection at URL: $baseUrl');
      
      // Try direct businesses endpoint since it's known to work in browser
      final response = await http
          .get(Uri.parse('$baseUrl/businesses'))
          .timeout(const Duration(seconds: 10));

      print('API check response status: ${response.statusCode}');
      print('API check response body: ${response.body}');
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('API connection check failed with error: $e');
      return false;
    }
  }
}

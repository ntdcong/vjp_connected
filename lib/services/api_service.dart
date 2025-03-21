import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/business.dart';
import '../models/message.dart';

class ApiService {
  // API Base URL - thay thế localhost bằng 10.0.2.2 cho Android emulator
  static String get baseUrl {
    // Sử dụng 10.0.2.2 cho Android Emulator để trỏ đến localhost của máy host
    // Sử dụng localhost cho iOS Simulator hoặc thiết bị thực
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
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
  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final requestBody = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    print('Register request: $requestBody');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));
  
      print('Register response status code: ${response.statusCode}');
      print('Register response full: ${response.body}');
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Register exception: $e');
      return {
        'status': 'error',
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final requestBody = {
      'email': email,
      'password': password,
    };
    print('Login request: $requestBody');
    print('Login URL: ${Uri.parse('$baseUrl/auth/login')}');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10)); // Thêm timeout để tránh chờ quá lâu
      
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
      return {
        'status': 'error',
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
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
      final response = await http.get(
        Uri.parse('$baseUrl/businesses'),
      ).timeout(const Duration(seconds: 10));
      
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
      // Thử phương pháp khác để truyền ID - dùng path thay vì query parameter
      print('Đang tải getBusinessById với id=$id từ: $baseUrl/businesses/$id');
      final response = await http.get(
        Uri.parse('$baseUrl/businesses/$id'),
      ).timeout(const Duration(seconds: 10));

      // Nếu không được, thử sử dụng id thay vì ID trong query parameter
      if (response.statusCode != 200 || jsonDecode(response.body)['status'] == 'error') {
        print('Thử phương pháp truyền tham số khác: id thay vì ID');
        final alternativeResponse = await http.get(
          Uri.parse('$baseUrl/businesses/detail?id=$id'),
        ).timeout(const Duration(seconds: 10));
        
        print('getBusinessById alternative status code: ${alternativeResponse.statusCode}');
        print('getBusinessById alternative response body: ${alternativeResponse.body}');
        
        final data = jsonDecode(alternativeResponse.body);
        
        if (data['status'] != 'success') {
          // Thử phương pháp cuối cùng - truyền ID trong body
          final postResponse = await http.post(
            Uri.parse('$baseUrl/businesses/detail'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': id}),
          ).timeout(const Duration(seconds: 10));
          
          print('getBusinessById POST status code: ${postResponse.statusCode}');
          print('getBusinessById POST response body: ${postResponse.body}');
          
          final postData = jsonDecode(postResponse.body);
          
          if (postData['status'] != 'success') {
            throw Exception('API trả về lỗi: ${postData['message'] ?? "Không thể tải thông tin"}');
          }
          
          if (postData['data'] == null) {
            throw Exception('Không tìm thấy thông tin doanh nghiệp với ID: $id');
          }
          
          return Business.fromJson(postData['data']);
        }
        
        if (data['data'] == null) {
          throw Exception('Không tìm thấy thông tin doanh nghiệp với ID: $id');
        }
        
        return Business.fromJson(data['data']);
      }
      
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/businesses/owner'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

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

  Future<Map<String, dynamic>> createBusiness(Map<String, dynamic> businessData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/businesses/create'),
      headers: await getAuthHeaders(),
      body: jsonEncode(businessData),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateBusiness(Map<String, dynamic> businessData) async {
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

  Future<Map<String, dynamic>> sendMessage(int receiverId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/send'),
      headers: await getAuthHeaders(),
      body: jsonEncode({
        'receiver_id': receiverId,
        'content': content,
      }),
    );

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
      print('Kiểm tra kết nối API với URL: $baseUrl');
      // Thử ping máy chủ với endpoint bất kỳ thay vì health-check
      final response = await http.get(
        Uri.parse('$baseUrl/auth/ping'),
      ).timeout(const Duration(seconds: 5));
      
      print('API health-check status code: ${response.statusCode}');
      
      // Nếu không có kết quả hoặc lỗi, thử ping trực tiếp máy chủ cơ sở
      if (response.statusCode >= 400) {
        final baseResponse = await http.get(
          Uri.parse('http://localhost:8000/'),
        ).timeout(const Duration(seconds: 5));
        print('Base server status code: ${baseResponse.statusCode}');
      }
      
      // Giả định kết nối OK vì nhiều máy chủ có thể không có health-check
      return true;
    } catch (e) {
      print('API connection check failed: $e');
      // Thử ping một lần nữa trực tiếp tới máy chủ
      try {
        final baseResponse = await http.get(
          Uri.parse('http://localhost:8000/'),
        ).timeout(const Duration(seconds: 5));
        print('Base server retry status code: ${baseResponse.statusCode}');
        return true;
      } catch (e2) {
        print('Base server ping also failed: $e2');
        return false;
      }
    }
  }
} 
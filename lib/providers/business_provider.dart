import 'package:flutter/material.dart';
import '../models/business.dart';
import '../services/api_service.dart';

class BusinessProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Business> _businesses = [];
  List<Business> _myBusinesses = [];
  Business? _selectedBusiness;
  bool _isLoading = false;
  String? _error;

  List<Business> get businesses => _businesses;
  List<Business> get myBusinesses => _myBusinesses;
  Business? get selectedBusiness => _selectedBusiness;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllBusinesses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _businesses = await _apiService.getAllBusinesses();
    } catch (e) {
      _error = 'Không thể tải danh sách doanh nghiệp: ${e.toString()}';
      print('Chi tiết lỗi fetchAllBusinesses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyBusinesses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myBusinesses = await _apiService.getBusinessesByOwner();
    } catch (e) {
      _error = 'Không thể tải doanh nghiệp của bạn: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBusinessById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedBusiness = await _apiService.getBusinessById(id);
    } catch (e) {
      _error = 'Không thể tải thông tin doanh nghiệp: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBusiness(Map<String, dynamic> businessData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createBusiness(businessData);
      if (response['status'] == 'success') {
        await fetchMyBusinesses();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Tạo doanh nghiệp thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateBusiness(Map<String, dynamic> businessData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateBusiness(businessData);
      if (response['status'] == 'success') {
        await fetchMyBusinesses();
        
        // Cập nhật selectedBusiness nếu đó là doanh nghiệp đang được chọn
        if (_selectedBusiness != null && _selectedBusiness!.id == businessData['id']) {
          await fetchBusinessById(businessData['id']);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Cập nhật doanh nghiệp thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteBusiness(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteBusiness(id);
      if (response['status'] == 'success') {
        // Xóa doanh nghiệp khỏi danh sách local
        _myBusinesses.removeWhere((business) => business.id == id);
        
        // Nếu đang chọn doanh nghiệp này thì xóa selection
        if (_selectedBusiness != null && _selectedBusiness!.id == id) {
          _selectedBusiness = null;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Xóa doanh nghiệp thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void selectBusiness(Business business) {
    _selectedBusiness = business;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 
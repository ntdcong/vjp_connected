class Business {
  final int id;
  final int ownerId;
  final String name;
  final String foundedYear;
  final String employees;
  final String industry;
  final String capital;
  final String address;
  final String needs;
  final List<String> imageUrls;
  final String createdAt;
  final String updatedAt;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.foundedYear,
    required this.employees,
    required this.industry,
    required this.capital,
    required this.address,
    required this.needs,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    try {
      // Hàm hỗ trợ chuyển đổi kiểu dữ liệu an toàn
      String safeToString(dynamic value) {
        if (value == null) return '';
        return value.toString();
      }
      
      // Xử lý danh sách ảnh an toàn
      List<String> safeImageList(dynamic imageData) {
        if (imageData == null) return [];
        if (imageData is List) {
          return imageData.map((item) => item.toString()).toList();
        }
        // Nếu là chuỗi, có thể là đường dẫn đơn
        if (imageData is String) {
          return [imageData];
        }
        return [];
      }
      
      print('Parsing business JSON: $json');
      return Business(
        id: json['id'] ?? 0,
        ownerId: json['ownerId'] ?? 0,
        name: json['name'] ?? '',
        foundedYear: safeToString(json['foundedYear']),
        employees: safeToString(json['employees']),
        industry: json['industry'] ?? '',
        capital: safeToString(json['capital']),
        address: json['address'] ?? '',
        needs: json['needs'] ?? '',
        imageUrls: safeImageList(json['imageUrls']),
        createdAt: json['createdAt'] ?? '',
        updatedAt: json['updatedAt'] ?? '',
      );
    } catch (e) {
      print('Error parsing business JSON: $e');
      print('JSON data: $json');
      // Trả về một đối tượng Business mặc định nếu có lỗi
      return Business(
        id: 0,
        ownerId: 0,
        name: 'Error: Không thể phân tích dữ liệu',
        foundedYear: '',
        employees: '',
        industry: '',
        capital: '',
        address: '',
        needs: '',
        imageUrls: [],
        createdAt: '',
        updatedAt: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'foundedYear': foundedYear,
      'employees': employees,
      'industry': industry,
      'capital': capital,
      'address': address,
      'needs': needs,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/business_provider.dart';
import '../providers/auth_provider.dart';
import '../models/business.dart';
import 'chat_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final int businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusinessProvider>(context, listen: false)
          .fetchBusinessById(widget.businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết doanh nghiệp'),
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, businessProvider, child) {
          if (businessProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (businessProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    businessProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      businessProvider.fetchBusinessById(widget.businessId);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final business = businessProvider.selectedBusiness;
          if (business == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin doanh nghiệp'),
            );
          }

          final formatCurrency = NumberFormat.currency(
            locale: 'vi_VN',
            symbol: 'VNĐ',
            decimalDigits: 0,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(business),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              business.address,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection('Thông tin doanh nghiệp', [
                        _buildInfoItem('Ngành nghề', business.industry),
                        _buildInfoItem('Năm thành lập', business.foundedYear),
                        _buildInfoItem('Số nhân viên', business.employees),
                        _buildInfoItem('Vốn điều lệ', _formatCapital(business.capital)),
                      ]),
                      const SizedBox(height: 24),
                      _buildInfoSection('Nhu cầu', [
                        _buildInfoItem('', business.needs),
                      ]),
                      const SizedBox(height: 24),
                      _buildContactButton(context, business),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageCarousel(Business business) {
    if (business.imageUrls.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Icon(Icons.business, size: 80, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: business.imageUrls.length,
        itemBuilder: (context, index) {
          return Image.network(
            business.imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.business, size: 80, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        ...children,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, Business business) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Kiểm tra nếu người dùng đang xem doanh nghiệp của chính họ
    if (authProvider.user != null && authProvider.user!.id == business.ownerId) {
      return Container(); // Không hiển thị nút liên hệ cho doanh nghiệp của chính mình
    }
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (authProvider.isAuthenticated) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  userId: business.ownerId,
                  userName: business.name,
                ),
              ),
            );
          } else {
            // Nếu chưa đăng nhập thì chuyển đến trang đăng nhập
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng đăng nhập để liên hệ'),
              ),
            );
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Liên hệ ngay',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatCapital(String capital) {
    if (capital.isEmpty) return '0 VNĐ';
    try {
      final capitalValue = int.parse(capital);
      return NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'VNĐ',
        decimalDigits: 0,
      ).format(capitalValue);
    } catch (e) {
      print('Lỗi khi định dạng vốn: $e');
      return capital;
    }
  }
} 
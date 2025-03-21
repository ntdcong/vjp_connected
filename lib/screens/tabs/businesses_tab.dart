import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';
import '../../models/business.dart';
import '../business_detail_screen.dart';

class BusinessesTab extends StatefulWidget {
  const BusinessesTab({super.key});

  @override
  State<BusinessesTab> createState() => _BusinessesTabState();
}

class _BusinessesTabState extends State<BusinessesTab> {
  @override
  void initState() {
    super.initState();
    // Tải danh sách doanh nghiệp khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusinessProvider>(context, listen: false).fetchAllBusinesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doanh nghiệp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Thêm chức năng tìm kiếm
            },
          ),
        ],
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      businessProvider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hãy kiểm tra kết nối mạng và máy chủ API',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      businessProvider.fetchAllBusinesses();
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (businessProvider.businesses.isEmpty) {
            return const Center(
              child: Text('Không có doanh nghiệp nào'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: businessProvider.businesses.length,
            itemBuilder: (context, index) {
              final business = businessProvider.businesses[index];
              return BusinessCard(business: business);
            },
          );
        },
      ),
    );
  }
}

class BusinessCard extends StatelessWidget {
  final Business business;
  
  // Màu chủ đạo của card
  static const Color primaryTextColor = Color(0xFF1A1A1A);
  static const Color primaryBlueColor = Color(0xFFE8F4FA);

  const BusinessCard({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BusinessDetailScreen(businessId: business.id),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            image: const DecorationImage(
              image: AssetImage('assets/background.jpg'),
              fit: BoxFit.cover,
              opacity: 0.05,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với tên doanh nghiệp
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    business.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Content với 2 cột: Logo và Thông tin
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cột trái (Logo)
                  Container(
                    width: 130,
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                    child: Column(
                      children: [
                        // Logo doanh nghiệp
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: business.imageUrls.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    business.imageUrls[0],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(Icons.business, size: 40, color: Colors.teal[200]),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Icon(Icons.business, size: 40, color: Colors.teal[200]),
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Ngôn ngữ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo Trung Quốc
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  '文',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Logo Nhật Bản
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  '日',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Chi tiết
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BusinessDetailScreen(businessId: business.id),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryTextColor,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Chi Tiết',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Cột phải (Thông tin doanh nghiệp)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0x99E8F4FA),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                        image: DecorationImage(
                          image: AssetImage('assets/background.jpg'),
                          fit: BoxFit.cover,
                          opacity: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Năm Thành Lập:', business.foundedYear),
                          const SizedBox(height: 12),
                          _buildInfoRow('Nhân Viên:', business.employees),
                          const SizedBox(height: 12),
                          _buildInfoRow('Vốn Doanh Nghiệp:', _formatCapital(business.capital)),
                          const SizedBox(height: 12),
                          _buildInfoRow('Địa Chỉ:', business.address, maxLines: 2),
                          const SizedBox(height: 12),
                          _buildInfoRow('Ngành Nghề:', business.industry),
                          const SizedBox(height: 12),
                          _buildInfoRow('Nhu Cầu:', business.needs, maxLines: 2),
                          const SizedBox(height: 16),
                          // JCI, YBA badge ở dưới cùng
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                height: 26,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.people, size: 14, color: Colors.amber[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'JCI, YBA',
                                      style: TextStyle(
                                        color: Colors.amber[800],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 14,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  String _formatCapital(String capital) {
    if (capital.isEmpty) return '';
    // Nếu capital chứa tiếng Nhật như "万円", giữ nguyên
    if (capital.contains('万') || capital.contains('円')) {
      return capital;
    }
    try {
      int capitalValue = int.parse(capital);
      if (capitalValue >= 1000000000) {
        return '${(capitalValue / 1000000000).toStringAsFixed(1)} tỷ VND';
      } else if (capitalValue >= 1000000) {
        return '${(capitalValue / 1000000).toStringAsFixed(1)} triệu VND';
      }
      return '$capitalValue VND';
    } catch (e) {
      return capital;
    }
  }
} 
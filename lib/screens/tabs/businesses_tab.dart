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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // 0: card phong cách cũ, 1: card dạng grid, 2: card dạng list
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    // Tải danh sách doanh nghiệp khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusinessProvider>(context, listen: false).fetchAllBusinesses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doanh nghiệp',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.view_list),
            onSelected: (int result) {
              setState(() {
                _viewMode = result;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.view_agenda, size: 20),
                    SizedBox(width: 8),
                    Text('Kiểu thẻ gốc'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.grid_view, size: 20),
                    SizedBox(width: 8),
                    Text('Kiểu lưới'),
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.view_list, size: 20),
                    SizedBox(width: 8),
                    Text('Kiểu danh sách'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm doanh nghiệp...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (businessProvider.businesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy doanh nghiệp nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Lọc doanh nghiệp theo từ khóa tìm kiếm
          final filteredBusinesses = businessProvider.businesses.where((business) {
            return business.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   business.industry.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   business.address.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          if (filteredBusinesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy kết quả cho "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          switch (_viewMode) {
            case 0:
              return _buildOriginalCardView(filteredBusinesses);
            case 1:
              return _buildGridView(filteredBusinesses);
            case 2:
              return _buildListView(filteredBusinesses);
            default:
              return _buildOriginalCardView(filteredBusinesses);
          }
        },
      ),
    );
  }

  Widget _buildOriginalCardView(List<Business> businesses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: businesses.length,
      itemBuilder: (context, index) {
        return BusinessOriginalCard(business: businesses[index]);
      },
    );
  }

  Widget _buildGridView(List<Business> businesses) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: businesses.length,
      itemBuilder: (context, index) {
        return BusinessGridCard(business: businesses[index]);
      },
    );
  }

  Widget _buildListView(List<Business> businesses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: businesses.length,
      itemBuilder: (context, index) {
        return BusinessListCard(business: businesses[index]);
      },
    );
  }
}

class BusinessOriginalCard extends StatelessWidget {
  final Business business;
  
  // Màu chủ đạo của card
  static const Color primaryTextColor = Color(0xFF1A1A1A);
  static const Color primaryBlueColor = Color(0xFFE8F4FA);

  const BusinessOriginalCard({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 1.0,
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
              image: AssetImage('assets/images/pattern_bg.png'),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 0,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
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
                              child: const Center(
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
                              child: const Center(
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => BusinessDetailScreen(businessId: business.id),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Chi Tiết',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Cột phải (Thông tin doanh nghiệp)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FA).withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/pattern_bg.png'),
                          fit: BoxFit.cover,
                          opacity: 0.1,
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
                                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'BNI',
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
}

class BusinessGridCard extends StatelessWidget {
  final Business business;

  const BusinessGridCard({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BusinessDetailScreen(businessId: business.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            SizedBox(
              height: 120,
              width: double.infinity,
              child: business.imageUrls.isNotEmpty
                  ? Image.network(
                      business.imageUrls[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(Icons.business, size: 40, color: Colors.teal.shade200),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(Icons.business, size: 40, color: Colors.teal.shade200),
                      ),
                    ),
            ),

            // Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      business.industry,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.teal.shade300),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            business.address.split(',').last.trim(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

class BusinessListCard extends StatelessWidget {
  final Business business;

  const BusinessListCard({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BusinessDetailScreen(businessId: business.id),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              width: 100,
              height: 120,
              child: business.imageUrls.isNotEmpty
                  ? Image.network(
                      business.imageUrls[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(Icons.business, size: 40, color: Colors.teal.shade200),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(Icons.business, size: 40, color: Colors.teal.shade200),
                      ),
                    ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            business.industry,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.teal.shade300),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            business.employees,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.teal.shade300),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            business.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/business.dart';
import '../business_detail_screen.dart';
import '../business_form_screen.dart';

class MyBusinessesTab extends StatefulWidget {
  const MyBusinessesTab({super.key});

  @override
  State<MyBusinessesTab> createState() => _MyBusinessesTabState();
}

class _MyBusinessesTabState extends State<MyBusinessesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<BusinessProvider>(context, listen: false).fetchMyBusinesses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Nếu chưa đăng nhập, hiển thị màn hình yêu cầu đăng nhập
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doanh nghiệp của tôi'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vui lòng đăng nhập để xem doanh nghiệp của bạn'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Đăng nhập ngay'),
              ),
            ],
          ),
        ),
      );
    }

    // Nếu không phải là doanh nghiệp, hiển thị tab yêu thích (phần này chưa làm)
    if (authProvider.user?.role != 'business') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Yêu thích'),
        ),
        body: const Center(
          child: Text('Chức năng yêu thích sẽ có trong phiên bản tiếp theo'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doanh nghiệp của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BusinessFormScreen(),
                ),
              );
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
                  Text(
                    businessProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      businessProvider.fetchMyBusinesses();
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (businessProvider.myBusinesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa có doanh nghiệp nào'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BusinessFormScreen(),
                        ),
                      );
                    },
                    child: const Text('Tạo doanh nghiệp'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: businessProvider.myBusinesses.length,
            itemBuilder: (context, index) {
              final business = businessProvider.myBusinesses[index];
              return MyBusinessCard(business: business);
            },
          );
        },
      ),
    );
  }
}

class MyBusinessCard extends StatelessWidget {
  final Business business;

  const MyBusinessCard({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: business.imageUrls.isNotEmpty
                ? Image.network(
                    business.imageUrls[0],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.business,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.business,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        business.address,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BusinessFormScreen(
                                business: business,
                              ),
                            ),
                          );
                        },
                        child: const Text('Chỉnh sửa'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BusinessDetailScreen(
                                businessId: business.id,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Xem chi tiết'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
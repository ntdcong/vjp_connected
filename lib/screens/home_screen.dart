import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'tabs/businesses_tab.dart';
import 'tabs/my_businesses_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const BusinessesTab(),
    const MyBusinessesTab(),
    const MessagesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Doanh nghiệp',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Provider.of<AuthProvider>(context).user?.role == 'business'
                  ? Icons.storefront
                  : Icons.favorite
            ),
            label: Provider.of<AuthProvider>(context).user?.role == 'business'
                ? 'Doanh nghiệp của tôi'
                : 'Yêu thích',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Tin nhắn',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
} 
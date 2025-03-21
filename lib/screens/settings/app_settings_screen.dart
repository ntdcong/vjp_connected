import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'Tiếng Việt';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _darkMode = prefs.getBool('darkMode') ?? false;
        _notifications = prefs.getBool('notifications') ?? true;
        _language = prefs.getString('language') ?? 'Tiếng Việt';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _darkMode);
      await prefs.setBool('notifications', _notifications);
      await prefs.setString('language', _language);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cài đặt đã được lưu')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt ứng dụng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giao diện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Chế độ tối'),
                          subtitle: const Text('Chuyển sang giao diện tối'),
                          value: _darkMode,
                          onChanged: (value) {
                            setState(() {
                              _darkMode = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Ngôn ngữ'),
                          subtitle: Text(_language),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          onTap: () {
                            _showLanguageDialog();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Kích thước chữ'),
                          subtitle: const Text('Vừa'),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chức năng đang phát triển')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Thông báo'),
                          subtitle: const Text('Bật/tắt thông báo từ ứng dụng'),
                          value: _notifications,
                          onChanged: (value) {
                            setState(() {
                              _notifications = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Thông báo tin nhắn'),
                          subtitle: const Text('Khi có tin nhắn mới'),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chức năng đang phát triển')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Thông báo doanh nghiệp'),
                          subtitle: const Text('Khi có doanh nghiệp mới'),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chức năng đang phát triển')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bảo mật',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Đổi mật khẩu'),
                          subtitle: const Text('Cập nhật mật khẩu của bạn'),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Xác thực hai lớp'),
                          subtitle: const Text('Bảo mật tài khoản cao hơn'),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chức năng đang phát triển')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Lưu cài đặt',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _showResetDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        'Đặt lại cài đặt mặc định',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Tiếng Việt'),
            _buildLanguageOption('Tiếng Anh'),
            _buildLanguageOption('Tiếng Nhật'),
            _buildLanguageOption('Tiếng Trung'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _language == language
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        setState(() {
          _language = language;
        });
        Navigator.of(context).pop();
      },
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại cài đặt'),
        content: const Text('Bạn có chắc chắn muốn đặt lại tất cả cài đặt về mặc định?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                _darkMode = false;
                _notifications = true;
                _language = 'Tiếng Việt';
              });
              await _saveSettings();
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }
} 
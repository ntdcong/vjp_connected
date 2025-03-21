import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/business.dart';
import '../providers/business_provider.dart';

class BusinessFormScreen extends StatefulWidget {
  final Business? business;

  const BusinessFormScreen({super.key, this.business});

  @override
  State<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends State<BusinessFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _foundedYearController = TextEditingController();
  final _employeesController = TextEditingController();
  final _industryController = TextEditingController();
  final _capitalController = TextEditingController();
  final _addressController = TextEditingController();
  final _needsController = TextEditingController();
  
  // Trong thực tế, đây sẽ là một danh sách các File từ điện thoại, 
  // nhưng để đơn giản chúng ta chỉ lưu trữ danh sách URL
  List<String> _imageUrls = [];
  
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.business != null;
    
    if (_isEdit) {
      // Đặt giá trị từ đối tượng business nếu đang chỉnh sửa
      _nameController.text = widget.business!.name;
      _foundedYearController.text = widget.business!.foundedYear;
      _employeesController.text = widget.business!.employees;
      _industryController.text = widget.business!.industry;
      _capitalController.text = widget.business!.capital;
      _addressController.text = widget.business!.address;
      _needsController.text = widget.business!.needs;
      _imageUrls = List.from(widget.business!.imageUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _foundedYearController.dispose();
    _employeesController.dispose();
    _industryController.dispose();
    _capitalController.dispose();
    _addressController.dispose();
    _needsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      // Trong thực tế, bạn sẽ tải ảnh lên server và nhận URL trả về
      // Nhưng ở đây chúng ta sẽ giả lập bằng cách sử dụng path của file
      setState(() {
        _imageUrls.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _saveBusiness() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> businessData = {
        'name': _nameController.text,
        'foundedYear': _foundedYearController.text,
        'employees': _employeesController.text,
        'industry': _industryController.text,
        'capital': _capitalController.text,
        'address': _addressController.text,
        'needs': _needsController.text,
        'imageUrls': _imageUrls,
      };

      if (_isEdit) {
        businessData['id'] = widget.business!.id;
      }

      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      bool success;
      
      if (_isEdit) {
        success = await businessProvider.updateBusiness(businessData);
      } else {
        success = await businessProvider.createBusiness(businessData);
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Chỉnh sửa doanh nghiệp' : 'Tạo doanh nghiệp mới'),
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, businessProvider, child) {
          return Stack(
            children: [
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (businessProvider.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  businessProvider.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildImageSection(),
                      const SizedBox(height: 24),
                      _buildTextInput(
                        controller: _nameController,
                        label: 'Tên doanh nghiệp',
                        hint: 'Nhập tên doanh nghiệp',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên doanh nghiệp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextInput(
                        controller: _industryController,
                        label: 'Ngành nghề',
                        hint: 'Nhập ngành nghề kinh doanh',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập ngành nghề';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextInput(
                              controller: _foundedYearController,
                              label: 'Năm thành lập',
                              hint: 'VD: 2020',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập năm thành lập';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextInput(
                              controller: _employeesController,
                              label: 'Số nhân viên',
                              hint: 'VD: 10-50',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập số nhân viên';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextInput(
                        controller: _capitalController,
                        label: 'Vốn điều lệ (VNĐ)',
                        hint: 'VD: 1000000000',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập vốn điều lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextInput(
                        controller: _addressController,
                        label: 'Địa chỉ',
                        hint: 'Nhập địa chỉ doanh nghiệp',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập địa chỉ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextInput(
                        controller: _needsController,
                        label: 'Nhu cầu',
                        hint: 'Nhu cầu đầu tư, hợp tác...',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập nhu cầu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: businessProvider.isLoading ? null : _saveBusiness,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: businessProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Cập nhật' : 'Tạo doanh nghiệp',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (businessProvider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình ảnh doanh nghiệp',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Nút thêm ảnh
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                      SizedBox(height: 4),
                      Text('Thêm ảnh', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              // Danh sách ảnh đã chọn
              ..._imageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: url.startsWith('http')
                            ? Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(url),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }
} 
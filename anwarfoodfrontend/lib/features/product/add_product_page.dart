import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/product_unit.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import 'dart:convert';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  
  const AddProductPage({Key? key, this.initialData}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  final _mrpController = TextEditingController();
  final _spController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _qohController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _cgstController = TextEditingController();
  final _igstController = TextEditingController();
  final _sgstController = TextEditingController();
  final _mfgDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _mfgByController = TextEditingController();
  final _image1Controller = TextEditingController();
  final _image2Controller = TextEditingController();
  final _image3Controller = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCategories = [];
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  String _isBarcodeAvailable = 'N';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingSubCategories = false;
  String? _error;
  String? _subCategoriesError;

  // Add this list to store product units
  List<ProductUnit> _productUnits = [];

  // Add controllers for the unit form
  final _unitNameController = TextEditingController();
  final _unitValueController = TextEditingController();
  final _unitRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load categories from API
      final response = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = response.map((category) => {
            'CATEGORY_ID': category.id,
            'CATEGORY_NAME': category.name,
            'sub_categories': category.subCategories ?? [],
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSubCategories(int categoryId) async {
    print('Loading subcategories for categoryId: $categoryId');
    if (!mounted) return;
    
    setState(() {
      _isLoadingSubCategories = true;
      _subCategoriesError = null;
      _selectedSubCategoryId = null;
      _subCategories = []; // Clear existing subcategories
    });

    try {
      final response = await _categoryService.getSubCategories(categoryId);
      print('Subcategories API Response: $response');
      
      if (!mounted) return;

      if (response != null && response is List) {
        final mappedSubCategories = response.map((subCat) {
          print('Processing subcategory: $subCat');
          // Map using the correct API response keys (id and name)
          final id = subCat['id'] is String 
              ? int.tryParse(subCat['id']) 
              : subCat['id'] as int?;
              
          return {
            'SUB_CATEGORY_ID': id ?? 0,
            'SUB_CATEGORY_NAME': subCat['name'] ?? 'Unknown',
          };
        }).toList();

        print('Mapped subcategories: $mappedSubCategories');
        
        setState(() {
          _subCategories = mappedSubCategories;
          _isLoadingSubCategories = false;
        });
      } else {
        print('Invalid response format or null response');
        setState(() {
          _subCategories = [];
          _isLoadingSubCategories = false;
          _subCategoriesError = 'Invalid response format';
        });
      }
    } catch (e) {
      print('Error loading subcategories: $e');
      if (!mounted) return;
      setState(() {
        _subCategories = [];
        _subCategoriesError = e.toString();
        _isLoadingSubCategories = false;
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  void _addUnit() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Unit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Unit Name (e.g., KG, G)',
                controller: _unitNameController,
                validator: (value) => value?.isEmpty == true ? 'Unit name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Unit Value',
                controller: _unitValueController,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Unit value is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Unit Rate',
                controller: _unitRateController,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Unit rate is required' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _unitNameController.clear();
                        _unitValueController.clear();
                        _unitRateController.clear();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B1B1B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_unitNameController.text.isNotEmpty &&
                            _unitValueController.text.isNotEmpty &&
                            _unitRateController.text.isNotEmpty) {
                          setState(() {
                            _productUnits.add(
                              ProductUnit(
                                unitName: _unitNameController.text,
                                unitValue: _unitValueController.text,
                                unitRate: _unitRateController.text,
                              ),
                            );
                          });
                          _unitNameController.clear();
                          _unitValueController.clear();
                          _unitRateController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildUnitsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Product Units',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B1B1B),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: const Color(0xFF9B1B1B),
              onPressed: _addUnit,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_productUnits.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No units added yet. Click the + button to add units.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _productUnits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final unit = _productUnits[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.unitName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Value: ${unit.unitValue}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rate: Rs. ${unit.unitRate}',
                            style: const TextStyle(
                              color: Color(0xFF9B1B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: () {
                        setState(() {
                          _productUnits.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one unit for the product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Map product units to match API format
      final List<Map<String, String>> formattedUnits = _productUnits.map((unit) => {
        'unitName': unit.unitName,
        'unitValue': unit.unitValue,
        'unitRate': unit.unitRate,
      }).toList();

      final productData = {
        'prodSubCatId': _selectedSubCategoryId,
        'prodName': _nameController.text.trim(),
        'prodCode': _codeController.text.trim(),
        'prodDesc': _descController.text.trim(),
        'prodMrp': double.tryParse(_mrpController.text) ?? 0.0,
        'prodSp': double.tryParse(_spController.text) ?? 0.0,
        'prodReorderLevel': _reorderLevelController.text.trim(),
        'prodQoh': _qohController.text.trim(),
        'prodHsnCode': _hsnCodeController.text.trim(),
        'prodCgst': _cgstController.text.trim(),
        'prodIgst': _igstController.text.trim(),
        'prodSgst': _sgstController.text.trim(),
        'prodMfgDate': _mfgDateController.text.isEmpty ? null : _mfgDateController.text,
        'prodExpiryDate': _expiryDateController.text.isEmpty ? null : _expiryDateController.text,
        'prodMfgBy': _mfgByController.text.trim(),
        'prodImage1': _image1Controller.text.trim(),
        'prodImage2': _image2Controller.text.trim(),
        'prodImage3': _image3Controller.text.trim(),
        'prodCatId': _selectedCategoryId,
        'isBarcodeAvailable': _isBarcodeAvailable,
        'productUnits': formattedUnits,
      };

      // Debug print the request payload
      print('Sending product data to API:');
      print(productData);

      final result = await _productService.addProduct(productData);
      print('API Response:');
      print(result);
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Product added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error adding product:');
      print(e);
      print('Stack trace:');
      print(stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _mrpController.dispose();
    _spController.dispose();
    _reorderLevelController.dispose();
    _qohController.dispose();
    _hsnCodeController.dispose();
    _cgstController.dispose();
    _igstController.dispose();
    _sgstController.dispose();
    _mfgDateController.dispose();
    _expiryDateController.dispose();
    _mfgByController.dispose();
    _image1Controller.dispose();
    _image2Controller.dispose();
    _image3Controller.dispose();
    _unitNameController.dispose();
    _unitValueController.dispose();
    _unitRateController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            validator: validator,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Product',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCategories,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Product Name *',
                            controller: _nameController,
                            validator: (value) => value?.isEmpty == true ? 'Product name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Product Code *',
                            controller: _codeController,
                            validator: (value) => value?.isEmpty == true ? 'Product code is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Description *',
                            controller: _descController,
                            maxLines: 3,
                            validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
                          ),
                          const SizedBox(height: 24),

                          // Category Section
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Category *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            items: _categories.map((category) {
                              final id = category['CATEGORY_ID'];
                              final name = category['CATEGORY_NAME'] ?? 'Unknown';
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setState(() {
                                  _selectedCategoryId = value;
                                  _selectedSubCategoryId = null;
                                });
                                await _loadSubCategories(value);
                              }
                            },
                            validator: (value) => value == null ? 'Category is required' : null,
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingSubCategories)
                            const Center(child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: CircularProgressIndicator(),
                            ))
                          else if (_subCategoriesError != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                _subCategoriesError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              value: _selectedSubCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Sub Category *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                enabled: _selectedCategoryId != null,
                              ),
                              items: _subCategories.map((subCategory) {
                                print('Creating dropdown item for subcategory: $subCategory');
                                final id = subCategory['SUB_CATEGORY_ID'] as int;
                                final name = subCategory['SUB_CATEGORY_NAME'] as String;
                                print('Subcategory ID: $id, Name: $name');
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(name),
                                );
                              }).toList(),
                              onChanged: _selectedCategoryId == null ? null : (int? value) {
                                print('Selected subcategory ID: $value');
                                if (value != null) {
                                  setState(() {
                                    _selectedSubCategoryId = value;
                                  });
                                }
                              },
                              validator: (value) => value == null ? 'Sub Category is required' : null,
                            ),
                          const SizedBox(height: 24),

                          // Pricing Section
                          const Text(
                            'Pricing',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'MRP *',
                                  controller: _mrpController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value?.isEmpty == true ? 'MRP is required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Selling Price *',
                                  controller: _spController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value?.isEmpty == true ? 'Selling price is required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Inventory Section
                          const Text(
                            'Inventory',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Quantity on Hand',
                                  controller: _qohController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Reorder Level',
                                  controller: _reorderLevelController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Tax Information Section
                          const Text(
                            'Tax Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'HSN Code',
                            controller: _hsnCodeController,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'CGST (%)',
                                  controller: _cgstController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'SGST (%)',
                                  controller: _sgstController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'IGST (%)',
                            controller: _igstController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),

                          // Manufacturing Details Section
                          const Text(
                            'Manufacturing Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Manufactured By',
                            controller: _mfgByController,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Manufacturing Date',
                                  controller: _mfgDateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(_mfgDateController),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Expiry Date',
                                  controller: _expiryDateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(_expiryDateController),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Images Section
                          const Text(
                            'Product Images',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Image 1 URL *',
                            controller: _image1Controller,
                            validator: (value) => value?.isEmpty == true ? 'At least one image is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Image 2 URL',
                            controller: _image2Controller,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Image 3 URL',
                            controller: _image3Controller,
                          ),
                          const SizedBox(height: 24),

                          // Barcode Section
                          const Text(
                            'Barcode',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown<String>(
                            label: 'Barcode Available',
                            value: _isBarcodeAvailable,
                            items: const [
                              DropdownMenuItem(value: 'Y', child: Text('Yes')),
                              DropdownMenuItem(value: 'N', child: Text('No')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _isBarcodeAvailable = value ?? 'N';
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Add the units section before the submit button
                          _buildUnitsList(),
                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9B1B1B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Add Product',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
} 
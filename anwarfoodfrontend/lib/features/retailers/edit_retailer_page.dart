import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class EditRetailerPage extends StatefulWidget {
  const EditRetailerPage({Key? key}) : super(key: key);

  @override
  State<EditRetailerPage> createState() => _EditRetailerPageState();
}

class _EditRetailerPageState extends State<EditRetailerPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool isLoading = false;

  // Form controllers
  final _shopNameController = TextEditingController();
  final _retailerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  String _shopOpenStatus = 'Y';

  // List of states and cities
  final List<String> _states = [
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Tamil Nadu',
    'Gujarat',
    'Uttar Pradesh',
    'West Bengal',
    'Rajasthan',
    'Telangana',
    'Kerala'
  ];

  final Map<String, List<String>> _citiesByState = {
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Trichy'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Noida'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam']
  };

  @override
  void initState() {
    super.initState();
    // Set default values
    _selectedCountry = 'India';
    _selectedState = 'Maharashtra';
    _selectedCity = _citiesByState['Maharashtra']?.first;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final retailerData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (retailerData != null) {
        _populateFormData(retailerData);
      }
    });
  }

  void _populateFormData(Map<String, dynamic> data) {
    _shopNameController.text = data['RET_SHOP_NAME'] ?? '';
    _retailerNameController.text = data['RET_NAME'] ?? '';
    _addressController.text = data['RET_ADDRESS'] ?? '';
    _pinCodeController.text = data['RET_PIN_CODE']?.toString() ?? '';
    _emailController.text = data['RET_EMAIL_ID'] ?? '';
    _gstController.text = data['RET_GST_NO'] ?? '';
    
    setState(() {
      _selectedCountry = data['RET_COUNTRY'] ?? 'India';
      _selectedState = data['RET_STATE'];
      // If the state exists in our list, use it, otherwise default to Maharashtra
      if (_selectedState != null && !_states.contains(_selectedState)) {
        _selectedState = 'Maharashtra';
      }
      
      // Set city based on state
      if (_selectedState != null && _citiesByState.containsKey(_selectedState)) {
        final cities = _citiesByState[_selectedState!]!;
        _selectedCity = data['RET_CITY'];
        // If the city doesn't exist in our list for this state, use the first city
        if (_selectedCity == null || !cities.contains(_selectedCity)) {
          _selectedCity = cities.first;
        }
      }
      
      _shopOpenStatus = data['SHOP_OPEN_STATUS'] ?? 'Y';
    });
  }

  Future<void> _updateRetailer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('http://localhost:3000/api/retailers/my-retailer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'RET_NAME': _retailerNameController.text,
          'RET_SHOP_NAME': _shopNameController.text,
          'RET_ADDRESS': _addressController.text,
          'RET_PIN_CODE': int.parse(_pinCodeController.text),
          'RET_EMAIL_ID': _emailController.text,
          'RET_COUNTRY': _selectedCountry,
          'RET_STATE': _selectedState,
          'RET_CITY': _selectedCity,
          'RET_GST_NO': _gstController.text,
          'SHOP_OPEN_STATUS': _shopOpenStatus,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retailer profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception(data['message'] ?? 'Failed to update retailer profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _retailerNameController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Retailer Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _retailerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Retailer Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter retailer name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter shop name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedState,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                        items: _states
                            .map((state) => DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(state),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedState = value;
                              // Reset city when state changes
                              _selectedCity = _citiesByState[value]?.first;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a state';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedState != null)
                        DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                          items: (_citiesByState[_selectedState!] ?? [])
                              .map((city) => DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(city),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCity = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a city';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinCodeController,
                        decoration: const InputDecoration(
                          labelText: 'PIN Code',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter PIN code';
                          }
                          if (value.length != 6) {
                            return 'PIN code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gstController,
                        decoration: const InputDecoration(
                          labelText: 'GST Number (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Shop Status: '),
                          Switch(
                            value: _shopOpenStatus == 'Y',
                            onChanged: (value) {
                              setState(() {
                                _shopOpenStatus = value ? 'Y' : 'N';
                              });
                            },
                            activeColor: const Color(0xFF9B1B1B),
                          ),
                          Text(
                            _shopOpenStatus == 'Y' ? 'Open' : 'Closed',
                            style: TextStyle(
                              color: _shopOpenStatus == 'Y' ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B1B1B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : _updateRetailer,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
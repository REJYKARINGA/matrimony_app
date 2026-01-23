import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/profile_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Age preferences
  late TextEditingController _minAgeController;
  late TextEditingController _maxAgeController;

  // Height preferences
  late TextEditingController _minHeightController;
  late TextEditingController _maxHeightController;

  // Basic preferences
  late String? _maritalStatus;
  late String? _religion;
  late TextEditingController _casteController;
  late TextEditingController _educationController;
  late TextEditingController _occupationController;

  // Income preferences
  late TextEditingController _minIncomeController;
  late TextEditingController _maxIncomeController;

  // Location preferences
  late TextEditingController _preferredLocationsController;

  bool _isLoading = false;
  bool _isDataLoading = true;
  String? _errorMessage;

  final List<String> _maritalStatusOptions = [
    'never_married',
    'divorced',
    'widowed',
  ];

  final List<String> _religions = [
    'Muslim',
    'Hindu',
    'Christian',
    'Sikh',
    'Jain',
    'Buddhist',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isDataLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ProfileService.getMyProfile();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final preferences = data['user']['preferences'];

        if (preferences != null) {
          _initializeControllersWithData(preferences);
        } else {
          _initializeEmptyControllers();
        }
      } else if (response.statusCode == 404) {
        _initializeEmptyControllers();
      } else {
        setState(() {
          _errorMessage = 'Failed to load preferences';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading preferences: $e';
      });
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
  }

  void _initializeEmptyControllers() {
    _minAgeController = TextEditingController(text: '');
    _maxAgeController = TextEditingController(text: '');
    _minHeightController = TextEditingController(text: '');
    _maxHeightController = TextEditingController(text: '');
    _maritalStatus = null;
    _religion = null;
    _casteController = TextEditingController(text: '');
    _educationController = TextEditingController(text: '');
    _occupationController = TextEditingController(text: '');
    _minIncomeController = TextEditingController(text: '');
    _maxIncomeController = TextEditingController(text: '');
    _preferredLocationsController = TextEditingController(text: '');
  }

  void _initializeControllersWithData(Map<String, dynamic> preferences) {
    _minAgeController = TextEditingController(
      text: preferences['min_age']?.toString() ?? '',
    );
    _maxAgeController = TextEditingController(
      text: preferences['max_age']?.toString() ?? '',
    );
    _minHeightController = TextEditingController(
      text: preferences['min_height']?.toString() ?? '',
    );
    _maxHeightController = TextEditingController(
      text: preferences['max_height']?.toString() ?? '',
    );
    _maritalStatus = preferences['marital_status'];
    _religion = preferences['religion'];
    _casteController = TextEditingController(text: preferences['caste'] ?? '');
    _educationController = TextEditingController(
      text: preferences['education'] ?? '',
    );
    _occupationController = TextEditingController(
      text: preferences['occupation'] ?? '',
    );
    _minIncomeController = TextEditingController(
      text: preferences['min_income']?.toString() ?? '',
    );
    _maxIncomeController = TextEditingController(
      text: preferences['max_income']?.toString() ?? '',
    );
    _preferredLocationsController = TextEditingController(
      text: preferences['preferred_locations'] != null
          ? (preferences['preferred_locations'] as List).join(', ')
          : '',
    );
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProfileService.updatePreferences(
        minAge: int.tryParse(_minAgeController.text),
        maxAge: int.tryParse(_maxAgeController.text),
        minHeight: int.tryParse(_minHeightController.text),
        maxHeight: int.tryParse(_maxHeightController.text),
        maritalStatus: _maritalStatus,
        religion: _religion,
        caste: _casteController.text,
        education: _educationController.text,
        occupation: _occupationController.text,
        minIncome: double.tryParse(_minIncomeController.text),
        maxIncome: double.tryParse(_maxIncomeController.text),
        preferredLocations: _preferredLocationsController.text.isNotEmpty
            ? _preferredLocationsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .toList()
            : [],
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final data = json.decode(response.body);
        String message = data['error'] ?? 'Failed to update preferences';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isDataLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildGradientHeader(size, context),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFB47FFF)),
                      const SizedBox(height: 16),
                      const Text('Loading preferences...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildGradientHeader(size, context),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _loadPreferences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildGradientHeader(size, context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('Age Preferences', [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _minAgeController,
                                  'Min Age',
                                  Icons.calendar_today,
                                  isNumber: true,
                                  validator: _ageValidator,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  _maxAgeController,
                                  'Max Age',
                                  Icons.calendar_today,
                                  isNumber: true,
                                  validator: _ageValidator,
                                ),
                              ),
                            ],
                          ),
                        ]),

                        _buildSection('Height Preferences', [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _minHeightController,
                                  'Min Height (cm)',
                                  Icons.height,
                                  isNumber: true,
                                  validator: _heightValidator,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  _maxHeightController,
                                  'Max Height (cm)',
                                  Icons.height,
                                  isNumber: true,
                                  validator: _heightValidator,
                                ),
                              ),
                            ],
                          ),
                        ]),

                        _buildSection('Basic Preferences', [
                          _buildDropdown(
                            'Preferred Marital Status',
                            _maritalStatus,
                            _maritalStatusOptions,
                            Icons.favorite_outline,
                            (value) {
                              setState(() => _maritalStatus = value);
                            },
                            formatLabel: true,
                          ),
                          const SizedBox(height: 10),
                          _buildDropdown(
                            'Preferred Religion',
                            _religion,
                            _religions,
                            Icons.church,
                            (value) {
                              setState(() => _religion = value);
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            _casteController,
                            'Preferred Caste',
                            Icons.people_outline,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            _educationController,
                            'Preferred Education',
                            Icons.school,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            _occupationController,
                            'Preferred Occupation',
                            Icons.work_outline,
                          ),
                        ]),

                        _buildSection('Income Preferences', [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _minIncomeController,
                                  'Min Income (Lakhs)',
                                  Icons.currency_rupee,
                                  isNumber: true,
                                  validator: _incomeValidator,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  _maxIncomeController,
                                  'Max Income (Lakhs)',
                                  Icons.currency_rupee,
                                  isNumber: true,
                                  validator: _incomeValidator,
                                ),
                              ),
                            ],
                          ),
                        ]),

                        _buildSection('Location Preferences', [
                          _buildTextField(
                            _preferredLocationsController,
                            'Preferred Locations (comma separated)',
                            Icons.location_city,
                            maxLines: 3,
                            hint: 'e.g., Kochi, Thiruvananthapuram, Kozhikode',
                          ),
                        ]),

                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFB47FFF), Color(0xFF5CB3FF)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _savePreferences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Update Preferences',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(Size size, BuildContext context) {
    return Container(
      width: double.infinity,
      height: size.height * 0.22,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB47FFF), // Purple
            Color(0xFF5CB3FF), // Blue
            Color(0xFF4CD9A6), // Green
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.tune, size: 35, color: Color(0xFFB47FFF)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find your perfect match',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF5CB3FF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xFF5CB3FF), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    IconData icon,
    void Function(String?) onChanged, {
    bool formatLabel = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF5CB3FF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xFF5CB3FF), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((item) {
        String displayText = formatLabel
            ? item
                  .split('_')
                  .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
                  .join(' ')
            : item;
        return DropdownMenuItem(value: item, child: Text(displayText));
      }).toList(),
      onChanged: onChanged,
    );
  }

  String? _ageValidator(String? value) {
    if (value != null && value.isNotEmpty) {
      final numValue = int.tryParse(value);
      if (numValue == null || numValue < 18 || numValue > 100) {
        return 'Enter age 18-100';
      }
    }
    return null;
  }

  String? _heightValidator(String? value) {
    if (value != null && value.isNotEmpty) {
      final numValue = int.tryParse(value);
      if (numValue == null || numValue < 100 || numValue > 250) {
        return 'Enter height 100-250 cm';
      }
    }
    return null;
  }

  String? _incomeValidator(String? value) {
    if (value != null && value.isNotEmpty) {
      final numValue = double.tryParse(value);
      if (numValue == null || numValue < 0) {
        return 'Enter valid income';
      }
    }
    return null;
  }

  @override
  void dispose() {
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _minHeightController.dispose();
    _maxHeightController.dispose();
    _casteController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _minIncomeController.dispose();
    _maxIncomeController.dispose();
    _preferredLocationsController.dispose();
    super.dispose();
  }
}

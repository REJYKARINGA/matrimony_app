import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/profile_service.dart';
import '../services/location_service.dart';
import '../widgets/common_footer.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Age preferences
  RangeValues _ageRange = const RangeValues(18, 50);
  
  // Height preferences
  RangeValues _heightRange = const RangeValues(140, 180);

  // Basic preferences
  late String? _maritalStatus;
  late String? _religion;
  List<String> _selectedCastes = [];
  final TextEditingController _casteController = TextEditingController();
  late TextEditingController _educationController;
  late TextEditingController _occupationController;

  // Income preferences
  RangeValues _incomeRange = const RangeValues(0, 30);

  // Location preferences
  List<String> _preferredLocations = [];
  final TextEditingController _locationSearchController = TextEditingController();

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
    _ageRange = const RangeValues(18, 50);
    _heightRange = const RangeValues(140, 180);
    _maritalStatus = null;
    _religion = null;
    _selectedCastes = [];
    _casteController.text = '';
    _educationController = TextEditingController(text: '');
    _occupationController = TextEditingController(text: '');
    _incomeRange = const RangeValues(0, 30);
    _preferredLocations = [];
    _locationSearchController.text = '';
  }

  void _initializeControllersWithData(Map<String, dynamic> preferences) {
    double ageStart = double.tryParse(preferences['min_age']?.toString() ?? '18') ?? 18;
    double ageEnd = double.tryParse(preferences['max_age']?.toString() ?? '50') ?? 50;
    _ageRange = RangeValues(
      ageStart.clamp(18, 70),
      ageEnd.clamp(18, 70)
    );

    double heightStart = double.tryParse(preferences['min_height']?.toString() ?? '140') ?? 140;
    double heightEnd = double.tryParse(preferences['max_height']?.toString() ?? '180') ?? 180;
    _heightRange = RangeValues(
      heightStart.clamp(100, 220),
      heightEnd.clamp(100, 220)
    );
    _maritalStatus = preferences['marital_status'];
    _religion = preferences['religion'];
    
    if (preferences['caste'] != null) {
      if (preferences['caste'] is List) {
        _selectedCastes = List<String>.from(preferences['caste']);
      } else {
        _selectedCastes = [preferences['caste'].toString()];
      }
    } else {
      _selectedCastes = [];
    }
    _casteController.text = '';
    
    _educationController = TextEditingController(text: preferences['education'] ?? '');
    _occupationController = TextEditingController(
      text: preferences['occupation'] ?? '',
    );
    double incomeStartAnnual = double.tryParse(preferences['min_income']?.toString() ?? '0') ?? 0;
    double incomeEndAnnual = double.tryParse(preferences['max_income']?.toString() ?? '30') ?? 30;
    // Store internally as Monthly Thousands (K)
    _incomeRange = RangeValues(
      (incomeStartAnnual * 100 / 12).clamp(0, 800),
      (incomeEndAnnual * 100 / 12).clamp(0, 800)
    );
    _preferredLocations = preferences['preferred_locations'] != null
        ? List<String>.from(preferences['preferred_locations'])
        : [];
    _locationSearchController.text = '';
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProfileService.updatePreferences(
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        minHeight: _heightRange.start.round(),
        maxHeight: _heightRange.end.round(),
        maritalStatus: _maritalStatus,
        religion: _religion,
        caste: _selectedCastes,
        education: _educationController.text,
        occupation: _occupationController.text,
        minIncome: (_incomeRange.start * 12 / 100),
        maxIncome: (_incomeRange.end * 12 / 100),
        preferredLocations: _preferredLocations,
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
                        _buildSection('Age Preference', [
                          _buildRangeSlider(
                            'Age: ${_ageRange.start.round()} - ${_ageRange.end.round()} Years',
                            _ageRange,
                            18,
                            70,
                            (values) => setState(() => _ageRange = values),
                            Icons.calendar_month_rounded,
                          ),
                        ]),

                        _buildSection('Height Preference', [
                          _buildRangeSlider(
                            'Height: ${_heightRange.start.round()} - ${_heightRange.end.round()} cm',
                            _heightRange,
                            100,
                            220,
                            (values) => setState(() => _heightRange = values),
                            Icons.height_rounded,
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
                          _buildMultiSelectField(
                            'Preferred Caste',
                            _casteController,
                            _selectedCastes,
                            Icons.people_outline,
                            'Enter caste/sub-caste and add',
                            (value) {
                              if (value.isNotEmpty && !_selectedCastes.contains(value)) {
                                setState(() {
                                  _selectedCastes.add(value);
                                  _casteController.clear();
                                });
                              }
                            },
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

                        _buildSection('Income Preference', [
                          _buildIncomeRangeSlider(),
                        ]),

                        _buildSection('Location Preferences', [
                          _buildLocationSelector(),
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
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonFooter(),
    );
  }

  Widget _buildGradientHeader(Size size, BuildContext context) {
    return Container(
      width: double.infinity,
      height: size.height * 0.22,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        image: DecorationImage(
          image: const NetworkImage(
            'https://i.pinimg.com/originals/58/36/4b/58364b97bba4c044562b44d6df4010ae.jpg',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
          onError: (exception, stackTrace) {
            // Graceful fallback is handled by the container color
          },
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFB47FFF).withOpacity(0.8),
            const Color(0xFF5CB3FF).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB47FFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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

  Widget _buildMultiSelectField(
    String label,
    TextEditingController controller,
    List<String> selectedItems,
    IconData icon,
    String hint,
    Function(String) onAdd,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF5CB3FF)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFB47FFF)),
              onPressed: () => onAdd(controller.text.trim()),
            ),
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
              borderSide: BorderSide(color: const Color(0xFF5CB3FF), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onFieldSubmitted: (value) => onAdd(value.trim()),
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedItems.map((item) {
              return Chip(
                label: Text(
                  item,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                backgroundColor: const Color(0xFFB47FFF),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                onDeleted: () {
                  setState(() {
                    selectedItems.remove(item);
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ],
      ],
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

  Widget _buildIncomeRangeSlider() {
    double minAnnual = (_incomeRange.start * 12 / 100);
    double maxAnnual = (_incomeRange.end * 12 / 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_rounded, size: 20, color: Color(0xFF5CB3FF)),
                  const SizedBox(width: 10),
                  Text(
                    'Monthly: ₹${_formatSalary(_incomeRange.start)} - ₹${_formatSalary(_incomeRange.end)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CD9A6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Annual: ${minAnnual.toStringAsFixed(1)} - ${maxAnnual.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8B57),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFB47FFF),
              inactiveTrackColor: const Color(0xFFB47FFF).withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFB47FFF).withOpacity(0.1),
              valueIndicatorColor: const Color(0xFFB47FFF),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
                elevation: 4,
              ),
            ),
            child: RangeSlider(
              values: _incomeRange,
              min: 0,
              max: 800, // 8 Lakhs per month
              divisions: 160, // 5k increments
              labels: RangeLabels(
                '₹${_formatSalary(_incomeRange.start)}',
                '₹${_formatSalary(_incomeRange.end)}',
              ),
              onChanged: (values) => setState(() => _incomeRange = values),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹0', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text('₹8L/mo', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSalary(double kAmount) {
    if (kAmount < 100) {
      return '${kAmount.round()}k';
    } else {
      return '${(kAmount / 100).toStringAsFixed(1)}L';
    }
  }

  Widget _buildRangeSlider(
    String label,
    RangeValues values,
    double min,
    double max,
    void Function(RangeValues) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF5CB3FF)),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFB47FFF),
              inactiveTrackColor: const Color(0xFFB47FFF).withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFB47FFF).withOpacity(0.1),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              valueIndicatorColor: const Color(0xFFB47FFF),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
                elevation: 4,
              ),
            ),
            child: RangeSlider(
              values: values,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              labels: RangeLabels(
                values.start.round().toString(),
                values.end.round().toString(),
              ),
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${min.round()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text('${max.round()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          _locationSearchController,
          'Add Preferred District/City',
          Icons.location_city_rounded,
          hint: 'Type a place and tap search icon',
          suffixIcon: IconButton(
            icon: const Icon(Icons.person_search_rounded, color: Color(0xFFB47FFF)),
            onPressed: () async {
              final query = _locationSearchController.text.trim();
              if (query.isEmpty) return;
              
              setState(() => _isLoading = true);
              try {
                final data = await LocationService.searchAddressByCity(query);
                if (data != null) {
                  String? district = data['district'];
                  if (district != null) {
                    district = district.replaceAll(' District', '').trim();
                    if (!_preferredLocations.contains(district)) {
                      setState(() {
                        _preferredLocations.add(district!);
                        _locationSearchController.clear();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('District already in list')),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not find location')),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
          ),
        ),
        if (_preferredLocations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _preferredLocations.map((location) {
              return Chip(
                label: Text(
                  location,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                backgroundColor: const Color(0xFFB47FFF),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                onDeleted: () {
                  setState(() {
                    _preferredLocations.remove(location);
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ],
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
    Widget? suffixIcon,
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
        suffixIcon: suffixIcon,
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
    _casteController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }
}

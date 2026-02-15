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
  int? _religionId;
  List<String> _selectedCastes = [];
  List<int> _selectedCasteIds = [];
  List<int> _selectedSubCasteIds = [];
  final TextEditingController _casteController = TextEditingController();
  
  // Master data from API
  List<Map<String, dynamic>> _religionsData = [];
  List<Map<String, dynamic>> _availableCastesData = [];
  List<Map<String, dynamic>> _availableSubCastesData = [];
  List<Map<String, dynamic>> _educationOptions = [];
  List<Map<String, dynamic>> _occupationOptions = [];
  List<int> _selectedEducationIds = [];
  List<int> _selectedOccupationIds = [];

  // Income preferences
  RangeValues _incomeRange = const RangeValues(0, 30);

  // Location preferences
  List<String> _preferredLocations = [];
  double _maxDistance = 50.0;
  final TextEditingController _locationSearchController = TextEditingController();

  bool _isLoading = false;
  bool _isDataLoading = true;
  String? _errorMessage;

  // Habits preferences
  String _selectedDrugAddiction = 'any';
  List<String> _selectedSmoke = ['never', 'occasionally', 'regularly'];
  List<String> _selectedAlcohol = ['never', 'occasionally', 'regularly'];

  // Sorting states
  bool _isEducationAscending = false;
  bool _isOccupationAscending = false;
  bool _isCasteAscending = false;
  bool _isSubCasteAscending = false;

  // Search queries and controllers
  String _casteSearchQuery = '';
  final TextEditingController _casteSearchController = TextEditingController();
  
  String _subCasteSearchQuery = '';
  final TextEditingController _subCasteSearchController = TextEditingController();
  
  String _educationSearchQuery = '';
  final TextEditingController _educationSearchController = TextEditingController();
  
  String _occupationSearchQuery = '';
  final TextEditingController _occupationSearchController = TextEditingController();

  final List<String> _maritalStatusOptions = [
    'never_married',
    'nikkah_divorced',
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
    _loadPreferenceOptions();
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
        final profile = data['user']['user_profile'];
        final preferences = data['user']['preferences'];
        final userReligion = profile?['religion'];
        final userReligionId = profile?['religion_id'];

        if (preferences != null) {
          _initializeControllersWithData(preferences, userReligion, userReligionId);
        } else {
          _initializeEmptyControllers(userReligion, userReligionId);
        }
        _updateAvailableCastes();
      } else if (response.statusCode == 404) {
        _initializeEmptyControllers(null, null);
      } else {
        setState(() {
          _errorMessage = 'Failed to load preferences';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading preferences: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDataLoading = false;
        });
      }
    }
  }

  void _initializeEmptyControllers(String? userReligion, int? userReligionId) {
    _ageRange = const RangeValues(18, 50);
    _heightRange = const RangeValues(140, 180);
    _maritalStatus = null;
    _religion = userReligion;
    _religionId = userReligionId;
    _selectedCastes = [];
    _selectedCasteIds = [];
    _selectedSubCasteIds = [];
    _casteController.text = '';
    _selectedEducationIds = [];
    _selectedOccupationIds = [];
    _incomeRange = const RangeValues(0, 30);
    _preferredLocations = [];
    _maxDistance = 50.0;
    _locationSearchController.text = '';
    _selectedDrugAddiction = 'any';
    _selectedSmoke = ['never', 'occasionally', 'regularly'];
    _selectedAlcohol = ['never', 'occasionally', 'regularly'];
  }

  void _initializeControllersWithData(Map<String, dynamic> preferences, String? userReligion, int? userReligionId) {
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
    _maritalStatus = preferences['marital_status']?.toString();
    _religionId = userReligionId ?? (preferences['religion_id'] != null ? int.tryParse(preferences['religion_id'].toString()) : null);
    _religion = userReligion ?? preferences['religion_model']?['name']?.toString();
    
    if (preferences['caste_ids'] != null && preferences['caste_ids'] is List) {
      _selectedCasteIds = (preferences['caste_ids'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
    } else {
      _selectedCasteIds = [];
    }

    if (preferences['sub_caste_ids'] != null && preferences['sub_caste_ids'] is List) {
      _selectedSubCasteIds = (preferences['sub_caste_ids'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
    } else {
      _selectedSubCasteIds = [];
    }
    _selectedCastes = []; // We can populate this later if needed for UI chips
    _casteController.text = '';
    
    // Handle education and occupation as arrays of IDs
    if (preferences['education'] != null) {
      if (preferences['education'] is List) {
        _selectedEducationIds = (preferences['education'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      }
    } else {
      _selectedEducationIds = [];
    }
    
    if (preferences['occupation'] != null) {
      if (preferences['occupation'] is List) {
        _selectedOccupationIds = (preferences['occupation'] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      }
    } else {
      _selectedOccupationIds = [];
    }
    double incomeStartAnnual = double.tryParse(preferences['min_income']?.toString() ?? '0') ?? 0;
    double incomeEndAnnual = double.tryParse(preferences['max_income']?.toString() ?? '30') ?? 30;
    // Store internally as Monthly Thousands (K)
    _incomeRange = RangeValues(
      (incomeStartAnnual * 100 / 12).clamp(0, 800),
      (incomeEndAnnual * 100 / 12).clamp(0, 800)
    );
    _preferredLocations = preferences['preferred_locations'] != null && preferences['preferred_locations'] is List
        ? (preferences['preferred_locations'] as List).map((e) => e.toString()).toList()
        : [];
    _maxDistance = double.tryParse(preferences['max_distance']?.toString() ?? '50') ?? 50.0;
    _locationSearchController.text = '';

    _selectedDrugAddiction = preferences['drug_addiction']?.toString() ?? 'any';
    if (preferences['smoke'] != null && preferences['smoke'] is List) {
      _selectedSmoke = (preferences['smoke'] as List).map((e) => e.toString()).toList();
    } else {
      _selectedSmoke = ['never', 'occasionally', 'regularly'];
    }
    if (preferences['alcohol'] != null && preferences['alcohol'] is List) {
      _selectedAlcohol = (preferences['alcohol'] as List).map((e) => e.toString()).toList();
    } else {
      _selectedAlcohol = ['never', 'occasionally', 'regularly'];
    }
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
        religionId: _religionId,
        casteIds: _selectedCasteIds,
        subCasteIds: _selectedSubCasteIds,
        educationIds: _selectedEducationIds,
        occupationIds: _selectedOccupationIds,
        minIncome: (_incomeRange.start * 12 / 100),
        maxIncome: (_incomeRange.end * 12 / 100),
        maxDistance: _maxDistance.round(),
        preferredLocations: _preferredLocations,
        drugAddiction: _selectedDrugAddiction,
        smoke: _selectedSmoke,
        alcohol: _selectedAlcohol,
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFF00BCD4)),
              SizedBox(height: 16),
              Text('Loading preferences...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadPreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Age', [
                  _buildRangeSlider(
                    'Age: ${_ageRange.start.round()} - ${_ageRange.end.round()} Years',
                    _ageRange,
                    18,
                    70,
                    (values) => setState(() => _ageRange = values),
                    Icons.calendar_month_rounded,
                  ),
                ]),

                _buildSection('Height', [
                  _buildRangeSlider(
                    'Height: ${_heightRange.start.round()} - ${_heightRange.end.round()} cm',
                    _heightRange,
                    100,
                    220,
                    (values) => setState(() => _heightRange = values),
                    Icons.height_rounded,
                  ),
                ]),

                _buildSection('Basic Details', [
                  _buildDropdown(
                    'Marital Status',
                    _maritalStatus,
                    _maritalStatusOptions,
                    Icons.favorite_outline,
                    (value) {
                      setState(() => _maritalStatus = value);
                    },
                    formatLabel: true,
                  ),
                  const SizedBox(height: 10),
                  // Preferred Religion is now forced to match user's religion and hidden
                  const SizedBox(height: 10),
                  _buildCheckboxSelector(
                    'Caste',
                    _availableCastesData,
                    _selectedCasteIds,
                    Icons.people_outline,
                    (id, selected) {
                      setState(() {
                        if (selected) {
                          _selectedCasteIds.add(id);
                        } else {
                          _selectedCasteIds.remove(id);
                        }
                        _updateAvailableSubCastes();
                      });
                    },
                    isAscending: _isCasteAscending,
                    onSortToggled: () {
                      setState(() => _isCasteAscending = !_isCasteAscending);
                    },
                    searchQuery: _casteSearchQuery,
                    controller: _casteSearchController,
                    onSearchChanged: (val) => setState(() => _casteSearchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckboxSelector(
                    'Sub-Caste',
                    _availableSubCastesData,
                    _selectedSubCasteIds,
                    Icons.group_work_rounded,
                    (id, selected) {
                      setState(() {
                        if (selected) {
                          _selectedSubCasteIds.add(id);
                        } else {
                          _selectedSubCasteIds.remove(id);
                        }
                      });
                    },
                    isAscending: _isSubCasteAscending,
                    onSortToggled: () {
                      setState(() => _isSubCasteAscending = !_isSubCasteAscending);
                    },
                    searchQuery: _subCasteSearchQuery,
                    controller: _subCasteSearchController,
                    onSearchChanged: (val) => setState(() => _subCasteSearchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckboxSelector(
                    'Education',
                    _educationOptions,
                    _selectedEducationIds,
                    Icons.school,
                    (id, selected) {
                      setState(() {
                        if (selected) {
                          _selectedEducationIds.add(id);
                        } else {
                          _selectedEducationIds.remove(id);
                        }
                      });
                    },
                    isAscending: _isEducationAscending,
                    onSortToggled: () {
                      setState(() => _isEducationAscending = !_isEducationAscending);
                    },
                    searchQuery: _educationSearchQuery,
                    controller: _educationSearchController,
                    onSearchChanged: (val) => setState(() => _educationSearchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckboxSelector(
                    'Occupation',
                    _occupationOptions,
                    _selectedOccupationIds,
                    Icons.work_outline,
                    (id, selected) {
                      setState(() {
                        if (selected) {
                          _selectedOccupationIds.add(id);
                        } else {
                          _selectedOccupationIds.remove(id);
                        }
                      });
                    },
                    isAscending: _isOccupationAscending,
                    onSortToggled: () {
                      setState(() => _isOccupationAscending = !_isOccupationAscending);
                    },
                    searchQuery: _occupationSearchQuery,
                    controller: _occupationSearchController,
                    onSearchChanged: (val) => setState(() => _occupationSearchQuery = val),
                  ),
                ]),

                _buildSection('Distance', [
                  _buildSingleSlider(
                    'Search Radius: ${_maxDistance.round()} km',
                    _maxDistance,
                    1,
                    200,
                    (value) => setState(() => _maxDistance = value),
                    Icons.near_me_outlined,
                  ),
                ]),

                _buildSection('Income', [
                  _buildIncomeRangeSlider(),
                ]),

                _buildSection('Locations', [
                  _buildLocationSelector(),
                ]),

                _buildSection('Habits & Lifestyle', [
                  _buildDropdown(
                    'Drug Addiction Preference',
                    _selectedDrugAddiction,
                    ['any', 'yes', 'no'],
                    Icons.medical_services_outlined,
                    (value) => setState(() => _selectedDrugAddiction = value!),
                    formatLabel: true,
                  ),
                  if (_selectedDrugAddiction != 'no') ...[
                    const SizedBox(height: 16),
                    _buildHabitMultiSelect(
                      'Drinking Habit',
                      _selectedAlcohol,
                      Icons.local_bar,
                      (val, selected) {
                        setState(() {
                          if (selected) {
                            if (val == 'never') {
                              _selectedAlcohol = ['never'];
                            } else {
                              _selectedAlcohol.remove('never');
                              if (!_selectedAlcohol.contains(val)) {
                                _selectedAlcohol.add(val);
                              }
                            }
                          } else {
                            if (_selectedAlcohol.length > 1) {
                              _selectedAlcohol.remove(val);
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildHabitMultiSelect(
                      'Smoking Habit',
                      _selectedSmoke,
                      Icons.smoke_free,
                      (val, selected) {
                        setState(() {
                          if (selected) {
                            if (val == 'never') {
                              _selectedSmoke = ['never'];
                            } else {
                              _selectedSmoke.remove('never');
                              if (!_selectedSmoke.contains(val)) {
                                _selectedSmoke.add(val);
                              }
                            }
                          } else {
                            if (_selectedSmoke.length > 1) {
                              _selectedSmoke.remove(val);
                            }
                          }
                        });
                      },
                    ),
                  ],
                ]),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonFooter(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        children: const [
          Text(
            'Preferences',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Find your perfect match',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _savePreferences,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00BCD4),
                  ),
                )
              : const Text(
                  'Update',
                  style: TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey.withOpacity(0.1),
          height: 1,
        ),
      ),
    );
  }

  // Remove the old _buildGradientHeader method if needed, but let's keep it clean
  // and focus on the new professionally built one below if we want more flair.
  


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
            prefixIcon: Icon(icon, color: const Color(0xFF00BCD4)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF00BCD4)),
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
              borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
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
                backgroundColor: const Color(0xFF00BCD4),
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
                  const Icon(Icons.payments_rounded, size: 20, color: Color(0xFF00BCD4)),
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
                  color: const Color(0xFF00BCD4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Annual: ${minAnnual.toStringAsFixed(1)} - ${maxAnnual.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00BCD4),
              inactiveTrackColor: const Color(0xFF00BCD4).withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF00BCD4).withOpacity(0.1),
              valueIndicatorColor: const Color(0xFF00BCD4),
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
              Icon(icon, size: 20, color: const Color(0xFF00BCD4)),
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
              activeTrackColor: const Color(0xFF00BCD4),
              inactiveTrackColor: const Color(0xFF00BCD4).withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF00BCD4).withOpacity(0.1),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              valueIndicatorColor: const Color(0xFF00BCD4),
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

  Widget _buildSingleSlider(
    String label,
    double value,
    double min,
    double max,
    void Function(double) onChanged,
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
              Icon(icon, size: 20, color: const Color(0xFF00BCD4)),
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
              activeTrackColor: const Color(0xFF00BCD4),
              inactiveTrackColor: const Color(0xFF00BCD4).withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF00BCD4).withOpacity(0.1),
              valueIndicatorColor: const Color(0xFF00BCD4),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              label: value.round().toString(),
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${min.round()} km', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                Text('${max.round()} km', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
            icon: const Icon(Icons.person_search_rounded, color: Color(0xFF00BCD4)),
            onPressed: () async {
              final query = _locationSearchController.text.trim();
              if (query.isEmpty) return;
              
              setState(() => _isLoading = true);
              try {
                final data = await LocationService.searchAddressByCity(query);
                if (data != null && mounted) {
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
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not find location')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
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
                backgroundColor: const Color(0xFF00BCD4),
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
        prefixIcon: Icon(icon, color: const Color(0xFF00BCD4)),
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
          borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
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
        prefixIcon: Icon(icon, color: const Color(0xFF00BCD4)),
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
          borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
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

  void _updateAvailableCastes() {
    if (_religionId == null || _religionsData.isEmpty) return;

    final currentReligion = _religionsData.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r?['id'] == _religionId,
      orElse: () => null,
    );

    if (currentReligion != null) {
      if (!mounted) return;
      setState(() {
        _availableCastesData = List<Map<String, dynamic>>.from(currentReligion['castes'] ?? []);
        _updateAvailableSubCastes();
      });
    }
  }

  void _updateAvailableSubCastes() {
    if (_selectedCasteIds.isEmpty) {
      setState(() {
        _availableSubCastesData = [];
      });
      return;
    }

    List<Map<String, dynamic>> subCastes = [];
    for (var casteId in _selectedCasteIds) {
      final caste = _availableCastesData.firstWhere(
        (c) => c['id'] == casteId,
        orElse: () => {},
      );
      if (caste.containsKey('sub_castes') && caste['sub_castes'] is List) {
        subCastes.addAll(List<Map<String, dynamic>>.from(caste['sub_castes']));
      }
    }

    setState(() {
      _availableSubCastesData = subCastes;
    });
  }

  Future<void> _loadPreferenceOptions() async {
    try {
      final response = await ProfileService.getPreferenceOptions();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (!mounted) return;
          setState(() {
            _religionsData = List<Map<String, dynamic>>.from(data['data']['religions'] ?? []);
            
            _updateAvailableCastes();

            _educationOptions = List<Map<String, dynamic>>.from(
              data['data']['educations'].map((e) => {
                'id': e['id'],
                'name': e['name'],
                'order_number': e['order_number'],
                'popularity_count': e['popularity_count'] ?? 0,
              })
            );
            _occupationOptions = List<Map<String, dynamic>>.from(
              data['data']['occupations'].map((o) => {
                'id': o['id'],
                'name': o['name'],
                'order_number': o['order_number'],
                'popularity_count': o['popularity_count'] ?? 0,
              })
            );
          });
        }
      }
    } catch (e) {
      print('Error loading preference options: $e');
    }
  }

  Widget _buildCheckboxSelector(
    String label,
    List<Map<String, dynamic>> options,
    List<int> selectedIds,
    IconData icon,
    Function(int, bool) onChanged, {
    required bool isAscending,
    required VoidCallback onSortToggled,
    required String searchQuery,
    required TextEditingController controller,
    required Function(String) onSearchChanged,
  }) {
    // 1. Filter based on search query
    final filteredBySearch = options.where((option) {
      if (searchQuery.isEmpty) return true;
      final name = (option['name']?.toString() ?? '').toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    // 2. Sort the filtered options
    final sortedOptions = List<Map<String, dynamic>>.from(filteredBySearch);
    if (isAscending) {
      sortedOptions.sort((a, b) => (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? ''));
    } else {
      sortedOptions.sort((a, b) {
        final popA = a['popularity_count'] ?? 0;
        final popB = b['popularity_count'] ?? 0;
        final valA = popA is num ? popA.toInt() : 0;
        final valB = popB is num ? popB.toInt() : 0;
        // Primary sort: popularity (descending)
        int cmp = valB.compareTo(valA);
        if (cmp == 0) {
          // Secondary sort: name (ascending)
          return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
        }
        return cmp;
      });
    }

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
          // Header Row: Icon, Label, and Sort Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: const Color(0xFF00BCD4)),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sort:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onSortToggled,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trending Option
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: !isAscending ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: !isAscending
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 14,
                                  color: !isAscending ? const Color(0xFF00BCD4) : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Trending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: !isAscending ? const Color(0xFF00BCD4) : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // A-Z Option
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAscending ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: isAscending
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_by_alpha_rounded,
                                  size: 14,
                                  color: isAscending ? const Color(0xFF00BCD4) : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'A-Z',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isAscending ? const Color(0xFF00BCD4) : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Search Field
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search $label...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (sortedOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 30, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      searchQuery.isEmpty ? 'Loading options...' : 'No results matching "$searchQuery"',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedOptions.map((option) {
                final isSelected = selectedIds.contains(option['id']);
                final isTrending = (option['popularity_count'] ?? 0) > 10;
                
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(option['name'] ?? ''),
                      if (isTrending) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.trending_up, size: 14, color: Color(0xFF00BCD4)),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    onChanged(option['id'], selected);
                  },
                  selectedColor: const Color(0xFF00BCD4).withOpacity(0.3),
                  checkmarkColor: const Color(0xFF00BCD4),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF00BCD4) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          
          if (selectedIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${selectedIds.length} selected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitMultiSelect(
    String label,
    List<String> selectedItems,
    IconData icon,
    Function(String, bool) onSelected,
  ) {
    final List<String> habitOptions = ['never', 'occasionally', 'regularly'];

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
              Icon(icon, size: 20, color: const Color(0xFF00BCD4)),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: habitOptions.map((option) {
              final isSelected = selectedItems.contains(option);
              return FilterChip(
                label: Text(
                  option[0].toUpperCase() + option.substring(1),
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF00BCD4) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) => onSelected(option, selected),
                selectedColor: const Color(0xFF00BCD4).withOpacity(0.1),
                checkmarkColor: const Color(0xFF00BCD4),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF00BCD4) : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _casteController.dispose();
    _locationSearchController.dispose();
    _casteSearchController.dispose();
    _subCasteSearchController.dispose();
    _educationSearchController.dispose();
    _occupationSearchController.dispose();
    super.dispose();
  }
}
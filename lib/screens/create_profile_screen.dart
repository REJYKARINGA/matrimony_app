import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/profile_service.dart';
import '../services/auth_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/app_colors.dart';
import '../widgets/profile_creation_widgets.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({Key? key}) : super(key: key);

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 12; // Increased for Preview step

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dateOfBirthController;
  String? _selectedGender;
  double _height = 170;
  double _weight = 70;
  String? _selectedMaritalStatus;
  late TextEditingController _religionController;
  late TextEditingController _casteController;
  late TextEditingController _subCasteController;
  late TextEditingController _motherTongueController;
  late TextEditingController _educationController;
  late TextEditingController _occupationController;
  late TextEditingController _annualIncomeController;
  late TextEditingController _cityController;
  String? _selectedDistrict;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _bioController;
  bool _drugAddiction = false;
  String _smoke = 'never';
  String _alcohol = 'never';
  bool _isLoading = false;

  final List<String> _keralaDistricts = [
    'Thiruvananthapuram', 'Kollam', 'Pathanamthitta', 'Alappuzha', 'Kottayam',
    'Idukki', 'Ernakulam', 'Thrissur', 'Palakkad', 'Malappuram', 'Kozhikode',
    'Wayanad', 'Kannur', 'Kasaragod',
  ];

  // Master data for searchable selects
  List<dynamic> _religions = [];
  List<dynamic> _availableCastes = [];
  List<dynamic> _availableSubCastes = [];
  List<dynamic> _educations = [];
  List<dynamic> _occupations = [];

  // Selected IDs
  int? _selectedReligionId;
  int? _selectedCasteId;
  int? _selectedSubCasteId;
  int? _selectedEducationId;
  int? _selectedOccupationId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadOptions();
    
    // Redirect if profile already exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.hasProfile) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  Future<void> _loadOptions() async {
    try {
      final response = await ProfileService.getPreferenceOptions();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _religions = data['data']['religions'] ?? [];
            _educations = data['data']['educations'] ?? [];
            _occupations = data['data']['occupations'] ?? [];
          });
          
          _updateAvailableCastes(_religionController.text);
          _updateAvailableSubCastes(_casteController.text);
        }
      }
    } catch (e) {
      debugPrint('Error loading options: $e');
    }
  }

  void _updateAvailableCastes(String religionName) {
    if (religionName.isEmpty) {
      setState(() => _availableCastes = []);
      return;
    }
    
    final religion = _religions.firstWhere(
      (r) => r['name'] == religionName,
      orElse: () => null,
    );
    
    setState(() {
      _availableCastes = religion != null ? religion['castes'] : [];
    });
  }

  void _updateAvailableSubCastes(String casteName) {
    if (casteName.isEmpty) {
      setState(() => _availableSubCastes = []);
      return;
    }
    
    final caste = _availableCastes.firstWhere(
      (c) => c['name'] == casteName,
      orElse: () => null,
    );
    
    setState(() {
      _availableSubCastes = caste != null ? caste['sub_castes'] : [];
    });
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _religionController = TextEditingController();
    _casteController = TextEditingController();
    _subCasteController = TextEditingController();
    _motherTongueController = TextEditingController();
    _educationController = TextEditingController();
    _occupationController = TextEditingController();
    _annualIncomeController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController(text: 'Kerala');
    _countryController = TextEditingController(text: 'India');
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _religionController.dispose();
    _casteController.dispose();
    _subCasteController.dispose();
    _motherTongueController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _annualIncomeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ProfileService.updateMyProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: DateFormatter.parseDate(_dateOfBirthController.text),
        gender: _selectedGender,
        height: _height.round(),
        weight: _weight.round(),
        maritalStatus: _selectedMaritalStatus,
        religionId: _selectedReligionId,
        casteId: _selectedCasteId,
        subCasteId: _selectedSubCasteId,
        motherTongue: _motherTongueController.text,
        educationId: _selectedEducationId,
        occupationId: _selectedOccupationId,
        annualIncome: double.tryParse(_annualIncomeController.text),
        city: _cityController.text,
        district: _selectedDistrict,
        state: _stateController.text,
        country: _countryController.text,
        bio: _bioController.text,
        drugAddiction: _drugAddiction,
        smoke: _smoke,
        alcohol: _alcohol,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadCurrentUserWithProfile();
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to create profile'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ProgressIndicatorRow(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              onBackPressed: _previousStep,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (int page) {
                    setState(() => _currentStep = page);
                  },
                  children: [
                    _buildNameStep(),
                    _buildGenderStep(),
                    _buildDOBStep(),
                    _buildWeightStep(),
                    _buildHeightStep(),
                    _buildMaritalStatusStep(),
                    _buildHabitsStep(),
                    _buildReligionStep(),
                    _buildEducationStep(),
                    _buildLocationStep(),
                    _buildBioStep(),
                    _buildPreviewStep(),
                  ],
                ),
              ),
            ),
            StepNavigationButtons(
              currentStep: _currentStep,
              onNext: _nextStep,
              onBack: _previousStep,
              isLoading: _isLoading,
              nextText: _currentStep == _totalSteps - 1 ? 'Complete' : 'Next',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerList({
    required ScrollController controller,
    required List<dynamic> items,
    required Function(dynamic) onSelected,
    required String searchText,
  }) {
    final filteredItems = items.where((item) {
      final name = item is String ? item : (item['name'] ?? '').toString();
      return name.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: filteredItems.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey[100]),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final name = item is String ? item : (item['name'] ?? '').toString();
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () {
            onSelected(item);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _openSearchablePicker({
    required String title,
    required List<dynamic> items,
    required TextEditingController controller,
    Function(dynamic)? onSelected,
  }) {
    String searchText = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search $title...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        searchText = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildPickerList(
                    controller: scrollController,
                    items: items,
                    searchText: searchText,
                    onSelected: (selectedItem) {
                      final name = selectedItem is String ? selectedItem : (selectedItem['name'] ?? '').toString();
                      controller.text = name;
                      if (onSelected != null) onSelected(selectedItem);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContainer({required String title, required String subtitle, required Widget child}) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StepHeader(title: title, subtitle: subtitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
            const SizedBox(height: 40), // Bottom padding for better visual balance
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return _buildStepContainer(
      title: 'Introduce Yourself',
      subtitle: 'To give you a better experience and results we need to know your name.',
      child: Column(
        children: [
          _buildTextField(controller: _firstNameController, label: 'First Name', icon: Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(controller: _lastNameController, label: 'Last Name', icon: Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    return _buildStepContainer(
      title: 'Gender',
      subtitle: 'To give you a better experience and results we need to know your gender.',
      child: FormField<String>(
        initialValue: _selectedGender,
        validator: (value) => value == null ? 'Please select your gender' : null,
        builder: (state) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GenderCard(
                    title: 'Male',
                    icon: Icons.face,
                    isSelected: state.value == 'male',
                    onTap: () {
                      state.didChange('male');
                      setState(() => _selectedGender = 'male');
                    },
                  ),
                  GenderCard(
                    title: 'Female',
                    icon: Icons.face_retouching_natural,
                    isSelected: state.value == 'female',
                    onTap: () {
                      state.didChange('female');
                      setState(() => _selectedGender = 'female');
                    },
                  ),
                ],
              ),
              if (state.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorText!,
                  style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeightStep() {
    return _buildStepContainer(
      title: 'Weight',
      subtitle: 'Weight in kg is flexible, so feel free to adjust it later.',
      child: CustomRulerPicker(
        minValue: 30,
        maxValue: 150,
        initialValue: _weight,
        unit: 'Kg',
        onChanged: (val) => _weight = val,
      ),
    );
  }

  Widget _buildHeightStep() {
    return _buildStepContainer(
      title: 'Height',
      subtitle: 'Height in cm don\'t worry you can always change it later.',
      child: CustomRulerPicker(
        minValue: 100,
        maxValue: 220,
        initialValue: _height,
        unit: 'Cm',
        onChanged: (val) => _height = val,
      ),
    );
  }

  Widget _buildDOBStep() {
    return _buildStepContainer(
      title: 'Date of Birth',
      subtitle: 'Your date of birth helps us find better matches.',
      child: FormField<String>(
        initialValue: _dateOfBirthController.text,
        validator: (value) => _dateOfBirthController.text.isEmpty ? 'Please select your date of birth' : null,
        builder: (state) {
          return Column(
            children: [
              CustomDatePickerField(
                label: 'Date of Birth',
                controller: _dateOfBirthController,
                onTap: () {
                  DateTime maxDate = _getMaxDateForAgeValidation();
                  DateTime initialDate = DateFormatter.parseDate(_dateOfBirthController.text) ?? maxDate;
                  
                  if (initialDate.isAfter(maxDate)) initialDate = maxDate;

                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CustomDatePickerModal(
                      initialDate: initialDate,
                      lastDate: maxDate,
                      onDateSelected: (date) {
                        setState(() {
                          _dateOfBirthController.text = DateFormatter.formatDate(date);
                          state.didChange(_dateOfBirthController.text);
                        });
                      },
                    ),
                  );
                },
              ),
              if (state.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: AppColors.primaryBlue, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMaritalStatusStep() {
    return _buildStepContainer(
      title: 'Marital Status',
      subtitle: 'This helps us filter profiles based on your requirements.',
      child: DropdownButtonFormField<String>(
        value: _selectedMaritalStatus,
        decoration: InputDecoration(
          labelText: 'Marital Status',
          prefixIcon: const Icon(Icons.favorite_outline),
        ),
        items: const [
          DropdownMenuItem(value: 'never_married', child: Text('Single')),
          DropdownMenuItem(value: 'nikkah_divorced', child: Text('Nikkah Divorced')),
          DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
          DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
        ],
        validator: (val) => val == null ? 'Required' : null,
        onChanged: (val) => setState(() => _selectedMaritalStatus = val),
      ),
    );
  }

  Widget _buildHabitsStep() {
    return _buildStepContainer(
      title: 'Lifestyle & Habits',
      subtitle: 'Tell us about your lifestyle preferences.',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Drug Addiction'),
            subtitle: const Text('Includes any substance abuse beyond tobacco/alcohol'),
            value: _drugAddiction,
            activeColor: AppColors.primaryBlue,
            onChanged: (val) => setState(() => _drugAddiction = val),
          ),
          const SizedBox(height: 16),
          _buildHabitDropdown('Smoking', _smoke, (val) => setState(() => _smoke = val!)),
          const SizedBox(height: 16),
          _buildHabitDropdown('Alcohol', _alcohol, (val) => setState(() => _alcohol = val!)),
        ],
      ),
    );
  }

  Widget _buildReligionStep() {
    return _buildStepContainer(
      title: 'Religion & Community',
      subtitle: 'Share your cultural background.',
      child: Column(
        children: [
          _buildTextField(
            controller: _religionController,
            label: 'Religion',
            icon: Icons.church,
            readOnly: true,
            onTap: () => _openSearchablePicker(
              title: 'Religion',
              items: _religions,
              controller: _religionController,
              onSelected: (item) {
                setState(() {
                  _selectedReligionId = item['id'];
                  _casteController.clear();
                  _selectedCasteId = null;
                  _subCasteController.clear();
                  _selectedSubCasteId = null;
                  _updateAvailableCastes(_religionController.text);
                  _availableSubCastes = [];
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _casteController,
            label: 'Caste',
            icon: Icons.people_outline,
            readOnly: true,
            onTap: () {
              if (_religionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select religion first')),
                );
                return;
              }
              _openSearchablePicker(
                title: 'Caste',
                items: _availableCastes,
                controller: _casteController,
                onSelected: (item) {
                  setState(() {
                    _selectedCasteId = item['id'];
                    _subCasteController.clear();
                    _selectedSubCasteId = null;
                    _updateAvailableSubCastes(_casteController.text);
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _subCasteController,
            label: 'Sub-caste',
            icon: Icons.people_alt_outlined,
            readOnly: true,
            onTap: () {
              if (_casteController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select caste first')),
                );
                return;
              }
              _openSearchablePicker(
                title: 'Sub-Caste',
                items: _availableSubCastes,
                controller: _subCasteController,
                onSelected: (item) {
                  setState(() {
                    _selectedSubCasteId = item['id'];
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(controller: _motherTongueController, label: 'Mother Tongue', icon: Icons.language),
        ],
      ),
    );
  }

  Widget _buildEducationStep() {
    return _buildStepContainer(
      title: 'Education & career',
      subtitle: 'Tell us about your professional background.',
      child: Column(
        children: [
          _buildTextField(
            controller: _educationController,
            label: 'Education',
            icon: Icons.school,
            readOnly: true,
            onTap: () => _openSearchablePicker(
              title: 'Education',
              items: _educations,
              controller: _educationController,
              onSelected: (item) {
                setState(() {
                  _selectedEducationId = item['id'];
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _occupationController,
            label: 'Occupation',
            icon: Icons.work_outline,
            readOnly: true,
            onTap: () => _openSearchablePicker(
              title: 'Occupation',
              items: _occupations,
              controller: _occupationController,
              onSelected: (item) {
                setState(() {
                  _selectedOccupationId = item['id'];
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(controller: _annualIncomeController, label: 'Annual Income', icon: Icons.currency_rupee, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return _buildStepContainer(
      title: 'Location',
      subtitle: 'Where are you currently located?',
      child: Column(
        children: [
          _buildTextField(controller: _cityController, label: 'City', icon: Icons.location_city),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: InputDecoration(
              labelText: 'District',
              prefixIcon: const Icon(Icons.map),
            ),
            items: _keralaDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            validator: (val) => val == null ? 'Required' : null,
            onChanged: (val) => setState(() => _selectedDistrict = val),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return _buildStepContainer(
      title: 'About You',
      subtitle: 'Write a short bio to let others know you better (min 20 chars).',
      child: _buildTextField(controller: _bioController, label: 'Bio', icon: Icons.edit_note, maxLines: 4),
    );
  }

  Widget _buildPreviewStep() {
    return _buildStepContainer(
      title: 'Review Profile',
      subtitle: 'Make sure everything looks correct before submitting.',
      child: Column(
        children: [
          _buildPreviewSection(
            title: 'Personal Information',
            icon: Icons.person_outline,
            items: [
              _buildPreviewItem('Name', '${_firstNameController.text} ${_lastNameController.text}'),
              _buildPreviewItem('Gender', _selectedGender?.toUpperCase() ?? ''),
              _buildPreviewItem('Birthday', _dateOfBirthController.text),
              _buildPreviewItem('Marital Status', _selectedMaritalStatus?.replaceAll('_', ' ').toUpperCase() ?? ''),
              _buildPreviewItem('Height/Weight', '${_height.round()} cm / ${_weight.round()} kg'),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewSection(
            title: 'Religion & Community',
            icon: Icons.church_outlined,
            items: [
              _buildPreviewItem('Religion', _religionController.text),
              _buildPreviewItem('Caste', _casteController.text),
              if (_subCasteController.text.isNotEmpty)
                _buildPreviewItem('Sub-caste', _subCasteController.text),
              _buildPreviewItem('Mother Tongue', _motherTongueController.text),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewSection(
            title: 'Professional Details',
            icon: Icons.work_outline,
            items: [
              _buildPreviewItem('Education', _educationController.text),
              _buildPreviewItem('Occupation', _occupationController.text),
              _buildPreviewItem('Annual Income', '₹${_annualIncomeController.text}'),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewSection(
            title: 'Location',
            icon: Icons.location_on_outlined,
            items: [
              _buildPreviewItem('City', _cityController.text),
              _buildPreviewItem('District', _selectedDistrict ?? ''),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewSection(
            title: 'Lifestyle Habits',
            icon: Icons.nightlife_outlined,
            items: [
              _buildPreviewItem('Smoking', _smoke.toUpperCase()),
              _buildPreviewItem('Alcohol', _alcohol.toUpperCase()),
              _buildPreviewItem('Drug Addiction', _drugAddiction ? 'YES' : 'NO'),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewSection(
            title: 'Bio',
            icon: Icons.edit_note,
            child: Text(
              _bioController.text,
              style: const TextStyle(color: Colors.black87, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPreviewSection({required String title, required IconData icon, List<Widget>? items, Widget? child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryCyan.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryCyan),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items != null) ...items,
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    if (value.isEmpty || value == 'NULL' || value == '0') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: readOnly ? const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryCyan) : null,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Required';
        if (label == 'Bio' && val.length < 20) return 'Minimum 20 characters required';
        return null;
      },
    );
  }

  Widget _buildHabitDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(label == 'Smoking' ? Icons.smoke_free : Icons.local_bar),
      ),
      items: const [
        DropdownMenuItem(value: 'never', child: Text('Never')),
        DropdownMenuItem(value: 'occasionally', child: Text('Occasionally')),
        DropdownMenuItem(value: 'regularly', child: Text('Regularly')),
      ],
      onChanged: onChanged,
    );
  }

  DateTime _getMaxDateForAgeValidation() {
    DateTime now = DateTime.now();
    if (_selectedGender == 'female') {
      return DateTime(now.year - 18, now.month, now.day);
    } else {
      // Default to 21 for male or if gender not yet selected
      return DateTime(now.year - 21, now.month, now.day);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/profile_service.dart';
import '../services/auth_provider.dart';
import '../utils/date_formatter.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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
        religion: _religionController.text,
        caste: _casteController.text,
        subCaste: _subCasteController.text,
        motherTongue: _motherTongueController.text,
        education: _educationController.text,
        occupation: _occupationController.text,
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
      backgroundColor: const Color(0xFFF2F9F9), // Light mint/neutral background
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
                  style: const TextStyle(color: Color(0xFF003840), fontWeight: FontWeight.bold, fontSize: 13),
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
                    color: Color(0xFF003840), 
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
        decoration: _inputDecoration(label: 'Marital Status', icon: Icons.favorite_outline),
        items: const [
          DropdownMenuItem(value: 'never_married', child: Text('Never Married')),
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
            activeColor: const Color(0xFF003840),
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
          _buildTextField(controller: _religionController, label: 'Religion', icon: Icons.church),
          const SizedBox(height: 16),
          _buildTextField(controller: _casteController, label: 'Caste', icon: Icons.people_outline),
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
          _buildTextField(controller: _educationController, label: 'Education', icon: Icons.school),
          const SizedBox(height: 16),
          _buildTextField(controller: _occupationController, label: 'Occupation', icon: Icons.work_outline),
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
            decoration: _inputDecoration(label: 'District', icon: Icons.map),
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreviewItem('Name', '${_firstNameController.text} ${_lastNameController.text}'),
            _buildPreviewItem('Gender', _selectedGender?.toUpperCase() ?? ''),
            _buildPreviewItem('Birthday', _dateOfBirthController.text),
            _buildPreviewItem('Marital Status', _selectedMaritalStatus?.replaceAll('_', ' ').toUpperCase() ?? ''),
            _buildPreviewItem('Height/Weight', '${_height.round()} cm / ${_weight.round()} kg'),
            _buildPreviewItem('Religion', '${_religionController.text} (${_casteController.text})'),
            _buildPreviewItem('Education', _educationController.text),
            _buildPreviewItem('Location', '${_cityController.text}, ${_selectedDistrict ?? ''}'),
            const Divider(),
            const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_bioController.text, style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003840))),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(label: label, icon: icon),
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
      decoration: _inputDecoration(label: label, icon: label == 'Smoking' ? Icons.smoke_free : Icons.local_bar),
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

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF003840)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF003840), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF003840), width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF003840), width: 2)),
      errorStyle: const TextStyle(color: Color(0xFF003840), fontWeight: FontWeight.bold),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../services/auth_provider.dart';
import '../utils/date_formatter.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({Key? key}) : super(key: key);

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dateOfBirthController;
  String? _selectedGender;
  String? _selectedHeight;
  String? _selectedWeight;
  String? _selectedMaritalStatus;
  String? _selectedReligion;
  late TextEditingController _casteController;
  late TextEditingController _subCasteController;
  String? _selectedMotherTongue;
  String? _selectedEducation;
  late TextEditingController _customEducationController;
  String? _selectedOccupation;
  late TextEditingController _customOccupationController;
  String? _selectedAnnualIncome;
  late TextEditingController _cityController;
  String? _selectedDistrict;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  final List<String> _keralaDistricts = [
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  final List<Map<String, String>> _heights = [];
  final List<String> _weights = [];
  final List<String> _religions = ['Muslim', 'Hindu', 'Christian'];
  final List<String> _motherTongues = [
    'Malayalam',
    'Tamil',
    'Hindi',
    'English',
    'Kannada',
    'Telugu',
  ];
  final List<String> _educationOptions = [
    'High School',
    'Higher Secondary',
    'Diploma',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'Doctorate/PhD',
    'Engineering',
    'Medical',
    'Other',
  ];
  final List<String> _occupationOptions = [
    'Software Engineer',
    'Doctor',
    'Teacher',
    'Nurse',
    'Business Owner',
    'Accountant',
    'Engineer',
    'Lawyer',
    'Government Employee',
    'Private Employee',
    'Self Employed',
    'Student',
    'Unemployed',
    'Other',
  ];
  final List<String> _incomeRanges = [
    'Below 1 Lakh',
    '1-2 Lakhs',
    '2-3 Lakhs',
    '3-4 Lakhs',
    '4-5 Lakhs',
    '5-7 Lakhs',
    '7-10 Lakhs',
    '10-15 Lakhs',
    '15-20 Lakhs',
    '20-30 Lakhs',
    '30-50 Lakhs',
    'Above 50 Lakhs',
  ];

  @override
  void initState() {
    super.initState();
    _generateHeights();
    _generateWeights();
    _initializeControllers();
  }

  void _generateHeights() {
    for (int cm = 140; cm <= 210; cm++) {
      double feet = cm / 30.48;
      int ft = feet.floor();
      double inches = (feet - ft) * 12;
      String display = '$cm cm - $ft\'${inches.toStringAsFixed(1)}"';
      _heights.add({'value': cm.toString(), 'display': display});
    }
  }

  void _generateWeights() {
    for (int kg = 30; kg <= 200; kg++) {
      _weights.add('$kg kg');
    }
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _selectedGender = null;
    _selectedHeight = null;
    _selectedWeight = null;
    _selectedMaritalStatus = null;
    _selectedReligion = null;
    _casteController = TextEditingController();
    _subCasteController = TextEditingController();
    _selectedMotherTongue = 'Malayalam'; // Default
    _selectedEducation = null;
    _customEducationController = TextEditingController();
    _selectedOccupation = null;
    _customOccupationController = TextEditingController();
    _selectedAnnualIncome = null;
    _cityController = TextEditingController();
    _selectedDistrict = null;
    _stateController = TextEditingController(text: 'Kerala');
    _countryController = TextEditingController(text: 'India');
    _bioController = TextEditingController();
  }

  String _getEducationValue() {
    if (_selectedEducation == 'Other') {
      return _customEducationController.text;
    }
    return _selectedEducation ?? '';
  }

  String _getOccupationValue() {
    if (_selectedOccupation == 'Other') {
      return _customOccupationController.text;
    }
    return _selectedOccupation ?? '';
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProfileService.updateMyProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: DateFormatter.parseDate(_dateOfBirthController.text),
        gender: _selectedGender,
        height: _selectedHeight != null ? int.tryParse(_selectedHeight!) : null,
        weight: _selectedWeight != null
            ? int.tryParse(_selectedWeight!.replaceAll(' kg', ''))
            : null,
        maritalStatus: _selectedMaritalStatus,
        religion: _selectedReligion,
        caste: _casteController.text,
        subCaste: _subCasteController.text,
        motherTongue: _selectedMotherTongue,
        education: _getEducationValue(),
        occupation: _getOccupationValue(),
        annualIncome: _selectedAnnualIncome != null ? double.tryParse(_selectedAnnualIncome!) : null,
        city: _cityController.text,
        district: _selectedDistrict,
        state: _stateController.text,
        country: _countryController.text,
        bio: _bioController.text,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshUser();
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        final data = json.decode(response.body);
        String message = data['error'] ?? 'Failed to create profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _dateOfBirthController.text.isNotEmpty &&
            _selectedGender != null &&
            _selectedMaritalStatus != null;
      case 1:
        return true; // Optional fields
      case 2:
        if (_selectedEducation == 'Other' &&
            _customEducationController.text.isEmpty) {
          return false;
        }
        if (_selectedOccupation == 'Other' &&
            _customOccupationController.text.isEmpty) {
          return false;
        }
        return true;
      case 3:
        return true; // Optional fields
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
        setState(() {
          _currentStep++;
        });
      } else {
        _createProfile();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s start with your basic details',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: 'First Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: 'Last Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dateOfBirthController,
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          readOnly: true,
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(
                const Duration(days: 365 * 25),
              ),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            );
            if (pickedDate != null) {
              setState(() {
                _dateOfBirthController.text = DateFormatter.formatDate(
                  pickedDate,
                );
              });
            }
          },
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: const Icon(Icons.wc),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
          ],
          onChanged: (value) => setState(() => _selectedGender = value),
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedHeight,
          decoration: InputDecoration(
            labelText: 'Height',
            prefixIcon: const Icon(Icons.height),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _heights.map((height) {
            return DropdownMenuItem(
              value: height['value'],
              child: Text(height['display']!),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedHeight = value),
          menuMaxHeight: 300,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedWeight,
          decoration: InputDecoration(
            labelText: 'Weight',
            prefixIcon: const Icon(Icons.monitor_weight_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _weights.map((weight) {
            return DropdownMenuItem(value: weight, child: Text(weight));
          }).toList(),
          onChanged: (value) => setState(() => _selectedWeight = value),
          menuMaxHeight: 300,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedMaritalStatus,
          decoration: InputDecoration(
            labelText: 'Marital Status',
            prefixIcon: const Icon(Icons.favorite_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: const [
            DropdownMenuItem(
              value: 'never_married',
              child: Text('Never Married'),
            ),
            DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
            DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
          ],
          onChanged: (value) => setState(() => _selectedMaritalStatus = value),
          validator: (value) => value == null ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildReligionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Religion & Community',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Share your cultural background',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 30),
        DropdownButtonFormField<String>(
          value: _selectedReligion,
          decoration: InputDecoration(
            labelText: 'Religion',
            prefixIcon: const Icon(Icons.church),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _religions.map((religion) {
            return DropdownMenuItem(value: religion, child: Text(religion));
          }).toList(),
          onChanged: (value) => setState(() => _selectedReligion = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _casteController,
          decoration: InputDecoration(
            labelText: 'Caste',
            prefixIcon: const Icon(Icons.people_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _subCasteController,
          decoration: InputDecoration(
            labelText: 'Sub-Caste',
            prefixIcon: const Icon(Icons.people),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedMotherTongue,
          decoration: InputDecoration(
            labelText: 'Mother Tongue',
            prefixIcon: const Icon(Icons.language),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _motherTongues.map((language) {
            return DropdownMenuItem(value: language, child: Text(language));
          }).toList(),
          onChanged: (value) => setState(() => _selectedMotherTongue = value),
        ),
      ],
    );
  }

  Widget _buildEducationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Education & Career',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your professional background',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 30),
        DropdownButtonFormField<String>(
          value: _selectedEducation,
          decoration: InputDecoration(
            labelText: 'Education',
            prefixIcon: const Icon(Icons.school),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _educationOptions.map((education) {
            return DropdownMenuItem(value: education, child: Text(education));
          }).toList(),
          onChanged: (value) => setState(() => _selectedEducation = value),
        ),
        if (_selectedEducation == 'Other') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customEducationController,
            decoration: InputDecoration(
              labelText: 'Enter Your Education',
              prefixIcon: const Icon(Icons.edit),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedOccupation,
          decoration: InputDecoration(
            labelText: 'Occupation',
            prefixIcon: const Icon(Icons.work_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _occupationOptions.map((occupation) {
            return DropdownMenuItem(value: occupation, child: Text(occupation));
          }).toList(),
          onChanged: (value) => setState(() => _selectedOccupation = value),
          menuMaxHeight: 300,
        ),
        if (_selectedOccupation == 'Other') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customOccupationController,
            decoration: InputDecoration(
              labelText: 'Enter Your Occupation',
              prefixIcon: const Icon(Icons.edit),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedAnnualIncome,
          decoration: InputDecoration(
            labelText: 'Annual Income',
            prefixIcon: const Icon(Icons.currency_rupee),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _incomeRanges.map((income) {
            return DropdownMenuItem(value: income, child: Text(income));
          }).toList(),
          onChanged: (value) => setState(() => _selectedAnnualIncome = value),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location & About',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Final details to complete your profile',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: 'City',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedDistrict,
          decoration: InputDecoration(
            labelText: 'District',
            prefixIcon: const Icon(Icons.map),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _keralaDistricts.map((district) {
            return DropdownMenuItem(value: district, child: Text(district));
          }).toList(),
          onChanged: (value) => setState(() => _selectedDistrict = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _stateController,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'State',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _countryController,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Country',
            prefixIcon: const Icon(Icons.public),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'About Me',
            hintText: 'Tell us something about yourself...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.edit_note),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildReligionStep();
      case 2:
        return _buildEducationStep();
      case 3:
        return _buildLocationStep();
      default:
        return _buildPersonalInfoStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.primary,
        title: const Text('Create Profile'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStepIndicator(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStep(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == 3
                                  ? 'Complete Profile'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _casteController.dispose();
    _subCasteController.dispose();
    _customEducationController.dispose();
    _customOccupationController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}

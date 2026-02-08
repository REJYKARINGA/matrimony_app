import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/profile_service.dart';

class FamilyDetailsScreen extends StatefulWidget {
  const FamilyDetailsScreen({Key? key}) : super(key: key);

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fatherNameController;
  late TextEditingController _fatherOccupationController;
  late TextEditingController _motherNameController;
  late TextEditingController _motherOccupationController;
  late TextEditingController _siblingsController;
  late String? _familyType;
  late String? _familyStatus;
  late TextEditingController _familyLocationController;
  late TextEditingController _elderSisterController;
  late TextEditingController _elderBrotherController;
  late TextEditingController _youngerSisterController;
  late TextEditingController _youngerBrotherController;
  late bool? _fatherAlive;
  late bool? _motherAlive;
  late bool? _isDisabled;
  late TextEditingController _guardianController;
  late bool? _show;

  bool _isLoading = false;
  bool _isDataLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFamilyDetails();
  }

  Future<void> _loadFamilyDetails() async {
    setState(() {
      _isDataLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ProfileService.getFamilyDetails();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final familyDetails = data['family_details'];

        if (familyDetails != null) {
          _initializeControllersWithData(familyDetails);
        } else {
          _initializeEmptyControllers();
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load family details';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading family details: $e';
      });
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
  }

  void _initializeEmptyControllers() {
    _fatherNameController = TextEditingController(text: '');
    _fatherOccupationController = TextEditingController(text: '');
    _motherNameController = TextEditingController(text: '');
    _motherOccupationController = TextEditingController(text: '');
    _siblingsController = TextEditingController(text: '');
    _familyType = null;
    _familyStatus = null;
    _familyLocationController = TextEditingController(text: '');
    _elderSisterController = TextEditingController(text: '');
    _elderBrotherController = TextEditingController(text: '');
    _youngerSisterController = TextEditingController(text: '');
    _youngerBrotherController = TextEditingController(text: '');
    _fatherAlive = true;
    _motherAlive = true;
    _isDisabled = false;
    _guardianController = TextEditingController(text: '');
    _show = null;
  }

  void _initializeControllersWithData(Map<String, dynamic> familyDetails) {
    _fatherNameController = TextEditingController(
      text: familyDetails['father_name'] ?? '',
    );
    _fatherOccupationController = TextEditingController(
      text: familyDetails['father_occupation'] ?? '',
    );
    _motherNameController = TextEditingController(
      text: familyDetails['mother_name'] ?? '',
    );
    _motherOccupationController = TextEditingController(
      text: familyDetails['mother_occupation'] ?? '',
    );
    _siblingsController = TextEditingController(
      text: familyDetails['siblings']?.toString() ?? '',
    );
    _familyType = familyDetails['family_type'];
    _familyStatus = familyDetails['family_status'];
    _familyLocationController = TextEditingController(
      text: familyDetails['family_location'] ?? '',
    );
    _elderSisterController = TextEditingController(
      text: familyDetails['elder_sister']?.toString() ?? '',
    );
    _elderBrotherController = TextEditingController(
      text: familyDetails['elder_brother']?.toString() ?? '',
    );
    _youngerSisterController = TextEditingController(
      text: familyDetails['younger_sister']?.toString() ?? '',
    );
    _youngerBrotherController = TextEditingController(
      text: familyDetails['younger_brother']?.toString() ?? '',
    );
    _fatherAlive = familyDetails['father_alive'] ?? true;
    _motherAlive = familyDetails['mother_alive'] ?? true;
    _isDisabled = familyDetails['is_disabled'] ?? false;
    _guardianController = TextEditingController(
      text: familyDetails['guardian'] ?? '',
    );
    _show = familyDetails['show'];
  }

  Future<void> _saveFamilyDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProfileService.updateFamilyDetails(
        fatherName: _fatherNameController.text,
        fatherOccupation: _fatherOccupationController.text,
        motherName: _motherNameController.text,
        motherOccupation: _motherOccupationController.text,
        siblings: int.tryParse(_siblingsController.text),
        familyType: _familyType,
        familyStatus: _familyStatus,
        familyLocation: _familyLocationController.text,
        elderSister: int.tryParse(_elderSisterController.text),
        elderBrother: int.tryParse(_elderBrotherController.text),
        youngerSister: int.tryParse(_youngerSisterController.text),
        youngerBrother: int.tryParse(_youngerBrotherController.text),
        fatherAlive: _fatherAlive,
        motherAlive: _motherAlive,
        isDisabled: _isDisabled,
        guardian: _guardianController.text,
        show: _show,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final data = json.decode(response.body);
        String message = data['error'] ?? 'Failed to update family details';
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
    if (_isDataLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Family Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF00BCD4)),
              SizedBox(height: 16),
              Text(
                'Loading family details...',
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Family Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadFamilyDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
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
      appBar: AppBar(
        title: const Text('Family Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveFamilyDetails,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00BCD4),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Form content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Father's Information
                        _buildSectionTitle(Icons.man, 'Father\'s Information'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _fatherNameController,
                          label: 'Father\'s Name',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter father\'s name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _fatherOccupationController,
                          label: 'Father\'s Occupation',
                          icon: Icons.work,
                        ),

                        const SizedBox(height: 24),

                        // Mother's Information
                        _buildSectionTitle(
                          Icons.woman,
                          'Mother\'s Information',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _motherNameController,
                          label: 'Mother\'s Name',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter mother\'s name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _motherOccupationController,
                          label: 'Mother\'s Occupation',
                          icon: Icons.work,
                        ),

                        const SizedBox(height: 24),

                        // Family Information
                        _buildSectionTitle(Icons.home, 'Family Information'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _siblingsController,
                          label: 'Number of Siblings',
                          icon: Icons.people,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final numValue = int.tryParse(value);
                              if (numValue == null) {
                                return 'Please enter a valid number';
                              }
                              if (numValue < 0) {
                                return 'Number of siblings cannot be negative';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          value: _familyType,
                          label: 'Family Type',
                          icon: Icons.home_outlined,
                          items: const [
                            DropdownMenuItem(
                              value: 'joint',
                              child: Text('Joint Family'),
                            ),
                            DropdownMenuItem(
                              value: 'nuclear',
                              child: Text('Nuclear Family'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _familyType = value),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          value: _familyStatus,
                          label: 'Family Status',
                          icon: Icons.star,
                          items: const [
                            DropdownMenuItem(
                              value: 'middle_class',
                              child: Text('Middle Class'),
                            ),
                            DropdownMenuItem(
                              value: 'upper_middle_class',
                              child: Text('Upper Middle Class'),
                            ),
                            DropdownMenuItem(
                              value: 'rich',
                              child: Text('Rich'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _familyStatus = value),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _familyLocationController,
                          label: 'Family Location',
                          icon: Icons.location_on,
                        ),

                        const SizedBox(height: 24),

                        // Sibling Information
                        _buildSectionTitle(Icons.groups, 'Sibling Information'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _elderSisterController,
                                label: 'Elder Sisters',
                                icon: Icons.person,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final numValue = int.tryParse(value);
                                    if (numValue == null || numValue < 0) {
                                      return 'Valid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _elderBrotherController,
                                label: 'Elder Brothers',
                                icon: Icons.person,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final numValue = int.tryParse(value);
                                    if (numValue == null || numValue < 0) {
                                      return 'Valid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _youngerSisterController,
                                label: 'Younger Sisters',
                                icon: Icons.person,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final numValue = int.tryParse(value);
                                    if (numValue == null || numValue < 0) {
                                      return 'Valid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _youngerBrotherController,
                                label: 'Younger Brothers',
                                icon: Icons.person,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final numValue = int.tryParse(value);
                                    if (numValue == null || numValue < 0) {
                                      return 'Valid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Additional Information
                        _buildSectionTitle(
                          Icons.info,
                          'Additional Information',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBoolDropdown(
                                value: _fatherAlive,
                                label: 'Father Alive',
                                onChanged: (value) =>
                                    setState(() => _fatherAlive = value),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBoolDropdown(
                                value: _motherAlive,
                                label: 'Mother Alive',
                                onChanged: (value) =>
                                    setState(() => _motherAlive = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBoolDropdown(
                          value: _isDisabled,
                          label: 'Is Disabled',
                          onChanged: (value) => setState(() => _isDisabled = value),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _guardianController,
                          label: 'Guardian',
                          icon: Icons.supervisor_account,
                        ),
                        const SizedBox(height: 12),
                        _buildBoolDropdown(
                          value: _show,
                          label: 'Show Details',
                          onChanged: (value) => setState(() => _show = value),
                        ),

                        const SizedBox(height: 30),

                        // Save Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00BCD4), Color(0xFF0D47A1)], // Turquoise to Deep Blue
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF00BCD4).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveFamilyDetails,
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
                                    'Update Family Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF00BCD4).withOpacity(0.1), // Turquoise
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Color(0xFF00BCD4)), // Turquoise
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF00BCD4)), // Turquoise
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF00BCD4), width: 2), // Turquoise
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF00BCD4)), // Turquoise
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF00BCD4), width: 2), // Turquoise
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildBoolDropdown({
    required bool? value,
    required String label,
    required void Function(bool?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF00BCD4), width: 2), // Turquoise
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          isExpanded: true,
          value: value,
          onChanged: onChanged,
          items: const [
            DropdownMenuItem(value: true, child: Text('Yes')),
            DropdownMenuItem(value: false, child: Text('No')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fatherNameController.dispose();
    _fatherOccupationController.dispose();
    _motherNameController.dispose();
    _motherOccupationController.dispose();
    _siblingsController.dispose();
    _familyLocationController.dispose();
    _elderSisterController.dispose();
    _elderBrotherController.dispose();
    _youngerSisterController.dispose();
    _youngerBrotherController.dispose();
    _guardianController.dispose();
    super.dispose();
  }
}
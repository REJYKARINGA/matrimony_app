import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isUsingEmail = true;
  String? _phoneSessionId;
  String? _verifiedEmail;

  int _currentStep = 0; // 0: Enter email, 1: Enter OTP, 2: Reset password
  bool _isLoading = false;
  String? _errorMessage;

  // Password visibility toggles
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
          ),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background subtle design
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/splash_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.mutedText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Step indicator
                  Row(
                    children: [
                      _buildStepIndicator(0, _isUsingEmail ? 'Email' : 'Phone'),
                      _buildStepLine(),
                      _buildStepIndicator(1, 'OTP'),
                      _buildStepLine(),
                      _buildStepIndicator(2, 'Password'),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Content based on current step
                  _buildStepContent(authProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    switch (_currentStep) {
      case 0:
        return _isUsingEmail 
            ? 'Enter your email address to receive a verification code'
            : 'Enter your phone number to receive a verification code';
      case 1:
        return _isUsingEmail 
            ? 'Enter the OTP sent to your email'
            : 'Enter the OTP sent to your phone';
      case 2:
        return 'Create your new password';
      default:
        return '';
    }
  }

  Widget _buildStepIndicator(int index, String label) {
    bool isActive = index <= _currentStep;
    bool isCompleted = index < _currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.deepEmerald : Colors.white,
              border: Border.all(
                color: isActive ? AppColors.deepEmerald : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: AppColors.deepEmerald.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.black87 : Colors.grey.shade500,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return _buildStepLineInternal(0);
  }

  Widget _buildStepLineInternal(int index) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: _currentStep > index ? AppColors.deepEmerald : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStepContent(AuthProvider authProvider) {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep(authProvider);
      case 1:
        return _buildOtpStep(authProvider);
      case 2:
        return _buildPasswordStep(authProvider);
      default:
        return Container();
    }
  }

  Widget _buildEmailStep(AuthProvider authProvider) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Email'),
                selected: _isUsingEmail,
                onSelected: (val) {
                  if (val) setState(() => _isUsingEmail = true);
                },
                selectedColor: AppColors.deepEmerald.withOpacity(0.1),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _isUsingEmail ? AppColors.deepEmerald : Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: _isUsingEmail ? AppColors.deepEmerald.withOpacity(0.2) : Colors.grey.shade200),
                ),
                showCheckmark: true,
                checkmarkColor: AppColors.deepEmerald,
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Phone Number'),
                selected: !_isUsingEmail,
                onSelected: (val) {
                  if (val) setState(() => _isUsingEmail = false);
                },
                selectedColor: AppColors.deepEmerald.withOpacity(0.1),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: !_isUsingEmail ? AppColors.deepEmerald : Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: !_isUsingEmail ? AppColors.deepEmerald.withOpacity(0.2) : Colors.grey.shade200),
                ),
                showCheckmark: true,
                checkmarkColor: AppColors.deepEmerald,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isUsingEmail
              ? TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your registered email',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.deepEmerald),
                    filled: true,
                    fillColor: AppColors.deepEmerald.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.deepEmerald.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.deepEmerald, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                )
              : TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your registered phone',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.deepEmerald),
                    filled: true,
                    fillColor: AppColors.deepEmerald.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.deepEmerald.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.deepEmerald, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
          const SizedBox(height: 30),
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryCyan, AppColors.primaryBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_emailFormKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });

                        try {
                          if (_isUsingEmail) {
                            bool success = await authProvider.sendOtp(
                              email: _emailController.text.trim(),
                            );
                            if (success) {
                              setState(() {
                                _currentStep = 1;
                                _isLoading = false;
                              });
                            } else {
                              setState(() {
                                _errorMessage = authProvider.errorMessage ?? 'Failed to send OTP';
                                _isLoading = false;
                              });
                            }
                          } else {
                            String? sessionId = await authProvider.sendPhoneOtpForReset(
                              phone: _phoneController.text.trim(),
                            );
                            if (sessionId != null) {
                              setState(() {
                                _phoneSessionId = sessionId;
                                _currentStep = 1;
                                _isLoading = false;
                              });
                            } else {
                              setState(() {
                                _errorMessage = authProvider.errorMessage ?? 'Failed to send OTP';
                                _isLoading = false;
                              });
                            }
                          }
                        } catch (e) {
                          setState(() {
                            _errorMessage = 'An error occurred: ${e.toString()}';
                            _isLoading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.cardDark,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const Text(
                      'Sending OTP...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(AuthProvider authProvider) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Verification Code',
              hintText: 'Enter 6-digit OTP',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.lock_outlined, color: AppColors.deepEmerald),
              filled: true,
              fillColor: AppColors.deepEmerald.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.deepEmerald.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.deepEmerald, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the OTP';
              }
              if (value.length != 6) {
                return 'OTP must be 6 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Text(
            'OTP sent to ${_isUsingEmail ? _emailController.text : _phoneController.text}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryCyan, AppColors.primaryBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_otpFormKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });

                        try {
                          if (_isUsingEmail) {
                            bool success = await authProvider.verifyOtp(
                              email: _emailController.text.trim(),
                              otp: _otpController.text.trim(),
                            );
                            if (success) {
                              setState(() {
                                _currentStep = 2;
                                _isLoading = false;
                              });
                            } else {
                              setState(() {
                                _errorMessage = authProvider.errorMessage ?? 'Invalid OTP';
                                _isLoading = false;
                              });
                            }
                          } else {
                            if (_phoneSessionId == null) {
                                setState(() {
                                  _errorMessage = 'Session expired. Please request OTP again.';
                                  _isLoading = false;
                                });
                                return;
                            }
                            String? resolvedEmail = await authProvider.verifyPhoneOtpForReset(
                              phone: _phoneController.text.trim(),
                              otp: _otpController.text.trim(),
                              sessionId: _phoneSessionId!,
                            );
                            if (resolvedEmail != null) {
                              setState(() {
                                _verifiedEmail = resolvedEmail;
                                _currentStep = 2;
                                _isLoading = false;
                              });
                            } else {
                              setState(() {
                                _errorMessage = authProvider.errorMessage ?? 'Invalid OTP';
                                _isLoading = false;
                              });
                            }
                          }
                        } catch (e) {
                          setState(() {
                            _errorMessage = 'An error occurred: ${e.toString()}';
                            _isLoading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.cardDark,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const Text(
                      'Verifying OTP...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });

                      try {
                        if (_isUsingEmail) {
                          bool success = await authProvider.sendOtp(
                            email: _emailController.text.trim(),
                          );
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New OTP sent successfully'), backgroundColor: Colors.green),
                            );
                            setState(() => _isLoading = false);
                          } else {
                            setState(() {
                              _errorMessage = authProvider.errorMessage ?? 'Failed to resend OTP';
                              _isLoading = false;
                            });
                          }
                        } else {
                          String? sessionId = await authProvider.sendPhoneOtpForReset(
                            phone: _phoneController.text.trim(),
                          );
                          if (sessionId != null) {
                            setState(() {
                              _phoneSessionId = sessionId;
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New OTP sent successfully'), backgroundColor: Colors.green),
                            );
                          } else {
                            setState(() {
                              _errorMessage = authProvider.errorMessage ?? 'Failed to resend OTP';
                              _isLoading = false;
                            });
                          }
                        }
                      } catch (e) {
                        setState(() {
                          _errorMessage = 'An error occurred: ${e.toString()}';
                          _isLoading = false;
                        });
                      }
                    },
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  color: AppColors.deepEmerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(AuthProvider authProvider) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter your new password',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.deepEmerald),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.deepEmerald.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.deepEmerald.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.deepEmerald, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter new password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your new password',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.deepEmerald),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.deepEmerald.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.deepEmerald.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.deepEmerald, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryCyan, AppColors.primaryBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryCyan.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_passwordFormKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });

                        try {
                          // verifiedEmail is captured in step 1 if using Phone
                          String resetEmail = _isUsingEmail 
                              ? _emailController.text.trim() 
                              : (_verifiedEmail ?? '');

                          if (resetEmail.isEmpty) {
                            setState(() {
                              _errorMessage = 'Error: Cannot resolve email account associated with this phone structure. Please try again or use Email.';
                              _isLoading = false;
                            });
                            return;
                          }

                          bool success = await authProvider.resetPassword(
                            email: resetEmail,
                            newPassword: _newPasswordController.text,
                          );

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset successful!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            await Future.delayed(const Duration(milliseconds: 1500));

                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          } else {
                            setState(() {
                              _errorMessage =
                                  authProvider.errorMessage ??
                                  'Failed to reset password';
                              _isLoading = false;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _errorMessage = 'An error occurred: ${e.toString()}';
                            _isLoading = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.cardDark,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const Text(
                      'Resetting Password...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}















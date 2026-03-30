// ─────────────────────────────────────────────────────────────────────
//  screens/auth/registration_flow_screen.dart
// ─────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class RegistrationFlowScreen extends StatefulWidget {
  const RegistrationFlowScreen({super.key});

  @override
  State<RegistrationFlowScreen> createState() => _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState extends State<RegistrationFlowScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _confirmCtrl;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  
  // Document storage for registration
  List<UploadedDocument> _documents = [];
  
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _isLoading = false;
  
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _firstCtrl, _lastCtrl, _usernameCtrl, _emailCtrl,
      _phoneCtrl, _companyCtrl, _passCtrl, _confirmCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitRegistration() async {
    // Check policy agreements first
    if (!_agreeTerms || !_agreePrivacy) {
      setState(() => _error = 'Please agree to all policies to continue.');
      return;
    }

    // Clear any previous errors
    setState(() => _error = null);

    // Validate only current step fields
    bool isValid = true;
    String errorMessage = '';

    // Always validate basic info fields
    if (_firstCtrl.text.isEmpty) {
      isValid = false;
      errorMessage = 'First name is required';
    } else if (_lastCtrl.text.isEmpty) {
      isValid = false;
      errorMessage = 'Last name is required';
    } else if (_emailCtrl.text.isEmpty) {
      isValid = false;
      errorMessage = 'Email is required';
    } else if (!_emailCtrl.text.contains('@')) {
      isValid = false;
      errorMessage = 'Please enter a valid email address';
    } else if (_usernameCtrl.text.isEmpty) {
      isValid = false;
      errorMessage = 'Username is required';
    } else if (_phoneCtrl.text.isEmpty) {
      isValid = false;
      errorMessage = 'Phone number is required';
    } else if (_companyCtrl.text.isEmpty) {
      isValid = false;
      errorMessage = 'Company name is required';
    } else if (_passCtrl.text.length < 6) {
      isValid = false;
      errorMessage = 'Password must be at least 6 characters';
    } else if (_passCtrl.text != _confirmCtrl.text) {
      isValid = false;
      errorMessage = 'Passwords do not match';
    }

    if (!isValid) {
      setState(() => _error = errorMessage);
      return;
    }

    final auth = context.read<AuthService>();
    final err = await auth.register(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      username: _usernameCtrl.text,
      firstName: _firstCtrl.text,
      lastName: _lastCtrl.text,
      phone: _phoneCtrl.text,
      companyName: _companyCtrl.text,
    );

    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      // Registration successful - go to dashboard
      context.go('/dashboard');
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        
        return Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).colorScheme.primary
                : isCompleted 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                    : Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isActive 
                    ? Theme.of(context).colorScheme.onPrimary
                    : isCompleted 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Personal Information',
          subtitle: 'Please fill in your details to create an account.',
        ),
        const SizedBox(height: 28),
        
        // Form fields
        AppTextField(
          controller: _firstCtrl,
          label: 'First Name',
          hintText: 'Enter your first name',
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _lastCtrl,
          label: 'Last Name',
          hintText: 'Enter your last name',
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _usernameCtrl,
          label: 'Username',
          hintText: 'Choose a username',
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _emailCtrl,
          label: 'Email',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (!v!.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _phoneCtrl,
          label: 'Phone',
          hintText: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _companyCtrl,
          label: 'Company Name',
          hintText: 'Enter your company name',
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _passCtrl,
          label: 'Password',
          hintText: 'Create a password',
          obscureText: _obscurePass,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (v!.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _confirmCtrl,
          label: 'Confirm Password',
          hintText: 'Confirm your password',
          obscureText: _obscureConfirm,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (v != _passCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Upload Documents',
          subtitle: 'Please upload the required documents for verification.',
        ),
        const SizedBox(height: 28),
        
        // Document upload areas
        _DocumentUploadCard(
          title: 'Company Profile',
          description: 'Company registration document',
          icon: Icons.business,
          onUpload: (doc) {
            setState(() {
              _documents.add(doc);
            });
          },
        ),
        const SizedBox(height: 16),
        
        _DocumentUploadCard(
          title: 'Certificate of Incorporation',
          description: 'Official company registration certificate',
          icon: Icons.description,
          onUpload: (doc) {
            setState(() {
              _documents.add(doc);
            });
          },
        ),
        const SizedBox(height: 16),
        
        _DocumentUploadCard(
          title: 'Articles of Association',
          description: 'Company articles of association',
          icon: Icons.article,
          onUpload: (doc) {
            setState(() {
              _documents.add(doc);
            });
          },
        ),
        const SizedBox(height: 16),
        
        _DocumentUploadCard(
          title: 'CR6 Document',
          description: 'Company tax clearance certificate',
          icon: Icons.assignment,
          onUpload: (doc) {
            setState(() {
              _documents.add(doc);
            });
          },
        ),
        const SizedBox(height: 16),
        
        _DocumentUploadCard(
          title: 'CR14 Document',
          description: 'Tax compliance certificate',
          icon: Icons.receipt,
          onUpload: (doc) {
            setState(() {
              _documents.add(doc);
            });
          },
        ),
        const SizedBox(height: 16),
        
        _DocumentUploadCard(
          title: 'Tax Clearance Certificate',
          description: 'Recent tax clearance certificate',
          icon: Icons.account_balance,
          onUpload: (doc) {
            setState(() {
              _documents.add(doc);
            });
          },
        ),
        const SizedBox(height: 16),
        
        _DocumentUploadCard(
          title: 'Financial Statements',
          description: 'Recent financial statements',
          icon: Icons.attach_money,
          onUpload: (doc) {
            setState(() {
              _documents.add(doc);
            });
          },
        ),
        const SizedBox(height: 16),
        
        _DocumentUploadCard(
          title: 'Banking Details',
          description: 'Company bank account information',
          icon: Icons.account_balance_wallet,
          onUpload: (doc) {
            setState(() {
              _documents.add(doc);
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Terms and Policies',
          subtitle: 'Please review and accept the terms and policies.',
        ),
        const SizedBox(height: 28),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms and Conditions',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By creating an account, you agree to our terms of service and understand the policies governing the use of our platform.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              CheckboxListTile(
                value: _agreeTerms,
                onChanged: (value) => setState(() => _agreeTerms = value ?? false),
                activeColor: Theme.of(context).colorScheme.primary,
                title: Text(
                  'I agree to the Terms and Conditions',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              CheckboxListTile(
                value: _agreePrivacy,
                onChanged: (value) => setState(() => _agreePrivacy = value ?? false),
                activeColor: Theme.of(context).colorScheme.primary,
                title: Text(
                  'I agree to the Privacy Policy',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: _currentStep > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        title: const StfLogo(size: 32),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 0 : 24, vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step indicator
                    _buildStepIndicator(),
                    const SizedBox(height: 32),
                    
                    // Error banner
                    if (_error != null)
                      ErrorBanner(
                        message: _error!,
                        onDismiss: () => setState(() => _error = null),
                      ),
                    
                    // Step content
                    _buildStepContent(),
                    const SizedBox(height: 32),
                    
                    // Navigation buttons
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousStep,
                              child: Text('Previous'),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 16),
                        if (_currentStep < 2)
                          Expanded(
                            child: GoldButton(
                              label: 'Next',
                              onPressed: () {
                                if (_currentStep == 0) {
                                  if (_formKey.currentState!.validate()) {
                                    _nextStep();
                                  }
                                } else if (_currentStep == 1) {
                                  _nextStep();
                                }
                              },
                            ),
                          ),
                        if (_currentStep == 2)
                          Expanded(
                            child: GoldButton(
                              label: 'Create Account',
                              onPressed: _submitRegistration,
                              isLoading: auth.isLoading,
                            ),
                          ),
                        if (_currentStep == 2)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showUploadedDocuments(context),
                              child: Text('View Uploaded Documents'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Function to show uploaded documents
void _showUploadedDocuments(BuildContext context) {
  if (_documents.isNotEmpty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Uploaded Documents'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _documents.map((doc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${doc.name} (${doc.type})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Document Upload Card Widget
class _DocumentUploadCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Function(UploadedDocument) onUpload;

  const _DocumentUploadCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'doc', 'docx'],
                );
                
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  final fileName = file.name;
                  final ext = file.extension?.toLowerCase();
                  
                  onUpload(UploadedDocument(
                    name: fileName,
                    type: ext ?? 'Unknown',
                    url: 'placeholder', // Replace with Firebase URL later
                    uploadedAt: DateTime.now(),
                  ));
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$fileName uploaded successfully!')),
                  );
                }
              },
              child: Text('Upload Document'),
            ),
          ),
        ],
      ),
    );
  }
}

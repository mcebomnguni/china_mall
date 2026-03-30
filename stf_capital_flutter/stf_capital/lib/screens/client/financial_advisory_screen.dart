// ─────────────────────────────────────────────────────────────────────
//  screens/client/financial_advisory_screen.dart
// ─────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../services/application_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class FinancialAdvisoryScreen extends StatefulWidget {
  const FinancialAdvisoryScreen({super.key});

  @override
  State<FinancialAdvisoryScreen> createState() => _FinancialAdvisoryScreenState();
}

class _FinancialAdvisoryScreenState extends State<FinancialAdvisoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionCtrl;
  List<UploadedDocument> _documents = [];
  bool _showPreview = false;
  bool _isSubmitting = false;
  String? _error;
  
  // Firebase Storage upload function
  Future<String> _uploadFileToStorage(PlatformFile file) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('documents/${file.name}');
      final uploadTask = storageRef.putData(file.bytes!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return 'placeholder'; // Fallback to placeholder
    }
  }
  List<String> _selectedProducts = [];
  
  // Financial Advisory Products
  final List<String> _financialProducts = [
    'Capital Raise',
    'Consultancy Services',
    'Order Financing',
    'Risk Participation Structured Finances',
    'Debt Restructuring',
  ];

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isWide = MediaQuery.of(context).size.width > 700;

    if (!_showPreview) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          leading: BackButton(onPressed: () => context.pop()),
          title: const StfLogo(size: 32),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 0 : 24, vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: 'Financial Advisory Services',
                      subtitle: 'Select products and upload your contract.',
                    ),
                    const SizedBox(height: 28),

                    // Error banner
                    if (_error != null)
                      ErrorBanner(
                        message: _error!,
                        onDismiss: () => setState(() => _error = null),
                      ),
                    
                    // Product Selection
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Products',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._financialProducts.map((product) {
                            return CheckboxListTile(
                              value: _selectedProducts.contains(product),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedProducts.add(product);
                                  } else {
                                    _selectedProducts.remove(product);
                                  }
                                });
                              },
                              title: Text(
                                product,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _DocumentUploadCard(
                      title: 'Contract Upload',
                      description: 'Upload your contract for financial advisory services',
                      icon: Icons.description,
                      onUpload: (document) {
                        setState(() {
                          _documents.add(document);
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Description
                    AppTextField(
                      controller: _descriptionCtrl,
                      label: 'Additional Information',
                      hintText: 'Provide details about the financial advisory services you require...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showPreviewApplication,
                            child: Text('Preview Application'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GoldButton(
                            label: 'Submit Application',
                            onPressed: _submitApplication,
                            isLoading: _isSubmitting,
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
      );
    }

    // Preview Screen
    return _buildPreviewScreen();
  }

  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showPreview = false),
        ),
        title: Text(
          'Application Preview',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'Application Review',
                    subtitle: 'Please review your application before submitting.',
                  ),
                  const SizedBox(height: 28),

                  // Application Details
                  _PreviewSection(
                    title: 'Application Details',
                    children: [
                      _PreviewRow('Service Type', 'Financial Advisory'),
                      _PreviewRow('Client Name', '${context.read<AuthService>().currentUser?.firstName} ${context.read<AuthService>().currentUser?.lastName}'),
                      _PreviewRow('Company', context.read<AuthService>().currentUser?.companyName ?? ''),
                      _PreviewRow('Email', context.read<AuthService>().currentUser?.email ?? ''),
                      _PreviewRow('Phone', context.read<AuthService>().currentUser?.phone ?? ''),
                      _PreviewRow('Description', _descriptionCtrl.text),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Uploaded Documents
                  _PreviewSection(
                    title: 'Uploaded Documents',
                    children: [
                      ..._documents.map((doc) => _PreviewRow(doc.name, doc.type)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _showPreview = false),
                          child: Text('Edit Application'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GoldButton(
                          label: 'Submit Application',
                          onPressed: _submitApplication,
                          isLoading: _isSubmitting,
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
    );
  }

  void _showPreviewApplication() {
    if (_documents.isEmpty) {
      setState(() => _error = 'Please upload your contract');
      return;
    }
    setState(() => _showPreview = true);
  }

  Future<void> _submitApplication() async {
    if (_documents.isEmpty) {
      setState(() => _error = 'Please upload your contract');
      return;
    }

    setState(() => _isSubmitting = true);
    _error = null;

    try {
      // Create application
      final application = ServiceApplication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientUid: context.read<AuthService>().currentUser?.uid ?? '',
        clientName: '${context.read<AuthService>().currentUser?.firstName} ${context.read<AuthService>().currentUser?.lastName}',
        clientEmail: context.read<AuthService>().currentUser?.email ?? '',
        companyName: context.read<AuthService>().currentUser?.companyName ?? '',
        productCategoryId: 'Financial Advisory',
        productCategoryName: 'Financial Advisory',
        selectedProductId: 'Financial Advisory Services',
        selectedProductName: 'Financial Advisory Services',
        documents: _documents,
        status: ApplicationStatus.pendingReview,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Submit to Firestore
      await context.read<ApplicationService>().createApplication(application);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: AppTheme.goldLight,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error submitting application: $e';
          _isSubmitting = false;
        });
      }
    }
  }
}

// Helper widgets (reuse from insurance bonds screen)
class _PreviewSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PreviewSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                  final ext = file.extension?.toUpperCase();
                  final type = ext ?? 'Unknown';
                  
                  // Upload to Firebase Storage
                  final downloadUrl = await _uploadFileToStorage(file);
                  
                  onUpload(UploadedDocument(
                    name: fileName,
                    type: type,
                    url: downloadUrl,
                    uploadedAt: DateTime.now(),
                  ));
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

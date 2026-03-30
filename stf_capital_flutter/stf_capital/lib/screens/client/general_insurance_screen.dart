// ─────────────────────────────────────────────────────────────────────
//  screens/client/general_insurance_screen.dart
// ─────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../services/application_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class GeneralInsuranceScreen extends StatefulWidget {
  const GeneralInsuranceScreen({super.key});

  @override
  State<GeneralInsuranceScreen> createState() => _GeneralInsuranceScreenState();
}

class _GeneralInsuranceScreenState extends State<GeneralInsuranceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionCtrl;
  List<String> _selectedProducts = [];
  String? _selectedCompany;
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

  // General Insurance Products
  final List<String> _insuranceProducts = [
    'Contractor All Risk (CAR) Insurance',
    'Erections All Risk Insurance',
    'Goods In Transit',
    'Public Liability Insurance',
    'Fire Damage Insurance',
    'Motor Insurance - Third Party Only',
    'Motor Insurance - Third Party Fire and Theft',
    'Motor Insurance - Comprehensive',
    'Agriculture Insurance',
    'Travel Insurance',
    'Export Credit Insurance',
    'Domestic Payments Insurance Policy (DPIP)',
    'Marine Insurance',
  ];

  // Insurance Companies
  final List<String> _insuranceCompanies = [
    'ECGC Limited — Export Credit Guarantee Corporation',
    'Credsure Insurance — Credsure Insurance',
    'CBZ Insurance — CBZ Insurance',
    'Alliance Insurance Zimbabwe — Alliance Insurance',
    'FBC Insurance — FBC Insurance',
    'Old Mutual — Old Mutual',
    'Zimnat Insurance — Zimnat Insurance',
    'Sanctuary Insurance — Sanctuary Insurance',
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
                      title: 'General Insurance Products',
                      subtitle: 'Select insurance products you want to cover.',
                    ),
                    const SizedBox(height: 28),

                    // Error banner
                    if (_error != null)
                      ErrorBanner(
                        message: _error!,
                        onDismiss: () => setState(() => _error = null),
                      ),
                    
                    // Products Selection
                    _buildProductsSelection(),
                    const SizedBox(height: 28),

                    // Company Selection
                    _buildCompanySelection(),
                    const SizedBox(height: 28),

                    // Document Upload
                    _buildDocumentUpload(),
                    const SizedBox(height: 28),

                    // Description
                    AppTextField(
                      controller: _descriptionCtrl,
                      label: 'Coverage Details',
                      hintText: 'Describe what needs to be covered or insured...',
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

  Widget _buildProductsSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Products (Multi-select allowed)',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          ..._insuranceProducts.map((product) => CheckboxListTile(
            title: Text(
              product,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
            activeColor: Theme.of(context).colorScheme.primary,
          )),
        ],
      ),
    );
  }

  Widget _buildCompanySelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Insurance Company',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          ..._insuranceCompanies.map((company) => RadioListTile<String>(
            title: Text(
              company,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            value: company,
            groupValue: _selectedCompany,
            onChanged: (value) {
              setState(() => _selectedCompany = value);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          )),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Documents',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          _DocumentUploadCard(
            title: 'Contract or Asset Details',
            description: 'Upload contract or asset details to be insured',
            icon: Icons.description,
            onUpload: (document) {
              setState(() {
                _documents.add(document);
              });
            },
          ),
        ],
      ),
    );
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
                      _PreviewRow('Service Type', 'General Insurance'),
                      _PreviewRow('Products', _selectedProducts.join(', ')),
                      _PreviewRow('Insurance Company', _selectedCompany ?? ''),
                      _PreviewRow('Client Name', '${context.read<AuthService>().currentUser?.firstName} ${context.read<AuthService>().currentUser?.lastName}'),
                      _PreviewRow('Company', context.read<AuthService>().currentUser?.companyName ?? ''),
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
    if (_selectedProducts.isEmpty) {
      setState(() => _error = 'Please select at least one product');
      return;
    }
    if (_selectedCompany == null) {
      setState(() => _error = 'Please select an insurance company');
      return;
    }
    if (_documents.isEmpty) {
      setState(() => _error = 'Please upload contract or asset details');
      return;
    }
    setState(() => _showPreview = true);
  }

  Future<void> _submitApplication() async {
    if (_selectedProducts.isEmpty || _selectedCompany == null || _documents.isEmpty) {
      _showPreviewApplication();
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
        productCategoryId: 'General Insurance',
        productCategoryName: 'General Insurance',
        selectedProductId: _selectedProducts.join(', '),
        selectedProductName: _selectedProducts.join(', '),
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
        _showMeetingDialog();
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

  void _showMeetingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Application Submitted!',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your application has been submitted successfully!',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Would you like to schedule a meeting with our team?',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('No, thank you'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMeetingScheduler();
            },
            child: Text('Schedule Meeting'),
          ),
        ],
      ),
    );
  }

  void _showMeetingScheduler() {
    showDialog(
      context: context,
      builder: (context) => _MeetingSchedulerDialog(
        onScheduled: (dateTime) {
          _bookMeeting(dateTime);
        },
      ),
    );
  }

  Future<void> _bookMeeting(DateTime dateTime) async {
    try {
      // Create meeting in Firestore
      final meeting = {
        'clientId': context.read<AuthService>().currentUser?.uid,
        'clientName': '${context.read<AuthService>().currentUser?.firstName} ${context.read<AuthService>().currentUser?.lastName}',
        'scheduledAt': dateTime.toIso8601String(),
        'status': 'scheduled',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('meetings').add(meeting);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meeting scheduled for ${dateTime.toString().split('.')[0]}'),
          backgroundColor: AppTheme.goldLight,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling meeting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Helper widgets
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

// Meeting Scheduler Dialog
class _MeetingSchedulerDialog extends StatefulWidget {
  final Function(DateTime) onScheduled;

  const _MeetingSchedulerDialog({required this.onScheduled});

  @override
  State<_MeetingSchedulerDialog> createState() => _MeetingSchedulerDialogState();
}

class _MeetingSchedulerDialogState extends State<_MeetingSchedulerDialog> {
  DateTime? _selectedDateTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Schedule Meeting',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a date and time for your meeting',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Meetings are available Monday to Friday, 8:00 AM - 5:00 PM',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectDateTime,
            child: Text('Select Date & Time'),
          ),
          if (_selectedDateTime != null) ...[
            const SizedBox(height: 16),
            Text(
              'Selected: ${_selectedDateTime.toString().split('.')[0]}',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedDateTime != null
              ? () {
                  Navigator.of(context).pop();
                  widget.onScheduled(_selectedDateTime!);
                }
              : null,
          child: Text('Schedule'),
        ),
      ],
    );
  }

  void _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date!.year,
            date!.month,
            date!.day,
            time!.hour,
            time!.minute,
          );
        });
      }
    }
  }
}

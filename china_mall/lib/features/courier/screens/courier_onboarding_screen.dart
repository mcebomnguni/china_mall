import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/theme/app_theme.dart';
 
class CourierOnboardingScreen extends StatefulWidget {
  const CourierOnboardingScreen({super.key});
 
  @override
  State<CourierOnboardingScreen> createState() => _CourierOnboardingScreenState();
}
 
class _CourierOnboardingScreenState extends State<CourierOnboardingScreen> {
  static const _requiredDocs = [
    {'type': 'drivers_licence', 'label': "Driver's Licence", 'icon': Icons.credit_card},
    {'type': 'prdp', 'label': 'PrDP Certificate', 'icon': Icons.verified},
    {'type': 'licence_disc', 'label': 'Licence Disc', 'icon': Icons.disc_full},
    {'type': 'dekra_report', 'label': 'Dekra Car Report', 'icon': Icons.car_repair},
    {'type': 'police_clearance', 'label': 'Police Clearance', 'icon': Icons.security},
    {'type': 'selfie', 'label': 'Photo of Yourself', 'icon': Icons.face},
    {'type': 'id_document', 'label': 'ID Document', 'icon': Icons.badge},
    {'type': 'banking_details', 'label': 'Banking Details (PDF/Image)', 'icon': Icons.account_balance},
  ];
 
  Map<String, dynamic> _existingDocs = {};
  Map<String, bool> _uploading = {};  // ignore: prefer_final_fields
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _loadDocs();
  }
 
  Future<void> _loadDocs() async {
    setState(() => _loading = true);
    try {
      final res = await DeliveryService.getCourierDocuments();
      final docs = res['documents'] as List? ?? [];
      final map = <String, dynamic>{};
      for (final doc in docs) {
        map[doc['doc_type']] = doc;
      }
      setState(() => _existingDocs = map);
    } catch (_) {
      _showSnack('Failed to load documents.', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }
 
  Future<void> _uploadDoc(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || result.files.single.path == null) return;
 
    setState(() => _uploading[docType] = true);
    try {
      final res = await DeliveryService.uploadCourierDocument(
        docType: docType,
        filePath: result.files.single.path!,
      );
      if (res['statusCode'] == 200 || res['statusCode'] == 201) {
        _showSnack('Document uploaded successfully!');
        await _loadDocs();
      } else {
        _showSnack(res['error'] ?? 'Upload failed.', error: true);
      }
    } catch (_) {
      _showSnack('Upload failed. Try again.', error: true);
    } finally {
      setState(() => _uploading[docType] = false);
    }
  }
 
  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
 
  int get _submittedCount => _existingDocs.length;
  int get _approvedCount =>
      _existingDocs.values.where((d) => d['status'] == 'approved').length;
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Courier Onboarding',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
          tooltip: 'Back',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                  Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primaryLight,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_submittedCount/${_requiredDocs.length} Submitted',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$_approvedCount Approved',
                            style: const TextStyle(
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _submittedCount / _requiredDocs.length,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All documents must be approved before you can go online.',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
 
                // Document list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requiredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final doc = _requiredDocs[i];
                      final docType = doc['type'] as String;
                      final existing = _existingDocs[docType];
                      final isUploading = _uploading[docType] == true;
 
                      return _DocCard(
                        label: doc['label'] as String,
                        icon: doc['icon'] as IconData,
                        status: existing?['status'],
                        isUploading: isUploading,
                        rejectionReason: existing?['rejection_reason'],
                        onUpload: () => _uploadDoc(docType),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
 
class _DocCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? status;
  final bool isUploading;
  final String? rejectionReason;
  final VoidCallback onUpload;
 
  const _DocCard({
    required this.label,
    required this.icon,
    this.status,
    required this.isUploading,
    this.rejectionReason,
    required this.onUpload,
  });
 
  Color get _statusColor {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }
 
  IconData get _statusIcon {
    switch (status) {
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'pending': return Icons.hourglass_top;
      default: return Icons.upload_file;
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor.withValues(alpha: 0.15),
          child: Icon(icon, color: _statusColor, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon, size: 14, color: _statusColor),
                const SizedBox(width: 4),
                Text(
                  status == null ? 'Not uploaded' : status!,
                  style: TextStyle(color: _statusColor, fontSize: 12),
                ),
              ],
            ),
            if (rejectionReason != null)
              Text('Reason: $rejectionReason',
                  style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
        ),
        trailing: isUploading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(
                onPressed: onUpload,
                child: Text(
                  status == null
                      ? 'Upload'
                      : status == 'rejected'
                          ? 'Re-upload'
                          : 'Replace',
                  style: TextStyle(
                      color: status == 'approved'
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary),
                ),
              ),
      ),
    );
  }
}

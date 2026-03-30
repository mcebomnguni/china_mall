// ─────────────────────────────────────────────────────────────────────
//  screens/admin/admin_document_review_screen.dart
// ─────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminDocumentReviewScreen extends StatefulWidget {
  const AdminDocumentReviewScreen({super.key});

  @override
  State<AdminDocumentReviewScreen> createState() => _AdminDocumentReviewScreenState();
}

class _AdminDocumentReviewScreenState extends State<AdminDocumentReviewScreen> {
  List<AppUser> _registeredClients = [];
  List<DocumentReviewItem> _pendingReviews = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRegisteredClients();
    _loadPendingReviews();
  }

  Future<void> _loadRegisteredClients() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'client')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _registeredClients = snapshot.docs
              .map((doc) => AppUser.fromMap({
                ...doc.data(),
                'uid': doc.id,
              }))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading clients: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPendingReviews() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('document_reviews')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _pendingReviews = snapshot.docs
              .map((doc) => DocumentReviewItem.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  Future<bool> _confirmAction(String title, String message) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _approveDocument(String reviewId, String clientId) async {
    final confirmed = await _confirmAction(
      'Approve Document',
      'Are you sure you want to approve this document?'
    );
    
    if (!confirmed) return;
    try {
      await FirebaseFirestore.instance
          .collection('document_reviews')
          .doc(reviewId)
          .update({
            'status': 'approved',
            'reviewedAt': DateTime.now().toIso8601String(),
            'reviewedBy': context.read<AuthService>().currentUser?.uid,
          });

      // Update client status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .update({'documentStatus': 'approved'});

      _loadPendingReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document approved successfully'),
          backgroundColor: AppTheme.goldLight,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _flagDocument(String reviewId, String clientId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('document_reviews')
          .doc(reviewId)
          .update({
            'status': 'flagged',
            'flagReason': reason,
            'reviewedAt': DateTime.now().toIso8601String(),
            'reviewedBy': context.read<AuthService>().currentUser?.uid,
          });

      // Update client status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .update({'documentStatus': 'flagged'});

      _loadPendingReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document flagged for review'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error flagging document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestResubmission(String reviewId, String clientId) async {
    try {
      await FirebaseFirestore.instance
          .collection('document_reviews')
          .doc(reviewId)
          .update({
            'status': 'resubmission_requested',
            'reviewedAt': DateTime.now().toIso8601String(),
            'reviewedBy': context.read<AuthService>().currentUser?.uid,
          });

      // Update client status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .update({'documentStatus': 'resubmission_required'});

      _loadPendingReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resubmission requested from client'),
          backgroundColor: AppTheme.goldLight,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting resubmission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(
          'Document Review',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left side - Registered Clients
                Expanded(
                  flex: 1,
                  child: _buildClientsList(),
                ),
                const VerticalDivider(width: 1),
                // Right side - Pending Reviews
                Expanded(
                  flex: 2,
                  child: _buildPendingReviews(),
                ),
              ],
            ),
    );
  }

  Widget _buildClientsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registered Clients',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _registeredClients.isEmpty
                ? Center(
                    child: Text(
                      'No registered clients found',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _registeredClients.length,
                    itemBuilder: (context, index) {
                      final client = _registeredClients[index];
                      return _ClientCard(
                        client: client,
                        onTap: () => _showClientDetails(client),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviews() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Document Reviews',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _pendingReviews.isEmpty
                ? Center(
                    child: Text(
                      'No pending reviews',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _pendingReviews.length,
                    itemBuilder: (context, index) {
                      final review = _pendingReviews[index];
                      return _ReviewCard(
                        review: review,
                        onApprove: () => _approveDocument(review.id, review.clientId),
                        onFlag: () => _showFlagDialog(review),
                        onRequestResubmission: () => _requestResubmission(review.id, review.clientId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(AppUser client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Client Details',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Name', '${client.firstName} ${client.lastName}'),
              _DetailRow('Email', client.email),
              _DetailRow('Phone', client.phone),
              _DetailRow('Company', client.companyName),
              _DetailRow('Status', _getDocumentStatus(client.documentStatus)),
              _DetailRow('Registered', _formatDate(client.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFlagDialog(DocumentReviewItem review) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Flag Document',
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
              'Please provide a reason for flagging this document:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason for flagging...',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                _flagDocument(review.id, review.clientId, reasonController.text.trim());
              }
            },
            child: Text('Flag Document'),
          ),
        ],
      ),
    );
  }

  String _getDocumentStatus(String? status) {
    switch (status) {
      case 'approved':
        return '✅ Approved';
      case 'flagged':
        return '🚩 Flagged';
      case 'resubmission_required':
        return '📋 Resubmission Required';
      case 'pending':
        return '⏳ Pending';
      default:
        return '❓ Unknown';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final AppUser client;
  final VoidCallback onTap;

  const _ClientCard({
    required this.client,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${client.firstName} ${client.lastName}',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                client.email,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                client.companyName,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final DocumentReviewItem review;
  final VoidCallback onApprove;
  final VoidCallback onFlag;
  final VoidCallback onRequestResubmission;

  const _ReviewCard({
    required this.review,
    required this.onApprove,
    required this.onFlag,
    required this.onRequestResubmission,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.documentType,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Client: ${review.clientName}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${_formatDate(review.submittedAt)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(review.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    review.status.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onApprove,
                    child: Text('Approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onFlag,
                    child: Text('Flag'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRequestResubmission,
                    child: Text('Request Resubmission'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'flagged':
        return Colors.red;
      case 'resubmission_requested':
        return Colors.purple;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Document Review Item Model
class DocumentReviewItem {
  final String id;
  final String clientId;
  final String clientName;
  final String documentType;
  final String status;
  final DateTime submittedAt;

  DocumentReviewItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.documentType,
    required this.status,
    required this.submittedAt,
  });

  factory DocumentReviewItem.fromMap(Map<String, dynamic> map) {
    return DocumentReviewItem(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      documentType: map['documentType'] ?? '',
      status: map['status'] ?? 'pending',
      submittedAt: map['submittedAt'] is Timestamp
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['submittedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

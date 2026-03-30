// ─────────────────────────────────────────────────────────────────────────────
//  models/app_models.dart
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole { client, admin }

extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.client:
        return "Client";
      case UserRole.admin:
        return "Admin";
    }
  }
}

enum ApplicationStatus {
  pendingReview,
  opened,
  pendingOutcome,
  returned,
  approved,
  declined,
}

extension ApplicationStatusX on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.pendingReview:   return 'Pending Review';
      case ApplicationStatus.opened:          return 'Opened';
      case ApplicationStatus.pendingOutcome:  return 'Pending Outcome';
      case ApplicationStatus.returned:        return 'Returned';
      case ApplicationStatus.approved:        return 'Approved';
      case ApplicationStatus.declined:        return 'Declined';
    }
  }

  String get displayName => label;

  String get firestoreValue {
    switch (this) {
      case ApplicationStatus.pendingReview:   return 'pending_review';
      case ApplicationStatus.opened:          return 'opened';
      case ApplicationStatus.pendingOutcome:  return 'pending_outcome';
      case ApplicationStatus.returned:        return 'returned';
      case ApplicationStatus.approved:        return 'approved';
      case ApplicationStatus.declined:        return 'declined';
    }
  }

  static ApplicationStatus fromString(String s) {
    switch (s) {
      case 'opened':          return ApplicationStatus.opened;
      case 'pending_outcome': return ApplicationStatus.pendingOutcome;
      case 'returned':        return ApplicationStatus.returned;
      case 'approved':        return ApplicationStatus.approved;
      case 'declined':        return ApplicationStatus.declined;
      default:                return ApplicationStatus.pendingReview;
    }
  }
}

// ─── User Model ───────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String companyName;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;
  final String? documentStatus;

  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.companyName,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.documentStatus,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() => {
    'uid':            uid,
    'username':       username,
    'email':          email,
    'firstName':      firstName,
    'lastName':       lastName,
    'phone':          phone,
    'companyName':    companyName,
    'role':           role.name,
    'createdAt':      createdAt.toIso8601String(),
    'isActive':       isActive,
    'documentStatus': documentStatus,
  };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    uid:         m['uid'] ?? '',
    username:    m['username'] ?? '',
    email:       m['email'] ?? '',
    firstName:   m['firstName'] ?? '',
    lastName:    m['lastName'] ?? '',
    phone:       m['phone'] ?? '',
    companyName: m['companyName'] ?? '',
    role:        UserRole.values.firstWhere((r) => r.name == m['role']) ?? UserRole.client,
    createdAt:   DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    isActive:    m['isActive'] ?? true,
    documentStatus: m['documentStatus'],
  );

  AppUser copyWith({
    String? username, String? email, String? firstName, String? lastName,
    String? phone, String? companyName, bool? isActive,
  }) => AppUser(
    uid:         uid,
    username:    username    ?? this.username,
    email:       email       ?? this.email,
    firstName:   firstName   ?? this.firstName,
    lastName:    lastName    ?? this.lastName,
    phone:       phone       ?? this.phone,
    companyName: companyName ?? this.companyName,
    role:        role,
    createdAt:   createdAt,
    isActive:    isActive    ?? this.isActive,
  );
}

// ─── Document Model ───────────────────────────────────────────────────────────
class UploadedDocument {
  final String name;
  final String url;
  final String type; // e.g. "pdf", "image"
  final DateTime uploadedAt;

  const UploadedDocument({
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() => {
    'name':       name,
    'url':        url,
    'type':       type,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory UploadedDocument.fromMap(Map<String, dynamic> m) => UploadedDocument(
    name:       m['name'] ?? '',
    url:        m['url']  ?? '',
    type:       m['type'] ?? '',
    uploadedAt: DateTime.tryParse(m['uploadedAt'] ?? '') ?? DateTime.now(),
  );
}

// ─── Product Category ─────────────────────────────────────────────────────────
class ProductCategory {
  final String id;
  final String name;
  final String description;
  final List<ProductItem> items;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
  });

  String get displayName => name;
}

class ProductItem {
  final String id;
  final String name;
  final String description;
  final String categoryId;

  const ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
  });
}

// ─── Application Model ────────────────────────────────────────────────────────
class ServiceApplication {
  final String id;
  final String clientUid;
  final String clientName;
  final String clientEmail;
  final String companyName;
  final String productCategoryId;
  final String productCategoryName;
  final String selectedProductId;
  final String selectedProductName;
  final List<UploadedDocument> documents;
  final ApplicationStatus status;
  final String? adminNote;
  final String? returnReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceApplication({
    required this.id,
    required this.clientUid,
    required this.clientName,
    required this.clientEmail,
    required this.companyName,
    required this.productCategoryId,
    required this.productCategoryName,
    required this.selectedProductId,
    required this.selectedProductName,
    required this.documents,
    required this.status,
    this.adminNote,
    this.returnReason,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id':                    id,
    'clientUid':             clientUid,
    'clientName':            clientName,
    'clientEmail':           clientEmail,
    'companyName':           companyName,
    'productCategoryId':     productCategoryId,
    'productCategoryName':   productCategoryName,
    'selectedProductId':     selectedProductId,
    'selectedProductName':   selectedProductName,
    'documents':             documents.map((d) => d.toMap()).toList(),
    'status':                status.firestoreValue,
    'adminNote':             adminNote,
    'returnReason':          returnReason,
    'createdAt':             createdAt.toIso8601String(),
    'updatedAt':             updatedAt.toIso8601String(),
  };

  factory ServiceApplication.fromMap(Map<String, dynamic> m) => ServiceApplication(
    id:                    m['id'] ?? '',
    clientUid:             m['clientUid'] ?? '',
    clientName:            m['clientName'] ?? '',
    clientEmail:           m['clientEmail'] ?? '',
    companyName:           m['companyName'] ?? '',
    productCategoryId:     m['productCategoryId'] ?? '',
    productCategoryName:   m['productCategoryName'] ?? '',
    selectedProductId:     m['selectedProductId'] ?? '',
    selectedProductName:   m['selectedProductName'] ?? '',
    documents:             (m['documents'] as List? ?? [])
        .map((d) => UploadedDocument.fromMap(d as Map<String, dynamic>))
        .toList(),
    status:                ApplicationStatusX.fromString(m['status'] ?? ''),
    adminNote:             m['adminNote'],
    returnReason:          m['returnReason'],
    createdAt:             DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt:             DateTime.tryParse(m['updatedAt'] ?? '') ?? DateTime.now(),
  );

  ServiceApplication copyWith({
    ApplicationStatus? status,
    String? adminNote,
    String? returnReason,
    DateTime? updatedAt,
  }) => ServiceApplication(
    id:                    id,
    clientUid:             clientUid,
    clientName:            clientName,
    clientEmail:           clientEmail,
    companyName:           companyName,
    productCategoryId:     productCategoryId,
    productCategoryName:   productCategoryName,
    selectedProductId:     selectedProductId,
    selectedProductName:   selectedProductName,
    documents:             documents,
    status:                status       ?? this.status,
    adminNote:             adminNote    ?? this.adminNote,
    returnReason:          returnReason ?? this.returnReason,
    createdAt:             createdAt,
    updatedAt:             updatedAt    ?? this.updatedAt,
  );
}

// ─── Static Product Catalogue ─────────────────────────────────────────────────
class ProductCatalogue {
  static const List<ProductCategory> categories = [
    ProductCategory(
      id: 'insurance_bonds',
      name: 'Insurance Bonds and Guarantees',
      description: 'Statutory and contractual bond instruments for project and business security.',
      items: [
        ProductItem(id: 'bid_bond', name: 'Bid Bond',
            description: 'A statutory requirement when participating for a tender. STF Capital is able to issue bid bonds through insurance and banks.',
            categoryId: 'insurance_bonds'),
        ProductItem(id: 'advance_payment', name: 'Advance Payment Guarantee',
            description: 'Ensures that advance funds remain protected. If the contractor fails to deliver due to insolvency risks, the employer can recover the funds.',
            categoryId: 'insurance_bonds'),
        ProductItem(id: 'performance_guarantee', name: 'Performance Guarantee',
            description: 'A promise to the project owner that the contract will be completed according to the specified terms.',
            categoryId: 'insurance_bonds'),
        ProductItem(id: 'retention_bond', name: 'Retention Bond',
            description: 'Allows contractors to receive retained payments earlier while guaranteeing the retention amount to the project owner.',
            categoryId: 'insurance_bonds'),
        ProductItem(id: 'credit_guarantee', name: 'Credit Guarantee',
            description: 'Guarantees payment to a supplier or creditor, often helping a business secure better credit terms for materials.',
            categoryId: 'insurance_bonds'),
        ProductItem(id: 'maintenance_bond', name: 'Maintenance Bond',
            description: 'Ensures that the contractor will fix defects or faults that appear after the project is finished, within a specified period.',
            categoryId: 'insurance_bonds'),
      ],
    ),
    ProductCategory(
      id: 'financial_advisory',
      name: 'Financial Advisory Services',
      description: 'Expert financial guidance, capital solutions, and strategic restructuring services.',
      items: [
        ProductItem(id: 'capital_raise', name: 'Capital Raise',
            description: 'Comprehensive services to raise capital from various sources including venture capital, private equity, and debt financing.',
            categoryId: 'financial_advisory'),
        ProductItem(id: 'consultancy', name: 'Consultancy Services',
            description: 'Expert advice on financial strategy, mergers and acquisitions, and corporate restructuring to optimise your financial performance.',
            categoryId: 'financial_advisory'),
        ProductItem(id: 'order_financing', name: 'Order Financing',
            description: 'Secure short-term funding to fulfil large orders and manage your working capital effectively.',
            categoryId: 'financial_advisory'),
        ProductItem(id: 'risk_participation', name: 'Risk Participation Structured Finance',
            description: 'Innovative financing solutions that involve sharing and mitigating risks among multiple parties.',
            categoryId: 'financial_advisory'),
        ProductItem(id: 'debt_restructuring', name: 'Debt Restructuring',
            description: 'Reorganising a company outstanding debt to improve liquidity and enable continued operation.',
            categoryId: 'financial_advisory'),
      ],
    ),
    ProductCategory(
      id: 'general_insurance',
      name: 'General Insurance Products',
      description: 'Comprehensive insurance solutions protecting your business, assets, and operations.',
      items: [
        ProductItem(id: 'car_insurance', name: 'Contractor All Risk (CAR) Insurance',
            description: 'Comprehensive coverage for construction projects, protecting against damage, third-party liability, and delays.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'erection_all_risk', name: 'Erection All Risk Insurance',
            description: 'Specialised coverage for the erection and installation of machinery and steel structures.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'goods_in_transit', name: 'Goods in Transit',
            description: 'Insurance for goods against loss or damage while in transit by road, rail, sea, or air.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'public_liability', name: 'Public Liability Insurance',
            description: 'Protection against claims of personal injury or property damage that a third party suffers as a result of your business activities.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'fire_damage', name: 'Fire Damage Insurance',
            description: 'Cover for damage to property caused by fire, lightning, and explosion.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'motor_third_party', name: 'Motor Insurance - Third Party Only',
            description: 'Basic motor insurance covering your legal liability for damage to a third party property or for death or injury to a third party.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'motor_third_fire_theft', name: 'Motor Insurance - Third Party Fire and Theft',
            description: 'Covers third-party liability as well as loss of or damage to your vehicle due to fire or theft.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'motor_comprehensive', name: 'Motor Insurance - Comprehensive',
            description: 'The widest cover, including third-party, fire and theft, and accidental damage to your own vehicle.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'agriculture', name: 'Agriculture Insurance',
            description: 'Protecting farmers against loss of their crops due to natural disasters or loss of revenue due to declines in the prices of agricultural commodities.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'travel', name: 'Travel Insurance',
            description: 'Coverage for risks associated with travelling such as loss of luggage, delays, and medical emergencies.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'export_credit', name: 'Export Credit Insurance',
            description: 'Protection against the risk of non-payment by foreign buyers due to commercial and political risks.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'dpip', name: 'Domestic Payments Insurance Policy (DPIP)',
            description: 'Cover for businesses against the risk of non-payment by domestic customers.',
            categoryId: 'general_insurance'),
        ProductItem(id: 'marine', name: 'Marine Insurance',
            description: 'Coverage for loss or damage of ships, cargo, terminals, and any transport by which property is transferred, acquired, or held between the points of origin and final destination.',
            categoryId: 'general_insurance'),
      ],
    ),
  ];

  static ProductCategory? findById(String id) {
    try { return categories.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }

  static ProductItem? findItemById(String categoryId, String itemId) {
    final cat = findById(categoryId);
    if (cat == null) return null;
    try { return cat.items.firstWhere((i) => i.id == itemId); }
    catch (_) { return null; }
  }
}

// ─── Required Documents ───────────────────────────────────────────────────────
class RequiredDocuments {
  static const List<String> registration = [
    'Company Profile',
    'Certificate of Incorporation',
    'Articles of Association',
    'CR6',
    'CR14',
    'Tax Clearance',
    'Financial Statements or Bank Statements',
    'Contract or Purchase Order (Required when requesting for a product)',
    'Tender Documents (For bid bonds)',
  ];
}

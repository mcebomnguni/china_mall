// ─────────────────────────────────────────────────────────────────────
//  screens/client/insurance_bonds_screen.dart
// ─────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class InsuranceBondsScreen extends StatefulWidget {
  const InsuranceBondsScreen({super.key});

  @override
  State<InsuranceBondsScreen> createState() => _InsuranceBondsScreenState();
}

class _InsuranceBondsScreenState extends State<InsuranceBondsScreen> {
  String? _selectedCategory;
  String? _selectedProduct;
  String? _selectedProvider;
  List<String> _selectedProducts = [];
  String? _selectedCompany;
  
  // Insurance Bonds & Guarantees Categories
  static const List<String> _categories = [
    'Insurance Bonds',
  ];

  // Products under each category
  final Map<String, List<String>> _categoryProducts = {
    'Insurance Bonds': [
      'Bid Bond',
      'Advance Payment Guarantee', 
      'Performance Guarantee',
      'Retention Bond',
      'Credit Guarantee',
      'Maintenance Bond',
    ],
  };

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

  // Banks
  final List<String> _banks = [
    'BancABC — African Banking Corporation',
    'Success Bank — Success Bank',
    'African Century Limited — African Century Limited',
    'AFC Commercial Bank — AFC Commercial Bank',
    'NBS Bank — NBS Bank',
    'NMB Bank — NMB Bank',
    'POSB Zimbabwe — People\'s Own Savings Bank',
    'CBZ Bank — Commercial Bank of Zimbabwe',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isWide = MediaQuery.of(context).size.width > 700;

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
            padding: EdgeInsets.only(
              left: isWide ? 0 : 24,
              right: isWide ? 0 : 24,
              top: 32,
              bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'Insurance Bonds & Guarantees',
                    subtitle: 'Select the type of bond or guarantee you require.',
                  ),
                  const SizedBox(height: 28),

                  // Step 1: Category Selection
                  _buildStepIndicator(1),
                  const SizedBox(height: 16),
                  _buildCategorySelection(),
                  const SizedBox(height: 28),

                  // Step 2: Products Selection
                  if (_selectedCategory != null) ...[
                    _buildStepIndicator(2),
                    const SizedBox(height: 16),
                    _buildProductsSelection(),
                    const SizedBox(height: 28),
                  ],

                  // Step 3: Provider Selection
                  if (_selectedProducts.isNotEmpty) ...[
                    _buildStepIndicator(3),
                    const SizedBox(height: 16),
                    _buildProviderSelection(),
                    const SizedBox(height: 28),
                  ],

                  // Step 4: Company/Bank Selection
                  if (_selectedProvider != null) ...[
                    _buildStepIndicator(4),
                    const SizedBox(height: 16),
                    _buildCompanySelection(),
                    const SizedBox(height: 28),
                  ],

                  // Continue Button
                  if (_selectedCompany != null) ...[
                    GoldButton(
                      label: 'Continue to Documents',
                      onPressed: _continueToDocuments,
                      isLoading: auth.isLoading,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Step $step: ${_getStepTitle(step)}',
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Category',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          ..._categories.map((category) => RadioListTile<String>(
            title: Text(
              category,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            value: category,
            groupValue: _selectedCategory,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _selectedProducts.clear();
                _selectedProduct = null;
                _selectedProvider = null;
                _selectedCompany = null;
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          )),
        ],
      ),
    );
  }

  Widget _buildProductsSelection() {
    final products = _categoryProducts[_selectedCategory] ?? [];
    
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
          ...products.map((product) => CheckboxListTile(
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
                  if (_selectedProducts.length >= 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maximum 5 products allowed')),
                    );
                    return;
                  }
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

  Widget _buildProviderSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Provider Type',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: Text(
              'Bank',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            value: 'bank',
            groupValue: _selectedProvider,
            onChanged: (value) {
              setState(() {
                _selectedProvider = value;
                _selectedCompany = null;
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          RadioListTile<String>(
            title: Text(
              'Insurance Company',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            value: 'insurance',
            groupValue: _selectedProvider,
            onChanged: (value) {
              setState(() {
                _selectedProvider = value;
                _selectedCompany = null;
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySelection() {
    final companies = _selectedProvider == 'bank' ? _banks : _insuranceCompanies;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select ${_selectedProvider == 'bank' ? 'Bank' : 'Insurance Company'}',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          ...companies.map((company) => RadioListTile<String>(
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

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Select Category';
      case 2:
        return 'Select Products';
      case 3:
        return 'Choose Provider';
      case 4:
        return 'Select ${_selectedProvider == 'bank' ? 'Bank' : 'Insurance Company'}';
      default:
        return 'Select Provider';
    }
  }

  void _continueToDocuments() {
    if (_selectedCategory == null || _selectedProducts.isEmpty || _selectedProvider == null || _selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps')),
      );
      return;
    }
    
    context.push('/insurance-bonds/documents', extra: {
      'category': _selectedCategory,
      'products': _selectedProducts,
      'provider': _selectedProvider,
      'company': _selectedCompany,
    });
  }
}

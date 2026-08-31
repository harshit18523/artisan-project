import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/strings.dart';
import '../models/product.dart';
import '../providers/app_state.dart';
import '../providers/data_provider.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../theme/palette.dart';
import '../theme/shadows.dart';
import '../widgets/success_feedback_widgets.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  File? _image;
  bool _loading = false;
  String? _statusMessage;
  String? _error;
  Product? _createdProduct;

  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _image = File(picked.path);
        _error = null;
        _createdProduct = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _analyzeAndSave() async {
    if (_image == null) return;

    final dataProvider = context.read<DataProvider>();
    dataProvider.setProcessingAi(true);

    setState(() {
      _loading = true;
      _statusMessage = 'Analyzing with Gemini AI...';
      _error = null;
      _createdProduct = null;
    });

    try {
      // 1. Gemini AI analysis
      final ai = await GeminiService.analyzeProductImage(_image!);

      if (mounted) {
        setState(() => _statusMessage = 'Uploading image to Supabase Storage...');
      }

      final nameEn = ai['title_en'] as String? ?? 'Handmade Product';
      final nameHi = ai['title_hi'] as String? ?? 'उत्पाद';
      final description = ai['description'] as String? ?? '';
      final category = ai['category'] as String? ?? 'Other';
      final priceInRupees = (ai['estimated_price_inr'] as num?)?.toInt() ?? 500;
      final productId = const Uuid().v4();

      // 2. Upload photo to Supabase Storage product-images bucket
      String? remoteImageUrl;
      bool isSynced = false;

      try {
        remoteImageUrl = await SupabaseService.uploadProductImage(_image!);
        isSynced = true;
      } catch (uploadErr) {
        debugPrint('❌ Supabase storage upload failed: $uploadErr');
      }

      // 3. If uploaded to Supabase Storage, insert record into Supabase products table with public URL
      String? remoteId;
      if (isSynced && remoteImageUrl != null && remoteImageUrl.isNotEmpty) {
        if (mounted) {
          setState(() => _statusMessage = 'Saving to Supabase & ONDC...');
        }
        try {
          remoteId = await SupabaseService.insertProduct(
            id: productId,
            nameEn: nameEn,
            nameHi: nameHi,
            description: description,
            category: category,
            priceInRupees: priceInRupees,
            imageUrl: remoteImageUrl,
          );
        } catch (dbErr) {
          debugPrint('❌ Supabase DB insert error: $dbErr');
          isSynced = false;
        }
      }

      // 4. Save to local SQLite via DataProvider
      final newProduct = Product(
        id: productId,
        nameEn: nameEn,
        nameHi: nameHi,
        description: description,
        category: category,
        priceInRupees: priceInRupees,
        status: ProductStatus.live,
        image: remoteImageUrl ?? _image!.path,
        isSynced: isSynced,
        remoteId: remoteId,
      );

      await dataProvider.addProduct(newProduct);
      dataProvider.setProcessingAi(false);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _statusMessage = null;
        _createdProduct = newProduct;
      });
    } catch (e) {
      dataProvider.setProcessingAi(false);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error: $e';
        });
      }
      debugPrint('Full error: $e');
    }
  }

  void _goToCatalog() {
    context.read<AppState>().setTab(NavTab.catalog);
    Navigator.pop(context);
  }

  void _resetForAnother() {
    setState(() {
      _image = null;
      _createdProduct = null;
      _loading = false;
      _statusMessage = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isHi = app.language == Language.hi;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _createdProduct != null
              ? (isHi ? 'उत्पाद जोड़ा गया' : 'Product Added')
              : (isHi ? 'फोटो खींचें और कैटलॉग बनाएं' : 'Snap & AI Catalog'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: dark ? Colors.white : AppColors.ink900,
          ),
        ),
        backgroundColor: dark ? AppColors.ink950 : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: dark ? Colors.white : AppColors.ink900),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _createdProduct != null
              ? _buildSuccessView(isHi, dark)
              : _buildCaptureView(isHi, dark),
        ),
      ),
    );
  }

  Widget _buildCaptureView(bool isHi, bool dark) {
    return Padding(
      key: const ValueKey('capture_view'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Image preview area
          Expanded(
            child: _image == null
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: dark ? AppColors.ink800 : AppColors.saffron50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: dark ? AppColors.ink700 : AppColors.saffron200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          size: 64,
                          color: dark ? AppColors.ink500 : AppColors.saffron600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isHi
                              ? 'फोटो खींचें या गैलरी से चुनें'
                              : 'Take a photo or choose from gallery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: dark ? Colors.white70 : AppColors.ink700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isHi
                              ? 'AI वस्तु की पहचान करेगा और नाम व सही दाम तय करेगा'
                              : 'AI will identify the item and write the title & price',
                          style: const TextStyle(fontSize: 13, color: AppColors.ink500),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(
                      _image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
          ),

          const SizedBox(height: 20),

          // Camera and Gallery buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pick(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: dark ? AppColors.ink700 : AppColors.saffron600,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    color: dark ? Colors.white : AppColors.saffron700,
                  ),
                  label: Text(
                    isHi ? 'कैमरा' : 'Camera',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : AppColors.saffron700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: dark ? AppColors.ink700 : AppColors.saffron600,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    Icons.photo_library_rounded,
                    color: dark ? Colors.white : AppColors.saffron700,
                  ),
                  label: Text(
                    isHi ? 'गैलरी' : 'Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : AppColors.saffron700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status / Error display
          if (_loading && _statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _statusMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.saffron600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.red600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_image == null || _loading) ? null : _analyzeAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffron600,
                disabledBackgroundColor: dark ? AppColors.ink800 : AppColors.ink200,
                elevation: _image != null && !_loading ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          isHi ? 'AI से जांचें और जोड़ें' : 'Analyze with AI & Save',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isHi, bool dark) {
    final product = _createdProduct!;
    final name = isHi ? product.nameHi : product.nameEn;
    final textColor = dark ? Colors.white : AppColors.ink900;

    return SingleChildScrollView(
      key: const ValueKey('success_product_view'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Animated checkmark badge
          const SuccessCheckAnimation(
            size: 76,
            primaryColor: AppColors.green600,
          ),
          const SizedBox(height: 16),

          // Success heading
          Text(
            isHi ? 'उत्पाद सफलतापूर्वक जोड़ा गया!' : 'Product Added Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Sync pill — green "Live on ONDC" only once the cloud actually has
          // it; amber "Pending Sync" when the product is saved locally only.
          // Mirrors the badge logic in product_card.dart.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: product.isSynced ? AppColors.green50 : AppColors.amber100,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: (product.isSynced ? AppColors.green600 : AppColors.amber600)
                    .withAlpha(80),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: product.isSynced
                        ? AppColors.green600
                        : AppColors.amber600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  product.isSynced
                      ? (isHi ? 'ONDC पर लाइव' : 'Live on ONDC')
                      : (isHi ? 'सिंक होना बाकी' : 'Pending Sync'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: product.isSynced
                        ? AppColors.green800
                        : AppColors.amber600,
                  ),
                ),
              ],
            ),
          ),
          if (!product.isSynced) ...[
            const SizedBox(height: 8),
            Text(
              isHi
                  ? 'फोन में सुरक्षित है — इंटरनेट आने पर अपने आप सिंक होगा'
                  : 'Saved on your phone — will sync automatically when online',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.ink500),
            ),
          ],
          const SizedBox(height: 24),

          // Product Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? AppColors.ink800 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dark ? AppColors.ink700 : AppColors.saffron100),
              boxShadow: kCardShadow,
            ),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: _image != null
                        ? Image.file(_image!, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.saffron50,
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: AppColors.saffron600,
                              size: 36,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.saffron600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: dark ? AppColors.ink700 : AppColors.saffron50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white70 : AppColors.saffron700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Primary Button: View in Catalog
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _goToCatalog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffron600,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 22),
              label: Text(
                isHi ? 'कैटलॉग में देखें' : 'View in Catalog',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Button: Add Another Product
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _resetForAnother,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: dark ? AppColors.ink700 : AppColors.ink200,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                Icons.add_a_photo_rounded,
                color: dark ? Colors.white70 : AppColors.ink700,
                size: 20,
              ),
              label: Text(
                isHi ? '+ एक और उत्पाद जोड़ें' : '+ Add Another Product',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : AppColors.ink900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

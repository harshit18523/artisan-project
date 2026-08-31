import 'dart:io';

import '../models/product.dart';
import 'supabase_service.dart';

/// The Supabase operations [DataProvider] depends on, behind an interface.
///
/// Exists so the sync logic can be tested without a live Supabase project —
/// [SupabaseService] is a set of static methods and cannot be substituted.
/// Production code uses [LiveSupabaseGateway]; tests supply a fake.
abstract class SupabaseGateway {
  Future<String> uploadProductImage(File imageFile);

  /// Returns the primary key of the created row — see
  /// [SupabaseService.insertProduct].
  Future<String> insertProduct({
    required String id,
    required String nameEn,
    required String nameHi,
    required String description,
    required String category,
    required int priceInRupees,
    required String imageUrl,
  });

  Future<void> updateProduct(Product product);

  Future<void> deleteProduct({required String id, String? imageUrl});
}

/// Default gateway: forwards straight to [SupabaseService].
class LiveSupabaseGateway implements SupabaseGateway {
  const LiveSupabaseGateway();

  @override
  Future<String> uploadProductImage(File imageFile) =>
      SupabaseService.uploadProductImage(imageFile);

  @override
  Future<String> insertProduct({
    required String id,
    required String nameEn,
    required String nameHi,
    required String description,
    required String category,
    required int priceInRupees,
    required String imageUrl,
  }) =>
      SupabaseService.insertProduct(
        id: id,
        nameEn: nameEn,
        nameHi: nameHi,
        description: description,
        category: category,
        priceInRupees: priceInRupees,
        imageUrl: imageUrl,
      );

  @override
  Future<void> updateProduct(Product product) =>
      SupabaseService.updateProduct(product);

  @override
  Future<void> deleteProduct({required String id, String? imageUrl}) =>
      SupabaseService.deleteProduct(id: id, imageUrl: imageUrl);
}

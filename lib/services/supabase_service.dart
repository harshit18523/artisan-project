import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const _bucket = 'product-images';

  /// Extracts the storage object path/filename from a Supabase public CDN URL.
  static String? _extractStorageFileName(String imageUrl) {
    if (!imageUrl.contains('/storage/v1/object/public/$_bucket/')) {
      return null;
    }
    final parts = imageUrl.split('/storage/v1/object/public/$_bucket/');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return Uri.decodeComponent(parts[1]);
    }
    return null;
  }

  /// Uploads local image file to Supabase Storage bucket 'product-images'
  /// and returns the public HTTP CDN URL.
  static Future<String> uploadProductImage(File imageFile) async {
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bytes = await imageFile.readAsBytes();

    try {
      await _client.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      final publicUrl = _client.storage.from(_bucket).getPublicUrl(fileName);
      debugPrint('✅ Image uploaded to Supabase Storage: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Storage upload failed: $e');
      rethrow;
    }
  }

  /// Postgres error codes meaning "this table assigns its own primary key".
  ///
  /// Raised when we offer a client-generated UUID to an `id` column that is an
  /// integer or `GENERATED ALWAYS AS IDENTITY`. Anything else (network, RLS,
  /// constraint violations) must not trigger the retry below, or a insert that
  /// actually succeeded could be duplicated.
  static const _serverAssignsIdCodes = {
    '22P02', // invalid input syntax for type (uuid string -> integer column)
    '42804', // datatype mismatch
    '428C9', // cannot insert into GENERATED ALWAYS column
    '55000', // object not in prerequisite state
  };

  /// Insert product into Supabase and return the primary key of the new row.
  ///
  /// Offers [id] as the row's key so local SQLite and Supabase share one
  /// identity. If the table assigns its own key instead, retries without it and
  /// returns whatever Postgres assigned — callers must persist the result as
  /// [Product.remoteId] so later updates and deletes can find the row.
  static Future<String> insertProduct({
    required String id,
    required String nameEn,
    required String nameHi,
    required String description,
    required String category,
    required int priceInRupees,
    required String imageUrl,
  }) async {
    final payload = {
      'name_en': nameEn,
      'name_hi': nameHi,
      'description': description,
      'category': category,
      'price_in_rupees': priceInRupees,
      'status': 'live',
      'image_url': imageUrl,
    };

    try {
      final row = await _client
          .from('products')
          .insert({'id': id, ...payload})
          .select()
          .single();
      final remoteId = row['id'].toString();
      debugPrint('✅ Inserted product into Supabase with client id: $remoteId');
      return remoteId;
    } on PostgrestException catch (e) {
      if (!_serverAssignsIdCodes.contains(e.code)) {
        debugPrint('❌ Supabase insert failed: $e');
        rethrow;
      }
      debugPrint(
          'ℹ️ products.id is server-assigned (${e.code}); retrying without client id');
    }

    try {
      final row =
          await _client.from('products').insert(payload).select().single();
      final remoteId = row['id'].toString();
      debugPrint('✅ Inserted product into Supabase with server id: $remoteId');
      return remoteId;
    } catch (e) {
      debugPrint('❌ Supabase insert failed: $e');
      rethrow;
    }
  }

  /// Update product in Supabase database table.
  ///
  /// Throws if no row matched — PostgREST reports a filter that matches nothing
  /// as success, which would otherwise leave the product marked as synced while
  /// the cloud silently keeps the stale values.
  static Future<void> updateProduct(Product product) async {
    try {
      final rows = await _client.from('products').update({
        'name_en': product.nameEn,
        'name_hi': product.nameHi,
        'description': product.description,
        'category': product.category,
        'price_in_rupees': product.priceInRupees,
        'status': product.status.name,
        'image_url': product.image,
      }).eq('id', product.syncKey).select();

      if ((rows as List).isEmpty) {
        throw StateError(
            'No Supabase row matched id ${product.syncKey} — nothing updated.');
      }
      debugPrint('✅ Updated product in Supabase table: ${product.syncKey}');
    } catch (e) {
      debugPrint('⚠️ Supabase update failed: $e');
      rethrow;
    }
  }

  /// Delete product database record and associated image file from Supabase Storage.
  ///
  /// [id] must be the product's [Product.syncKey], not necessarily its local id.
  static Future<void> deleteProduct({required String id, String? imageUrl}) async {
    try {
      // 1. Delete database row from products table
      await _client.from('products').delete().eq('id', id);

      // 2. If imageUrl is a valid Supabase Storage URL, remove file from bucket
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final storagePath = _extractStorageFileName(imageUrl);
        if (storagePath != null && storagePath.isNotEmpty) {
          await _client.storage.from(_bucket).remove([storagePath]);
          debugPrint('🗑️ Removed image from Supabase storage: $storagePath');
        }
      }

      debugPrint('✅ Product and image deleted from Supabase: $id');
    } catch (e) {
      debugPrint('❌ Cloud deletion failed: $e');
    }
  }

}

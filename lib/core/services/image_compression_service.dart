import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service de compression d'image style WhatsApp
/// Réduit significativement la taille des images tout en gardant une qualité acceptable
class ImageCompressionService {
  /// Qualité de compression (0-100)
  /// WhatsApp utilise environ 70-80%
  static const int _defaultQuality = 70;
  
  /// Largeur maximale en pixels
  /// WhatsApp redimensionne à environ 1280px de large
  static const int _maxWidth = 1280;
  
  /// Hauteur maximale en pixels
  static const int _maxHeight = 1280;
  
  /// Compresse une image depuis un fichier
  /// Retourne le fichier compressé ou null en cas d'erreur
  static Future<File?> compressImage(File imageFile, {
    int quality = _defaultQuality,
    int maxWidth = _maxWidth,
    int maxHeight = _maxHeight,
  }) async {
    try {
      final originalSize = await imageFile.length();
      print('📸 [COMPRESSION] Taille originale: ${_formatFileSize(originalSize)}');
      
      // Obtenir le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path, 
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );
      
      // Compresser l'image
      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
        // Rotation automatique selon EXIF
        autoCorrectionAngle: true,
        // Garder les métadonnées EXIF (localisation, etc.)
        keepExif: false,
      );
      
      if (compressedXFile == null) {
        print('❌ [COMPRESSION] Échec de la compression');
        return null;
      }
      
      final compressedFile = File(compressedXFile.path);
      final compressedSize = await compressedFile.length();
      final compressionRatio = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
      
      print('✅ [COMPRESSION] Taille compressée: ${_formatFileSize(compressedSize)}');
      print('📉 [COMPRESSION] Réduction: $compressionRatio%');
      
      return compressedFile;
    } catch (e) {
      print('❌ [COMPRESSION] Erreur: $e');
      return null;
    }
  }
  
  /// Compresse une image depuis des bytes
  static Future<Uint8List?> compressImageBytes(Uint8List imageBytes, {
    int quality = _defaultQuality,
    int maxWidth = _maxWidth,
    int maxHeight = _maxHeight,
  }) async {
    try {
      final originalSize = imageBytes.length;
      print('📸 [COMPRESSION] Taille originale (bytes): ${_formatFileSize(originalSize)}');
      
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
        keepExif: false,
      );
      
      final compressionRatio = ((originalSize - compressedBytes.length) / originalSize * 100).toStringAsFixed(1);
      
      print('✅ [COMPRESSION] Taille compressée: ${_formatFileSize(compressedBytes.length)}');
      print('📉 [COMPRESSION] Réduction: $compressionRatio%');
      
      return compressedBytes;
    } catch (e) {
      print('❌ [COMPRESSION] Erreur: $e');
      return null;
    }
  }
  
  /// Compresse avec différents niveaux de qualité
  /// - high: 85% qualité (pour les photos importantes)
  /// - medium: 70% qualité (par défaut, style WhatsApp)
  /// - low: 50% qualité (pour économiser beaucoup de données)
  static Future<File?> compressWithQuality(
    File imageFile, 
    CompressionQuality compressionQuality,
  ) async {
    int quality;
    int maxDimension;
    
    switch (compressionQuality) {
      case CompressionQuality.high:
        quality = 85;
        maxDimension = 1920;
        break;
      case CompressionQuality.medium:
        quality = 70;
        maxDimension = 1280;
        break;
      case CompressionQuality.low:
        quality = 50;
        maxDimension = 800;
        break;
    }
    
    return compressImage(
      imageFile,
      quality: quality,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
    );
  }
  
  /// Formate la taille du fichier de manière lisible
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  /// Retourne la taille formatée d'un fichier
  static Future<String> getFormattedFileSize(File file) async {
    final size = await file.length();
    return _formatFileSize(size);
  }
}

/// Niveaux de qualité de compression
enum CompressionQuality {
  high,   // 85% - Photos importantes
  medium, // 70% - Style WhatsApp (défaut)
  low,    // 50% - Économie maximale
}

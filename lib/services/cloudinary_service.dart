import 'dart:io';
import 'package:cloudinary/cloudinary.dart';

class CloudinaryService {
  static final _cloudinary = Cloudinary.signedConfig(
    apiKey: '223643466368582', 
    apiSecret: 'XAjSC2APftjQi0y2C0c5qTpEvEw', // User provided cloud_name and api_key, but secret was <your_api_secret>
    cloudName: 'dcddd4q9n',
  );

  /// Uploads a file to Cloudinary and returns the URL.
  Future<String?> uploadFile(File file, {String folder = 'general'}) async {
    try {
      final response = await _cloudinary.upload(
        file: file.path,
        fileBytes: file.readAsBytesSync(),
        resourceType: CloudinaryResourceType.auto, // Use auto to support PDF/Docs as well
        folder: 'astar_learning/$folder',
      );
      
      if (response.isSuccessful) {
        return response.secureUrl;
      } else {
        print('Cloudinary Upload Error: ${response.error}');
        return null;
      }
    } catch (e) {
      print('Cloudinary Exception: $e');
      return null;
    }
  }

  /// Uploads multiple files and returns a list of URLs.
  Future<List<String>> uploadMultiple(List<File> files, {String folder = 'general'}) async {
    List<String> urls = [];
    for (var file in files) {
      final url = await uploadFile(file, folder: folder);
      if (url != null) urls.add(url);
    }
    return urls;
  }
}

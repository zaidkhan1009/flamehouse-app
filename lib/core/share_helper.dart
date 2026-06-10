import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareAppApk(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing APK...'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    const platform = MethodChannel('com.test.flamehouse/apk_info');
    final String? apkPath = await platform.invokeMethod<String>('getApkPath');
    
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (apkPath != null && apkPath.isNotEmpty) {
      final env = dotenv.env['APP_ENV'] ?? 'dev';
      final version = dotenv.env['APP_VERSION'] ?? '1.0.0';
      final customName = 'flamehouse_${env}_$version.apk';
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$customName');
      await File(apkPath).copy(tempFile.path);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, mimeType: 'application/vnd.android.package-archive')],
          text: 'Flamehouse App APK',
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to locate the APK file.')),
        );
      }
    }
  } on PlatformException catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Native error: ${e.message}')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

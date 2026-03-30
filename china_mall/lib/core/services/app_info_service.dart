import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static PackageInfo? _info;

  static Future<void> init() async {
    try {
      _info = await PackageInfo.fromPlatform();
    } catch (_) {
      // Web: PackageInfo returns empty strings
    }
  }

  static String get version     => _info?.version ?? '1.0.0';
  static String get buildNumber => _info?.buildNumber ?? '1';
  static String get appName     => _info?.appName ?? 'China Stall Market Place';
  static String get packageName => _info?.packageName ?? 'com.chinastall.app';

  static String get fullVersion => '$version+$buildNumber';
  static String get platform    => kIsWeb ? 'Web' : defaultTargetPlatform.name;

  static String get userAgent =>
      'China Stall Market Place/$version ($platform; Build/$buildNumber)';
}

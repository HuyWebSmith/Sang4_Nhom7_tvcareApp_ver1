import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config_URL {
  static String get baseUrl {
    String url = dotenv.maybeGet('BASE_URL')?.trim() ?? "";
    // Xóa dấu / ở cuối nếu có
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String buildUrl(String endpoint) {
    String base = baseUrl;
    String cleanEndpoint = endpoint.trim();

    // 1. Nếu endpoint bắt đầu bằng "/" thì xóa đi
    if (cleanEndpoint.startsWith('/')) {
      cleanEndpoint = cleanEndpoint.substring(1);
    }

    // 2. Xử lý lỗi "api/api": Nếu base kết thúc bằng "/api" và endpoint bắt đầu bằng "api/"
    if (base.endsWith('/api') && cleanEndpoint.startsWith('api/')) {
      cleanEndpoint = cleanEndpoint.substring(4); 
    }

    return "$base/$cleanEndpoint";
  }
}

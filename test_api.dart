import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://zo1backend.vercel.app/equipment');
  final response = await http.get(url);
  final data = jsonDecode(response.body);
  final items = data['data'] as List;
  
  for (int i = 0; i < items.length; i++) {
    print("Equipment ${items[i]['listing_title']}");
    final specStr = items[i]['specifications'];
    if (specStr != null) {
      final specs = specStr is String ? jsonDecode(specStr) : specStr;
      print("  includedAccessories: ${specs['includedAccessories']}");
      print("  featureTags: ${specs['featureTags']}");
    }
  }
}

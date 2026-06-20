import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'http://13.232.186.222:5000/manpower';
  final response = await http.get(Uri.parse(url));
  final data = jsonDecode(response.body);
  print('Manpower items: ${data['data'].length}');
  if (data['data'].length > 0) {
    for (var i = 0; i < data['data'].length; i++) {
      final item = data['data'][i];
      print('Item $i: ${item['listing_title']}');
      print('  Specifications: ${item['specifications']}');
      print('  Manpower/Amenities in DB: ${item['manpower'] ?? item['amenities']}');
    }
  }
}

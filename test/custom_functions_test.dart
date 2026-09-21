import 'package:flutter_test/flutter_test.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart';

void main() {
  group('getProxyUrl Tests', () {
    const placeholderUrl = 'https://images.weserv.nl/?url=https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg&w=300';

    test('Should return placeholder for null or empty URL (RED step)', () {
      expect(getProxyUrl(null), placeholderUrl);
      expect(getProxyUrl(''), placeholderUrl);
    });

    test('Should return original URL when provided', () {
      const complexUrl = 'https://example.com/image with spaces & symbols.jpg?q=1';
      final result = getProxyUrl(complexUrl);
      
      expect(result, equals(complexUrl));
    });
  });
}

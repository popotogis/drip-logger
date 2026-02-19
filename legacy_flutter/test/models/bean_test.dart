import 'package:flutter_test/flutter_test.dart';
import 'package:drip_logger/models/bean.dart';

void main() {
  group('Bean Model Tests', () {
    test('should encode/decode correctly', () {
      final originalBean = Bean(
          id: 'DMC-12',
          name: 'time machine',
          roaster: 'Dr.Emmett Roaster',
          roastLevel: 'Light',
          origin: 'Hill Varrey',
          lastUsed: DateTime(2015, 10, 21, 16, 29));

      // 変換
      final jsonMap = originalBean.toJson();
      final decodedBean = Bean.fromJson(jsonMap);

      // 検証
      expect(decodedBean.id, originalBean.id);
      expect(decodedBean.name, originalBean.name);
      expect(decodedBean.roaster, originalBean.roaster);
      expect(decodedBean.roastLevel, originalBean.roastLevel);
      expect(decodedBean.origin, originalBean.origin);

      expect(decodedBean.lastUsed.toIso8601String(),
          originalBean.lastUsed.toIso8601String());
    });

    test('should support advanced fields (process, variety, roastDate)', () {
      final advancedBean = Bean(
        id: 'adv-1',
        name: 'Geisha Village',
        // Compile Error Expected Here
        process: 'Natural',
        variety: 'Geisha',
        roastDate: DateTime(2023, 12, 1),
      );

      final json = advancedBean.toJson();
      final decoded = Bean.fromJson(json);

      expect(decoded.process, 'Natural');
      expect(decoded.variety, 'Geisha');
      expect(decoded.roastDate, DateTime(2023, 12, 1));
    });
  });
}

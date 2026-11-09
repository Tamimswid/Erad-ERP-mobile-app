import 'package:erad/features/cities/data/models/city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityModel.fromMap', () {
    test('tüm alanları okur', () {
      final city = CityModel.fromMap(const {
        'id': 'city-1',
        'name': 'İstanbul',
        'is_active': false,
      });

      expect(city.id, 'city-1');
      expect(city.name, 'İstanbul');
      expect(city.isActive, isFalse);
    });

    test('eksik alanlarda varsayılanları kullanır', () {
      final city = CityModel.fromMap(const {});

      expect(city.id, isEmpty);
      expect(city.name, isEmpty);
      expect(city.isActive, isTrue);
    });
  });

  group('CityModel.toMap', () {
    test('yalnızca yazılabilir alanları içerir', () {
      const city = CityModel(id: 'city-1', name: 'Ankara', isActive: false);

      expect(city.toMap(), {'name': 'Ankara', 'is_active': false});
    });
  });

  test('eşitlik değerlere göre çalışır', () {
    const city = CityModel(id: 'city-1', name: 'İzmir');

    expect(city, const CityModel(id: 'city-1', name: 'İzmir'));
    expect(city, isNot(const CityModel(id: 'city-1', name: 'Bursa')));
  });
}

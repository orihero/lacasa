/// Shared JSON fixtures for lib/api/ tests.
library;

Map<String, dynamic> fullAdJson({
  String type = 'residential',
  String category = 'sale',
  String stage = '1',
  String? repairment = 'good',
  String? furniture = 'withFurniture',
}) {
  return {
    'id': 'ad-1',
    'title': 'Sunny 2-room flat',
    'city': 'Tashkent',
    'district': 'Yunusabad',
    'address': 'Amir Temur 1',
    'reference': 'REF-1',
    'type': type,
    'category': category,
    'repairment': ?repairment,
    'rooms': 2,
    'area': 54.5,
    'storey': 3,
    'floors': 9,
    'furniture': ?furniture,
    'hashtags': '#flat',
    'price': 100000,
    'priceType': 'usd',
    'stage': stage,
    'description': 'Nice flat',
    'nearPlacesList': ['metro', 'school'],
    'optionList': [
      {'key': 'balcony', 'value': 'yes'},
    ],
    'active': true,
    'lat': 41.31,
    'lng': 69.28,
    'tour3dLink': 'https://tour.example.com/ad-1',
    'agentId': 'agent-1',
    'coworkerId': '',
    'photos': ['https://cdn.example.com/1.jpg'],
    'media': [
      {
        'url': 'https://cdn.example.com/1.jpg',
        'mediaType': 'photo',
        'position': 0,
      },
    ],
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000100},
  };
}

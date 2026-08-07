// Minimal wire-shaped Ad JSON builders for photo_gallery tests. Never
// depends on the bundled fixture file's exact contents — every field this
// feature cares about (photos, media) is set explicitly per test.

Map<String, dynamic> mediaJson({
  required String url,
  required String mediaType,
  required int position,
}) {
  return {'url': url, 'mediaType': mediaType, 'position': position};
}

Map<String, dynamic> adJson({
  String id = 'ad-1',
  String title = 'Test listing',
  List<String> photos = const [],
  List<Map<String, dynamic>> media = const [],
}) {
  return {
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': 'Yunusabad',
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': 'sale',
    'rooms': 3,
    'area': 60,
    'storey': 2,
    'floors': 9,
    'hashtags': null,
    'price': 100000,
    'priceType': 'usd',
    'stage': '1',
    'description': null,
    'nearPlacesList': <String>[],
    'optionList': null,
    'active': true,
    'lat': null,
    'lng': null,
    'tour3dLink': null,
    'agentId': 'agent-1',
    'coworkerId': '',
    'photos': photos,
    'media': media,
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  };
}

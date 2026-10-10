class PersonalAlbum {
  const PersonalAlbum(
      {required this.id,
      required this.name,
      required this.trackIds,
      this.archived = false});
  final String id;
  final String name;
  final List<String> trackIds;
  final bool archived;

  Map<String, Object> toJson() =>
      {'id': id, 'name': name, 'trackIds': trackIds, 'archived': archived};

  static PersonalAlbum? fromJson(Object? value) {
    if (value is! Map ||
        value['id'] is! String ||
        value['name'] is! String ||
        value['trackIds'] is! List) {
      return null;
    }
    return PersonalAlbum(
        id: value['id'] as String,
        name: value['name'] as String,
        archived: value['archived'] == true,
        trackIds: List.unmodifiable(
            (value['trackIds'] as List).whereType<String>().toSet()));
  }
}

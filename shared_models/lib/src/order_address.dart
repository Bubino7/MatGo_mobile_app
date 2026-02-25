/// Adresa pre objednávku (doručenie alebo vyzdvihnutie). Ukladá sa ako map v Firestore.
class OrderAddress {
  OrderAddress({
    required this.street,
    required this.city,
    required this.zip,
    this.country = 'SK',
    this.note,
  });

  final String street;
  final String city;
  final String zip;
  final String country;
  final String? note;

  Map<String, dynamic> toMap() => {
        'street': street,
        'city': city,
        'zip': zip,
        'country': country,
        if (note != null && note!.isNotEmpty) 'note': note,
        'formatted': formatted,
      };

  static OrderAddress fromMap(Map<String, dynamic>? map) {
    if (map == null) return OrderAddress(street: '', city: '', zip: '');
    return OrderAddress(
      street: (map['street'] as String?) ?? '',
      city: (map['city'] as String?) ?? '',
      zip: (map['zip'] as String?) ?? '',
      country: (map['country'] as String?) ?? 'SK',
      note: map['note'] as String?,
    );
  }

  /// Jedna riadka na zobrazenie (ulica, PSČ mesto).
  String get displayLine => '$street, $zip $city${country != 'SK' ? ', $country' : ''}';

  /// Celá adresa ako jeden reťazec pre uloženie a zobrazenie (napr. navigácia, tlač).
  String get formatted {
    final base = '$street, $zip $city${country != 'SK' ? ', $country' : ''}';
    if (note != null && note!.trim().isNotEmpty) return '$base ($note)';
    return base;
  }
}

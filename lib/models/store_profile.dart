class StoreProfile {
  String storeName;
  String storeAddress;
  String storePhone;
  String? logoPath;
  double logoSize;
  String footerLine1;
  String footerLine2;
  String footerLine3;
  String footerLine4;
  String footerLine5;
  String footerLine6;

  StoreProfile({
    this.storeName = 'solosfly.id',
    this.storeAddress = 'dk.krangkungan 03/08 pondok, grogol sukoharjo jawa tengah',
    this.storePhone = 'Hp/Telp.: 085779465493',
    this.logoPath,
    this.logoSize = 80.0,
    this.footerLine1 = 'payment An.Diyah Permatasari/Diestories',
    this.footerLine2 = 'SOLOSFLY.ID',
    this.footerLine3 = 'Terima kasih telah berbelanja di toko kami.',
    this.footerLine4 = 'Kepercayaan dan dukunganmu sangat berarti bagi kami.',
    this.footerLine5 = 'sampai jumpa di pesanan berikutnya!',
    this.footerLine6 = 'Dengan cinta, Solosfly.id by Dies \u2661',
  });

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'storeAddress': storeAddress,
      'storePhone': storePhone,
      'logoPath': logoPath,
      'logoSize': logoSize,
      'footerLine1': footerLine1,
      'footerLine2': footerLine2,
      'footerLine3': footerLine3,
      'footerLine4': footerLine4,
      'footerLine5': footerLine5,
      'footerLine6': footerLine6,
    };
  }

  factory StoreProfile.fromMap(Map<String, dynamic> map) {
    return StoreProfile(
      storeName: map['storeName'] ?? 'solosfly.id',
      storeAddress: map['storeAddress'] ?? 'dk.krangkungan 03/08 pondok, grogol sukoharjo jawa tengah',
      storePhone: map['storePhone'] ?? 'Hp/Telp.: 085779465493',
      logoPath: map['logoPath'],
      logoSize: (map['logoSize'] as num?)?.toDouble() ?? 80.0,
      footerLine1: map['footerLine1'] ?? 'payment An.Diyah Permatasari/Diestories',
      footerLine2: map['footerLine2'] ?? 'SOLOSFLY.ID',
      footerLine3: map['footerLine3'] ?? 'Terima kasih telah berbelanja di toko kami.',
      footerLine4: map['footerLine4'] ?? 'Kepercayaan dan dukunganmu sangat berarti bagi kami.',
      footerLine5: map['footerLine5'] ?? 'sampai jumpa di pesanan berikutnya!',
      footerLine6: map['footerLine6'] ?? 'Dengan cinta, Solosfly.id by Dies \u2661',
    );
  }

  StoreProfile copyWith({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? logoPath,
    double? logoSize,
    String? footerLine1,
    String? footerLine2,
    String? footerLine3,
    String? footerLine4,
    String? footerLine5,
    String? footerLine6,
  }) {
    return StoreProfile(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      logoPath: logoPath ?? this.logoPath,
      logoSize: logoSize ?? this.logoSize,
      footerLine1: footerLine1 ?? this.footerLine1,
      footerLine2: footerLine2 ?? this.footerLine2,
      footerLine3: footerLine3 ?? this.footerLine3,
      footerLine4: footerLine4 ?? this.footerLine4,
      footerLine5: footerLine5 ?? this.footerLine5,
      footerLine6: footerLine6 ?? this.footerLine6,
    );
  }
}

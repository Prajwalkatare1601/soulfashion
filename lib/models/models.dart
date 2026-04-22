class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
  }
}

class Measurement {
  final String id;
  final String customerId;
  final String? chest;
  final String? waist;
  final String? shoulder;
  final String? sleeve;
  final DateTime updatedAt;

  Measurement({
    required this.id,
    required this.customerId,
    this.chest,
    this.waist,
    this.shoulder,
    this.sleeve,
    required this.updatedAt,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      chest: json['chest'] as String?,
      waist: json['waist'] as String?,
      shoulder: json['shoulder'] as String?,
      sleeve: json['sleeve'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      if (chest != null) 'chest': chest,
      if (waist != null) 'waist': waist,
      if (shoulder != null) 'shoulder': shoulder,
      if (sleeve != null) 'sleeve': sleeve,
    };
  }
}

class Scribble {
  final String id;
  final String customerId;
  final String imageUrl;
  final DateTime createdAt;

  Scribble({
    required this.id,
    required this.customerId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Scribble.fromJson(Map<String, dynamic> json) {
    return Scribble(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'image_url': imageUrl,
    };
  }
}

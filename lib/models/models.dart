enum OrderStatus {
  ordered,
  completed,
  delivered;

  String get label {
    switch (this) {
      case OrderStatus.ordered:
        return 'Ordered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  static OrderStatus fromString(String? value) {
    switch (value) {
      case 'completed':
        return OrderStatus.completed;
      case 'delivered':
        return OrderStatus.delivered;
      case 'ordered':
      default:
        return OrderStatus.ordered;
    }
  }
}

enum OrderType {
  stitching,
  handEmbroidery,
  both;

  String get label {
    switch (this) {
      case OrderType.stitching:
        return 'Stitching';
      case OrderType.handEmbroidery:
        return 'Hand Embroidery';
      case OrderType.both:
        return 'Both';
    }
  }

  static OrderType fromString(String? value) {
    switch (value) {
      case 'hand_embroidery':
      case 'handEmbroidery':
        return OrderType.handEmbroidery;
      case 'both':
        return OrderType.both;
      case 'stitching':
      default:
        return OrderType.stitching;
    }
  }
}

class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final OrderStatus orderStatus;
  final OrderType orderType;
  final DateTime createdAt;
  final DateTime? dueDate;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
    this.orderStatus = OrderStatus.ordered,
    this.orderType = OrderType.stitching,
    required this.createdAt,
    this.dueDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      orderStatus: OrderStatus.fromString(json['order_status'] as String?),
      orderType: OrderType.fromString(json['order_type'] as String?),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl,
      'order_status': orderStatus.name,
      'order_type': orderType.name,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
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
  final String? thigh;
  final String? inseam;
  final String? length;
  final DateTime updatedAt;

  Measurement({
    required this.id,
    required this.customerId,
    this.chest,
    this.waist,
    this.shoulder,
    this.sleeve,
    this.thigh,
    this.inseam,
    this.length,
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
      thigh: json['thigh'] as String?,
      inseam: json['inseam'] as String?,
      length: json['length'] as String?,
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
      if (thigh != null) 'thigh': thigh,
      if (inseam != null) 'inseam': inseam,
      if (length != null) 'length': length,
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

class ReferencePhoto {
  final String id;
  final String customerId;
  final String imageUrl;
  final DateTime createdAt;

  ReferencePhoto({
    required this.id,
    required this.customerId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory ReferencePhoto.fromJson(Map<String, dynamic> json) {
    return ReferencePhoto(
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

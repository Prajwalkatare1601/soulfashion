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

  // Upper body
  final String? upperLength;
  final String? chest;
  final String? upperChest;
  final String? point;
  final String? upperWaist;
  final String? sleeve;
  final String? shoulder;
  final String? slit;
  final String? upperHip;
  final String? lowerHip;
  final String? frontNeck;
  final String? backNeck;
  final String? backBoard;
  final String? arm;
  final String? side;

  // Bottom body
  final String? lowerLength;
  final String? lowerWaist;
  final String? bottomHip;
  final String? thigh;
  final String? knee;
  final String? crotch;
  final String? bottom;

  // Full body
  final String? fullLength;
  final String? yoke;

  // Legacy columns (retained for database compatibility)
  final String? waist;
  final String? inseam;
  final String? length;

  final Map<String, dynamic> customValues;
  final DateTime updatedAt;

  Measurement({
    required this.id,
    required this.customerId,
    this.upperLength,
    this.chest,
    this.upperChest,
    this.point,
    this.upperWaist,
    this.sleeve,
    this.shoulder,
    this.slit,
    this.upperHip,
    this.lowerHip,
    this.frontNeck,
    this.backNeck,
    this.backBoard,
    this.arm,
    this.side,
    this.lowerLength,
    this.lowerWaist,
    this.bottomHip,
    this.thigh,
    this.knee,
    this.crotch,
    this.bottom,
    this.fullLength,
    this.yoke,
    this.waist,
    this.inseam,
    this.length,
    this.customValues = const {},
    required this.updatedAt,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      upperLength: json['upper_length'] as String?,
      chest: json['chest'] as String?,
      upperChest: json['upper_chest'] as String?,
      point: json['point'] as String?,
      upperWaist: json['upper_waist'] as String?,
      sleeve: json['sleeve'] as String?,
      shoulder: json['shoulder'] as String?,
      slit: json['slit'] as String?,
      upperHip: json['upper_hip'] as String?,
      lowerHip: json['lower_hip'] as String?,
      frontNeck: json['front_neck'] as String?,
      backNeck: json['back_neck'] as String?,
      backBoard: json['back_board'] as String?,
      arm: json['arm'] as String?,
      side: json['side'] as String?,
      lowerLength: json['lower_length'] as String?,
      lowerWaist: json['lower_waist'] as String?,
      bottomHip: json['bottom_hip'] as String?,
      thigh: json['thigh'] as String?,
      knee: json['knee'] as String?,
      crotch: json['crotch'] as String?,
      bottom: json['bottom'] as String?,
      fullLength: json['full_length'] as String?,
      yoke: json['yoke'] as String?,
      waist: json['waist'] as String?,
      inseam: json['inseam'] as String?,
      length: json['length'] as String?,
      customValues: json['custom_values'] as Map<String, dynamic>? ?? {},
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      if (upperLength != null) 'upper_length': upperLength,
      if (chest != null) 'chest': chest,
      if (upperChest != null) 'upper_chest': upperChest,
      if (point != null) 'point': point,
      if (upperWaist != null) 'upper_waist': upperWaist,
      if (sleeve != null) 'sleeve': sleeve,
      if (shoulder != null) 'shoulder': shoulder,
      if (slit != null) 'slit': slit,
      if (upperHip != null) 'upper_hip': upperHip,
      if (lowerHip != null) 'lower_hip': lowerHip,
      if (frontNeck != null) 'front_neck': frontNeck,
      if (backNeck != null) 'back_neck': backNeck,
      if (backBoard != null) 'back_board': backBoard,
      if (arm != null) 'arm': arm,
      if (side != null) 'side': side,
      if (lowerLength != null) 'lower_length': lowerLength,
      if (lowerWaist != null) 'lower_waist': lowerWaist,
      if (bottomHip != null) 'bottom_hip': bottomHip,
      if (thigh != null) 'thigh': thigh,
      if (knee != null) 'knee': knee,
      if (crotch != null) 'crotch': crotch,
      if (bottom != null) 'bottom': bottom,
      if (fullLength != null) 'full_length': fullLength,
      if (yoke != null) 'yoke': yoke,
      if (waist != null) 'waist': waist,
      if (inseam != null) 'inseam': inseam,
      if (length != null) 'length': length,
      'custom_values': customValues,
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

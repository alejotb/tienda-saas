// Automatic FlutterFlow imports
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class WooCategoryDto {
  final int id;
  final String name;
  final String? image;
  final int? parentId;

  WooCategoryDto({
    required this.id,
    required this.name,
    this.image,
    this.parentId,
  });

  factory WooCategoryDto.fromJson(Map<String, dynamic> json) {
    return WooCategoryDto(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Sin nombre',
      image: (json['image'] != null && json['image']['src'] != null) 
          ? json['image']['src'] as String 
          : null,
      parentId: json['parent'] as int?,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id_woo': id,
      'nombre': name,
      'photo_path': image,
      'parent_id': parentId,
    };
  }
}

class WooOrderDto {
  final int id;
  final double total;
  final String status;
  final String customerName;
  final String customerEmail;
  final String dateCreated;

  WooOrderDto({
    required this.id,
    required this.total,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.dateCreated,
  });

  factory WooOrderDto.fromJson(Map<String, dynamic> json) {
    final String totalRaw = json['total']?.toString() ?? "0.0";
    final Map<String, dynamic> billing = json['billing'] ?? {};
    
    return WooOrderDto(
      id: json['id'] as int,
      total: double.tryParse(totalRaw) ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      customerName: "${billing['first_name'] ?? 'Invitado'} ${billing['last_name'] ?? ''}".trim(),
      customerEmail: billing['email']?.toString() ?? 'sin@email.com',
      dateCreated: json['date_created']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id_woo': id,
      'nombre_cliente': customerName,
      'email_cliente': customerEmail,
      'total': total,
      'estado': status,
      'fecha_creacion': dateCreated,
    };
  }
}

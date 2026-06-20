import 'dart:convert';

class ListingModel {
  final String id;
  final String vendorId;
  final String listingTitle;
  final String? shortDescription;
  final String category;
  final String subCategory;
  final String? detailedDescription;
  final int? capacity;
  final int? areaSqft;
  final double? pricePerHour;
  final double? pricePerDay;
  final int? minimumBookingHours;
  final List<String> amenities;
  final List<String> equipments;
  final List<String> manpower;
  final String? cancellationPolicy;
  final String? rules;
  final List<String> images;
  final String status;
  final double avgRating;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final String? vendorName;
  final String? openingTime;
  final String? closingTime;
  final String? brand;
  final String? model;
  final int? quantity;
  final double? depositAmount;
  final List<String>? blockedDates;

  ListingModel({
    required this.id,
    required this.vendorId,
    required this.listingTitle,
    this.shortDescription,
    required this.category,
    required this.subCategory,
    this.detailedDescription,
    this.capacity,
    this.areaSqft,
    this.pricePerHour,
    this.pricePerDay,
    this.minimumBookingHours,
    required this.amenities,
    this.equipments = const [],
    this.manpower = const [],
    this.cancellationPolicy,
    this.rules,
    required this.images,
    required this.status,
    required this.avgRating,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.vendorName,
    this.openingTime,
    this.closingTime,
    this.brand,
    this.model,
    this.quantity,
    this.depositAmount,
    this.blockedDates,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    // Parse images from image_1 to image_5
    List<String> parsedImages = [];
    for (int i = 1; i <= 5; i++) {
      final img = json['image_$i'];
      if (img != null && img.toString().isNotEmpty) {
        parsedImages.add(img.toString());
      }
    }

    // Parse amenities
    List<String> parsedAmenities = [];
    if (json['amenities'] is List) {
      parsedAmenities = List<String>.from(json['amenities'].map((e) => e.toString()));
    }

    // Parse equipments
    List<String> parsedEquipments = [];
    if (json['equipments'] is List) {
      parsedEquipments = List<String>.from(json['equipments'].map((e) => e.toString()));
    }

    // Parse manpower
    List<String> parsedManpower = [];
    if (json['manpower'] is List) {
      parsedManpower = List<String>.from(json['manpower'].map((e) => e.toString()));
    }

    // Parse blocked dates
    List<String>? parsedBlockedDates;
    if (json['blocked_dates'] is List) {
      parsedBlockedDates = List<String>.from(json['blocked_dates'].map((e) => e.toString()));
    }

    // Parse specifications for accessories and services
    Map<String, dynamic>? parsedSpecs;
    if (json['specifications'] != null) {
      if (json['specifications'] is Map) {
        parsedSpecs = Map<String, dynamic>.from(json['specifications'] as Map);
      } else if (json['specifications'] is String) {
        try {
          parsedSpecs = Map<String, dynamic>.from(jsonDecode(json['specifications']) as Map);
        } catch (e) {
          print("Error decoding specifications: $e");
        }
      }
    }

    if (parsedSpecs != null) {
      if (parsedSpecs['includedAccessories'] is List) {
        final accList = parsedSpecs['includedAccessories'] as List;
        for (var item in accList) {
          final s = item.toString();
          if (!parsedEquipments.contains(s)) parsedEquipments.add(s);
        }
      }
      
      if (parsedSpecs['featureTags'] is List) {
        final fList = parsedSpecs['featureTags'] as List;
        for (var item in fList) {
          final s = item.toString();
          if (!parsedEquipments.contains(s)) parsedEquipments.add(s);
        }
      }
      if (parsedSpecs['includedServices'] is List) {
        final srvList = parsedSpecs['includedServices'] as List;
        for (var item in srvList) {
          final s = item.toString();
          if (!parsedManpower.contains(s)) parsedManpower.add(s);
        }
      }
    }

    return ListingModel(
      id: json['id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      listingTitle: json['listing_title']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      category: json['category']?.toString() ?? '',
      subCategory: json['sub_category']?.toString() ?? '',
      detailedDescription: json['detailed_description']?.toString(),
      capacity: json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity']?.toString() ?? ''),
      areaSqft: json['area_sqft'] is int ? json['area_sqft'] : int.tryParse(json['area_sqft']?.toString() ?? ''),
      pricePerHour: json['price_per_hour'] != null ? double.tryParse(json['price_per_hour'].toString()) : null,
      pricePerDay: json['price_per_day'] != null ? double.tryParse(json['price_per_day'].toString()) : (json['price'] != null ? double.tryParse(json['price'].toString()) : null),
      minimumBookingHours: json['minimum_booking_hours'] is int ? json['minimum_booking_hours'] : int.tryParse(json['minimum_booking_hours']?.toString() ?? ''),
      amenities: parsedAmenities,
      equipments: parsedEquipments,
      manpower: parsedManpower,
      cancellationPolicy: json['cancellation_policy']?.toString(),
      rules: json['rules']?.toString(),
      images: parsedImages,
      status: json['status']?.toString() ?? 'active',
      avgRating: double.tryParse(json['avg_rating']?.toString() ?? '0') ?? 0.0,
      locationAddress: json['location_address']?.toString(),
      latitude: (json['location_lat'] ?? json['latitude']) != null ? double.tryParse((json['location_lat'] ?? json['latitude']).toString()) : null,
      longitude: (json['location_lng'] ?? json['longitude']) != null ? double.tryParse((json['location_lng'] ?? json['longitude']).toString()) : null,
      vendorName: json['vendor_name']?.toString(),
      openingTime: json['opening_time']?.toString(),
      closingTime: json['closing_time']?.toString(),
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? ''),
      depositAmount: json['deposit_amount'] != null ? double.tryParse(json['deposit_amount'].toString()) : null,
      blockedDates: parsedBlockedDates,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'vendor_id': vendorId,
      'listing_title': listingTitle,
      'short_description': shortDescription,
      'category': category,
      'sub_category': subCategory,
      'detailed_description': detailedDescription,
      'capacity': capacity,
      'area_sqft': areaSqft,
      'price_per_hour': pricePerHour,
      'price_per_day': pricePerDay,
      'minimum_booking_hours': minimumBookingHours,
      'amenities': amenities,
      'equipments': equipments,
      'manpower': manpower,
      'cancellation_policy': cancellationPolicy,
      'rules': rules,
      'status': status,
      'avg_rating': avgRating,
      'location_address': locationAddress,
      'location_lat': latitude,
      'location_lng': longitude,
      'vendor_name': vendorName,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'brand': brand,
      'model': model,
      'quantity': quantity,
      'deposit_amount': depositAmount,
      'blocked_dates': blockedDates,
    };
    
    // Add images back in format image_1, image_2, etc.
    for (int i = 0; i < images.length; i++) {
      data['image_${i + 1}'] = images[i];
    }
    
    return data;
  }
}

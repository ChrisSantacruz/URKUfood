import 'dart:typed_data';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.priceRange,
    required this.rating,
    required this.deliveryTime,
    required this.logoAsset,
    required this.bannerAssets,
    required this.contactName,
    required this.contactPhotoAsset,
    required this.instagram,
    required this.facebook,
    required this.phone,
    required this.address,
    required this.description,
    required this.tags,
    required this.mapX,
    required this.mapY,
    required this.latitude,
    required this.longitude,
    this.isHot = false,
  });

  final int id;
  final String name;
  final String cuisine;
  final String priceRange;
  final double rating;
  final String deliveryTime;
  final String logoAsset;
  final List<String> bannerAssets;
  final String contactName;
  final String contactPhotoAsset;
  final String instagram;
  final String facebook;
  final String phone;
  final String address;
  final String description;
  final List<String> tags;
  final double mapX;
  final double mapY;
  final double latitude;
  final double longitude;
  final bool isHot;
}

class PromoCampaign {
  const PromoCampaign({
    required this.id,
    required this.restaurantId,
    required this.imageAsset,
    required this.title,
    required this.description,
  });

  final int id;
  final int restaurantId;
  final String imageAsset;
  final String title;
  final String description;
}

class RecommendedDish {
  const RecommendedDish({
    required this.id,
    required this.restaurantId,
    required this.dishName,
    required this.imageAsset,
    required this.price,
    required this.restaurantName,
    required this.description,
  });

  final int id;
  final int restaurantId;
  final String dishName;
  final String imageAsset;
  final double price;
  final String restaurantName;
  final String description;
}

class MenuItemModel {
  const MenuItemModel({
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.description,
    required this.coverImage,
    required this.galleryImages,
    required this.ingredients,
    required this.calories,
    required this.prepTime,
    required this.customizations,
  });

  final int restaurantId;
  final String name;
  final double price;
  final String description;
  final String coverImage;
  final List<String> galleryImages;
  final List<String> ingredients;
  final String calories;
  final String prepTime;
  final List<String> customizations;
}

class TriviaQuestion {
  const TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
}

class Achievement {
  const Achievement({
    required this.name,
    required this.description,
    this.unlocked = false,
  });

  final String name;
  final String description;
  final bool unlocked;

  Achievement copyWith({bool? unlocked}) {
    return Achievement(
      name: name,
      description: description,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}

class RewardChallenge {
  const RewardChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    this.completed = false,
  });

  final String id;
  final String title;
  final String description;
  final int points;
  final bool completed;

  RewardChallenge copyWith({bool? completed}) {
    return RewardChallenge(
      id: id,
      title: title,
      description: description,
      points: points,
      completed: completed ?? this.completed,
    );
  }
}

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.details,
    this.isPrimary = false,
  });

  final String id;
  final String label;
  final String address;
  final String details;
  final bool isPrimary;

  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    String? details,
    bool? isPrimary,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      details: details ?? this.details,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'details': details,
      'isPrimary': isPrimary,
    };
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Dirección',
      address: json['address'] as String? ?? '',
      details: json['details'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class CartItem {
  const CartItem({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String id;
  final int restaurantId;
  final String restaurantName;
  final String name;
  final double price;
  final int quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String? ?? '',
      restaurantId: (json['restaurantId'] as num?)?.toInt() ?? 0,
      restaurantName: json['restaurantName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

enum OrderStatus { confirmed, preparing, onTheWay, delivered }

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.orderCode,
    required this.createdAt,
    required this.items,
    required this.restaurantNames,
    required this.itemCount,
    required this.status,
    required this.paymentMethod,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryInstructions,
    required this.paymentReference,
    this.paymentProofLabel,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.smallOrderFee,
    required this.discount,
    required this.etaLabel,
    required this.total,
  });

  final String id;
  final String orderCode;
  final DateTime createdAt;
  final List<CartItem> items;
  final List<String> restaurantNames;
  final int itemCount;
  final OrderStatus status;
  final PaymentMethodType paymentMethod;
  final String customerPhone;
  final String deliveryAddress;
  final String deliveryInstructions;
  final String paymentReference;
  final String? paymentProofLabel;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double smallOrderFee;
  final double discount;
  final String etaLabel;
  final double total;

  OrderRecord copyWith({OrderStatus? status}) {
    return OrderRecord(
      id: id,
      orderCode: orderCode,
      createdAt: createdAt,
      items: items,
      restaurantNames: restaurantNames,
      itemCount: itemCount,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      paymentReference: paymentReference,
      paymentProofLabel: paymentProofLabel,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      smallOrderFee: smallOrderFee,
      discount: discount,
      etaLabel: etaLabel,
      total: total,
    );
  }
}

class ChatEntry {
  const ChatEntry({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  final String message;
  final bool isUser;
  final DateTime timestamp;
}

enum AppNotificationType { order, social, restaurant, system }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isUnread = true,
  });

  final String id;
  final String title;
  final String message;
  final AppNotificationType type;
  final DateTime createdAt;
  final bool isUnread;

  AppNotification copyWith({bool? isUnread}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}

class SocialClip {
  const SocialClip({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.durationLabel,
    required this.viewsLabel,
    required this.likesLabel,
    required this.commentsLabel,
    this.durationSeconds = 30,
    this.likedByCurrentUser = false,
    this.mediaBytes,
    this.mediaLabel,
  });

  final String id;
  final int restaurantId;
  final String title;
  final String author;
  final String coverImage;
  final String durationLabel;
  final String viewsLabel;
  final String likesLabel;
  final String commentsLabel;
  final int durationSeconds;
  final bool likedByCurrentUser;
  final Uint8List? mediaBytes;
  final String? mediaLabel;

  SocialClip copyWith({
    String? author,
    String? likesLabel,
    String? commentsLabel,
    bool? likedByCurrentUser,
  }) {
    return SocialClip(
      id: id,
      restaurantId: restaurantId,
      title: title,
      author: author ?? this.author,
      coverImage: coverImage,
      durationLabel: durationLabel,
      viewsLabel: viewsLabel,
      likesLabel: likesLabel ?? this.likesLabel,
      commentsLabel: commentsLabel ?? this.commentsLabel,
      durationSeconds: durationSeconds,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      mediaBytes: mediaBytes,
      mediaLabel: mediaLabel,
    );
  }
}

class FoodPost {
  const FoodPost({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.author,
    required this.authorRole,
    required this.imageAsset,
    required this.caption,
    required this.likesLabel,
    required this.commentsLabel,
    required this.tags,
    this.authorImageBytes,
    this.featuredDishName,
    this.isVerifiedOrder = false,
    this.likedByCurrentUser = false,
    this.mediaBytes,
    this.mediaLabel,
  });

  final String id;
  final int restaurantId;
  final String restaurantName;
  final String author;
  final String authorRole;
  final String imageAsset;
  final String caption;
  final String likesLabel;
  final String commentsLabel;
  final List<String> tags;
  final Uint8List? authorImageBytes;
  final String? featuredDishName;
  final bool isVerifiedOrder;
  final bool likedByCurrentUser;
  final Uint8List? mediaBytes;
  final String? mediaLabel;

  FoodPost copyWith({
    String? author,
    String? authorRole,
    String? likesLabel,
    String? commentsLabel,
    Uint8List? authorImageBytes,
    bool clearAuthorImage = false,
    bool? likedByCurrentUser,
  }) {
    return FoodPost(
      id: id,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      author: author ?? this.author,
      authorRole: authorRole ?? this.authorRole,
      imageAsset: imageAsset,
      caption: caption,
      likesLabel: likesLabel ?? this.likesLabel,
      commentsLabel: commentsLabel ?? this.commentsLabel,
      tags: tags,
        authorImageBytes: clearAuthorImage
          ? null
          : (authorImageBytes ?? this.authorImageBytes),
      featuredDishName: featuredDishName,
      isVerifiedOrder: isVerifiedOrder,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      mediaBytes: mediaBytes,
      mediaLabel: mediaLabel,
    );
  }
}

class RestaurantComment {
  const RestaurantComment({
    required this.id,
    required this.restaurantId,
    required this.author,
    required this.handle,
    required this.message,
    required this.timeLabel,
    required this.likesLabel,
    this.likedByCurrentUser = false,
  });

  final String id;
  final int restaurantId;
  final String author;
  final String handle;
  final String message;
  final String timeLabel;
  final String likesLabel;
  final bool likedByCurrentUser;

  RestaurantComment copyWith({String? likesLabel, bool? likedByCurrentUser}) {
    return RestaurantComment(
      id: id,
      restaurantId: restaurantId,
      author: author,
      handle: handle,
      message: message,
      timeLabel: timeLabel,
      likesLabel: likesLabel ?? this.likesLabel,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
    );
  }
}

class DeliveryMapSnapshot {
  const DeliveryMapSnapshot({
    required this.title,
    required this.status,
    required this.eta,
    required this.courierName,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.progress,
  });

  final String title;
  final String status;
  final String eta;
  final String courierName;
  final String pickupLabel;
  final String dropoffLabel;
  final double progress;
}

enum PaymentMethodType { card, cash, wallet, instant, nequi, bankTransfer }

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.type,
    required this.label,
    required this.subtitle,
  });

  final PaymentMethodType type;
  final String label;
  final String subtitle;
}

class AvailabilityCheckItem {
  const AvailabilityCheckItem({
    required this.name,
    required this.quantity,
  });

  final String name;
  final int quantity;

  factory AvailabilityCheckItem.fromJson(Map<String, dynamic> json) {
    return AvailabilityCheckItem(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }
}

class AvailabilityRestaurantRequest {
  const AvailabilityRestaurantRequest({
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantPhone,
    required this.contactName,
    required this.items,
  });

  final String restaurantId;
  final String restaurantName;
  final String restaurantPhone;
  final String contactName;
  final List<AvailabilityCheckItem> items;

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantPhone': restaurantPhone,
      'contactName': contactName,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class AvailabilityCheckRestaurant {
  const AvailabilityCheckRestaurant({
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantPhone,
    required this.items,
    required this.state,
    required this.unavailableItemName,
    required this.unavailableIngredient,
    required this.note,
    required this.continueChosen,
  });

  final String restaurantId;
  final String restaurantName;
  final String restaurantPhone;
  final List<AvailabilityCheckItem> items;
  final String state;
  final String unavailableItemName;
  final String unavailableIngredient;
  final String note;
  final bool continueChosen;

  bool get isPending => state == 'pending';
  bool get isConfirmed => state == 'confirmed';
  bool get isDishUnavailable => state == 'dish_unavailable';
  bool get isIngredientUnavailable => state == 'ingredient_unavailable';
  bool get isError => state == 'error';
  bool get needsContinueDecision =>
      isIngredientUnavailable && !continueChosen;

  factory AvailabilityCheckRestaurant.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return AvailabilityCheckRestaurant(
      restaurantId: json['restaurantId'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? '',
      restaurantPhone: json['restaurantPhone'] as String? ?? '',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(AvailabilityCheckItem.fromJson)
          .toList(),
      state: json['state'] as String? ?? 'pending',
      unavailableItemName: json['unavailableItemName'] as String? ?? '',
      unavailableIngredient: json['unavailableIngredient'] as String? ?? '',
      note: json['note'] as String? ?? '',
      continueChosen: json['continueChosen'] as bool? ?? false,
    );
  }
}

class AvailabilityCheckSession {
  const AvailabilityCheckSession({
    required this.id,
    required this.status,
    required this.restaurants,
  });

  final String id;
  final String status;
  final List<AvailabilityCheckRestaurant> restaurants;

  bool get isPending => status == 'pending';
  bool get isReady => status == 'ready';
  bool get isBlocked => status == 'blocked';
  bool get isWhatsAppError => status == 'whatsapp_error';
  bool get needsUserAction => status == 'action_required';
  bool get isCancelled => status == 'cancelled';

  factory AvailabilityCheckSession.fromJson(Map<String, dynamic> json) {
    final rawRestaurants =
        json['restaurants'] as List<dynamic>? ?? const <dynamic>[];
    return AvailabilityCheckSession(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      restaurants: rawRestaurants
          .whereType<Map<String, dynamic>>()
          .map(AvailabilityCheckRestaurant.fromJson)
          .toList(),
    );
  }
}

class FoodCategory {
  const FoodCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.cuisines,
  });

  final String id;
  final String label;
  final String icon;
  final List<String> cuisines;
}

class MealWindow {
  const MealWindow({
    required this.id,
    required this.label,
    required this.headline,
    required this.startHour,
    required this.endHour,
    required this.restaurantIds,
  });

  final String id;
  final String label;
  final String headline;
  final int startHour;
  final int endHour;
  final List<int> restaurantIds;
}

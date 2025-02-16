import 'package:flutter/foundation.dart';

class RouteInfo {
  final double? angle;
  final bool? isBase;
  final String? groupId;
  final double? angleDifference;

  RouteInfo({
    this.angle,
    this.isBase,
    this.groupId,
    this.angleDifference,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      angle: json['angle'] != null ? (json['angle'] as num).toDouble() : null,
      isBase: json['is_base'] as bool?,
      groupId: json['group_id'] as String?,
      angleDifference: json['angle_difference'] != null ? (json['angle_difference'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (angle != null) 'angle': angle,
      if (isBase != null) 'is_base': isBase,
      if (groupId != null) 'group_id': groupId,
      if (angleDifference != null) 'angle_difference': angleDifference,
    };
  }
}

class CostBreakdown {
  final double? baseCost;
  final double? feeOrder;
  final double? pickupFee;

  CostBreakdown({
    this.baseCost,
    this.feeOrder,
    this.pickupFee,
  });

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    return CostBreakdown(
      baseCost: json['base_cost'] != null ? (json['base_cost'] as num).toDouble() : null,
      feeOrder: json['fee_order'] != null ? (json['fee_order'] as num).toDouble() : null,
      pickupFee: json['pickup_fee'] != null ? (json['pickup_fee'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (baseCost != null) 'base_cost': baseCost,
      if (feeOrder != null) 'fee_order': feeOrder,
      if (pickupFee != null) 'pickup_fee': pickupFee,
    };
  }
}

class MerchantDelivery {
  final int merchantId;
  final String merchantName;
  final double distance;
  final int? duration;
  final double cost;
  final String routeType;
  final RouteInfo routeInfo;
  final CostBreakdown costBreakdown;

  MerchantDelivery({
    required this.merchantId,
    required this.merchantName,
    required this.distance,
    this.duration,
    required this.cost,
    required this.routeType,
    required this.routeInfo,
    required this.costBreakdown,
  });

  factory MerchantDelivery.fromJson(Map<String, dynamic> json) {
    return MerchantDelivery(
      merchantId: json['merchant_id'] as int,
      merchantName: json['merchant_name'] as String,
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'] as int?,
      cost: (json['cost'] as num).toDouble(),
      routeType: json['route_type'] as String,
      routeInfo: RouteInfo.fromJson(json['route_info'] as Map<String, dynamic>),
      costBreakdown: CostBreakdown.fromJson(json['cost_breakdown'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_id': merchantId,
      'merchant_name': merchantName,
      'distance': distance,
      if (duration != null) 'duration': duration,
      'cost': cost,
      'route_type': routeType,
      'route_info': routeInfo.toJson(),
      'cost_breakdown': costBreakdown.toJson(),
    };
  }

  bool get isInDifferentDirection => routeType == 'different_direction';
  bool get isOnTheWay => routeType == 'on_the_way';
  bool get isBaseMerchant => routeType == 'base_merchant';
  bool get hasInvalidAngle => routeInfo.angle != null && routeInfo.angle! > 90;
}

class DirectionGroupMerchant {
  final String name;
  final double distance;
  final double cost;
  final CostBreakdown? breakdown;

  DirectionGroupMerchant({
    required this.name,
    required this.distance,
    required this.cost,
    this.breakdown,
  });

  factory DirectionGroupMerchant.fromJson(Map<String, dynamic> json) {
    return DirectionGroupMerchant(
      name: json['name'] as String,
      distance: (json['distance'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      breakdown: json['breakdown'] != null ? CostBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'distance': distance,
      'cost': cost,
      if (breakdown != null) 'breakdown': breakdown!.toJson(),
    };
  }
}

class DirectionGroupCostBreakdown {
  final DirectionGroupMerchant baseMerchant;
  final List<DirectionGroupMerchant> onTheWay;

  DirectionGroupCostBreakdown({
    required this.baseMerchant,
    required this.onTheWay,
  });

  factory DirectionGroupCostBreakdown.fromJson(Map<String, dynamic> json) {
    return DirectionGroupCostBreakdown(
      baseMerchant: DirectionGroupMerchant.fromJson(json['base_merchant'] as Map<String, dynamic>),
      onTheWay: (json['on_the_way'] as List? ?? [])
          .map((m) => DirectionGroupMerchant.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_merchant': baseMerchant.toJson(),
      'on_the_way': onTheWay.map((merchant) => merchant.toJson()).toList(),
    };
  }
}

class DirectionGroup {
  final String groupId;
  final double baseAngle;
  final List<String> merchants;
  final double totalCost;
  final DirectionGroupCostBreakdown costBreakdown;

  DirectionGroup({
    required this.groupId,
    required this.baseAngle,
    required this.merchants,
    required this.totalCost,
    required this.costBreakdown,
  });

  factory DirectionGroup.fromJson(Map<String, dynamic> json) {
    // Handle potentially missing or malformed merchants list
    List<String> merchantsList = [];
    if (json['merchants'] != null) {
      try {
        merchantsList = (json['merchants'] as List).map((e) => e.toString()).toList();
      } catch (e) {
        debugPrint('Error parsing merchants list: $e');
      }
    }

    return DirectionGroup(
      groupId: json['group_id'] as String? ?? '',
      baseAngle: json['base_angle'] != null ? (json['base_angle'] as num).toDouble() : 0.0,
      merchants: merchantsList,
      totalCost: json['total_cost'] != null ? (json['total_cost'] as num).toDouble() : 0.0,
      costBreakdown: json['cost_breakdown'] != null 
          ? DirectionGroupCostBreakdown.fromJson(json['cost_breakdown'] as Map<String, dynamic>)
          : DirectionGroupCostBreakdown(
              baseMerchant: DirectionGroupMerchant(
                name: '',
                distance: 0.0,
                cost: 0.0,
              ),
              onTheWay: [],
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'base_angle': baseAngle,
      'merchants': merchants,
      'total_cost': totalCost,
      'cost_breakdown': costBreakdown.toJson(),
    };
  }
}

class RouteSummary {
  final int totalMerchants;
  final List<DirectionGroup> directionGroups;
  final double baseMerchantDistance;

  RouteSummary({
    required this.totalMerchants,
    required this.directionGroups,
    required this.baseMerchantDistance,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_merchants': totalMerchants,
      'direction_groups': directionGroups.map((group) => group.toJson()).toList(),
      'base_merchant_distance': baseMerchantDistance,
    };
  }

  factory RouteSummary.fromJson(Map<String, dynamic> json) {
    // Handle potentially missing or malformed direction_groups
    List<DirectionGroup> groups = [];
    if (json['direction_groups'] != null) {
      try {
        groups = (json['direction_groups'] as List)
            .map((g) => DirectionGroup.fromJson(g as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error parsing direction groups: $e');
      }
    }

    return RouteSummary(
      totalMerchants: json['total_merchants'] as int? ?? 0,
      directionGroups: groups,
      baseMerchantDistance: json['base_merchant_distance'] != null 
          ? (json['base_merchant_distance'] as num).toDouble()
          : 0.0,
    );
  }

  // Computed properties
  bool get hasEfficientRoute {
    // Route is efficient if all merchants are in the same direction group
    // or if the angle difference between groups is acceptable
    if (directionGroups.length == 1) return true;
    
    // Check if any merchants are in different directions
    for (var group in directionGroups) {
      for (var otherGroup in directionGroups) {
        if (group != otherGroup) {
          // Calculate angle difference between groups
          final angleDiff = (group.baseAngle - otherGroup.baseAngle).abs();
          if (angleDiff > 90) return false;
        }
      }
    }
    return true;
  }
}

class CostComparison {
  final double singleOrderTotal;
  final String singleOrderBreakdown;
  final double separateOrdersTotal;
  final String separateOrdersBreakdown;
  final double savingsAmount;
  final String savingsExplanation;

  CostComparison({
    required this.singleOrderTotal,
    required this.singleOrderBreakdown,
    required this.separateOrdersTotal,
    required this.separateOrdersBreakdown,
    required this.savingsAmount,
    required this.savingsExplanation,
  });

  factory CostComparison.fromJson(Map<String, dynamic> json) {
    final singleOrder = json['if_single_order'] as Map<String, dynamic>;
    final separateOrders = json['if_separate_orders'] as Map<String, dynamic>;
    final savings = json['savings'] as Map<String, dynamic>;

    return CostComparison(
      singleOrderTotal: (singleOrder['total'] as num).toDouble(),
      singleOrderBreakdown: singleOrder['breakdown'] as String,
      separateOrdersTotal: (separateOrders['total'] as num).toDouble(),
      separateOrdersBreakdown: separateOrders['breakdown'] as String,
      savingsAmount: (savings['amount'] as num).toDouble(),
      savingsExplanation: savings['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'if_single_order': {
        'total': singleOrderTotal,
        'breakdown': singleOrderBreakdown,
      },
      'if_separate_orders': {
        'total': separateOrdersTotal,
        'breakdown': separateOrdersBreakdown,
      },
      'savings': {
        'amount': savingsAmount,
        'explanation': savingsExplanation,
      },
    };
  }
}

class SplitOrderSuggestion {
  final List<String> merchants;
  final double total;
  final DirectionGroupCostBreakdown breakdown;
  final bool createNewOrder;

  SplitOrderSuggestion({
    required this.merchants,
    required this.total,
    required this.breakdown,
    required this.createNewOrder,
  });

  factory SplitOrderSuggestion.fromJson(Map<String, dynamic> json) {
    return SplitOrderSuggestion(
      merchants: (json['merchants'] as List).map((e) => e as String).toList(),
      total: (json['total'] as num).toDouble(),
      breakdown: DirectionGroupCostBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
      createNewOrder: json['create_new_order'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchants': merchants,
      'total': total,
      'breakdown': breakdown.toJson(),
      'create_new_order': createNewOrder,
    };
  }
}

class ShippingRecommendations {
  final bool shouldSplit;
  final String reason;
  final List<SplitOrderSuggestion> suggestedSplits;
  final Map<String, String> benefits;

  ShippingRecommendations({
    required this.shouldSplit,
    required this.reason,
    required this.suggestedSplits,
    required this.benefits,
  });

  factory ShippingRecommendations.fromJson(Map<String, dynamic> json) {
    return ShippingRecommendations(
      shouldSplit: json['should_split'] as bool,
      reason: json['reason'] as String,
      suggestedSplits: (json['suggested_splits'] as List)
          .map((s) => SplitOrderSuggestion.fromJson(s as Map<String, dynamic>))
          .toList(),
      benefits: Map<String, String>.from(json['benefits'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'should_split': shouldSplit,
      'reason': reason,
      'suggested_splits': suggestedSplits.map((split) => split.toJson()).toList(),
      'benefits': benefits,
    };
  }
}

class ShippingDetails {
  final double totalShippingPrice;
  final List<MerchantDelivery> merchantDeliveries;
  final RouteSummary routeSummary;
  final CostComparison costComparison;
  final ShippingRecommendations recommendations;

  ShippingDetails({
    required this.totalShippingPrice,
    required this.merchantDeliveries,
    required this.routeSummary,
    required this.costComparison,
    required this.recommendations,
  });

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    
    // Create default cost comparison if missing
    final costComparison = data['cost_comparison'] != null 
        ? CostComparison.fromJson(data['cost_comparison'] as Map<String, dynamic>)
        : CostComparison(
            singleOrderTotal: (data['total_shipping_price'] as num).toDouble(),
            singleOrderBreakdown: '',
            separateOrdersTotal: (data['total_shipping_price'] as num).toDouble(),
            separateOrdersBreakdown: '',
            savingsAmount: 0,
            savingsExplanation: '',
          );

    // Create default recommendations if missing
    final recommendations = data['recommendations'] != null
        ? ShippingRecommendations.fromJson(data['recommendations'] as Map<String, dynamic>)
        : ShippingRecommendations(
            shouldSplit: false,
            reason: '',
            suggestedSplits: [],
            benefits: {},
          );

    return ShippingDetails(
      totalShippingPrice: (data['total_shipping_price'] as num).toDouble(),
      merchantDeliveries: (data['merchant_deliveries'] as List)
          .map((delivery) => MerchantDelivery.fromJson(delivery as Map<String, dynamic>))
          .toList(),
      routeSummary: RouteSummary.fromJson(data['route_summary'] as Map<String, dynamic>),
      costComparison: costComparison,
      recommendations: recommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'total_shipping_price': totalShippingPrice,
        'merchant_deliveries': merchantDeliveries.map((delivery) => delivery.toJson()).toList(),
        'route_summary': routeSummary.toJson(),
        'cost_comparison': costComparison.toJson(),
        'recommendations': recommendations.toJson(),
      },
    };
  }

  bool get hasInvalidRoute => merchantDeliveries.any((delivery) => 
    delivery.isInDifferentDirection || delivery.hasInvalidAngle);

  bool get canProceedToCheckout => !recommendations.shouldSplit;
  
  bool get isValidForShipping {
    return merchantDeliveries.isNotEmpty && 
           !hasInvalidRoute && 
           canProceedToCheckout;
  }

  String? get routeWarningMessage {
    if (recommendations.shouldSplit) {
      return recommendations.reason;
    }
    return null;
  }
}

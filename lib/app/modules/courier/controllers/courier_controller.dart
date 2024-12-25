import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class CourierController extends GetxController {
  // Navigation
  final RxInt currentTabIndex = 0.obs;

  void changePage(int index) {
    currentTabIndex.value = index;
  }

  // Dashboard Summary
  final RxBool isOnline = true.obs;
  final RxInt dailyDeliveries = 0.obs;
  final RxDouble dailyEarnings = 0.0.obs;
  final RxDouble totalDistance = 0.0.obs;
  final RxDouble performanceRating = 0.0.obs;

  // Order Counters
  final RxInt pendingOrders = 0.obs;
  final RxInt inProgressOrders = 0.obs;
  final RxInt completedOrders = 0.obs;

  // Delivery Lists
  final RxList availableOrders = [].obs;
  final RxList activeDeliveries = [].obs;
  final RxList pendingDeliveries = [].obs;
  final RxList completedDeliveries = [].obs;

  // Courier Profile
  final RxString courierName = ''.obs;
  final RxString courierId = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString vehicleType = ''.obs;
  final RxString licensePlate = ''.obs;
  final RxString profileImage = ''.obs;

  // Documents
  final RxBool isLicenseVerified = false.obs;
  final RxBool isVehicleRegistrationVerified = false.obs;
  final RxBool isInsuranceVerified = false.obs;
  final RxBool isCertified = false.obs;

  // Earnings
  final RxDouble weeklyEarnings = 0.0.obs;
  final RxDouble monthlyEarnings = 0.0.obs;
  final RxInt loyaltyPoints = 0.obs;
  final RxDouble performanceBonus = 0.0.obs;

  // Statistics
  final RxInt totalDeliveries = 0.obs;
  final RxDouble averageDeliveryTime = 0.0.obs;
  final RxDouble successRate = 0.0.obs;
  final RxDouble customerRating = 0.0.obs;
  final RxDouble routeEfficiency = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void loadInitialData() {
    loadCourierProfile();
    loadDashboardData();
    loadAvailableOrders();
    loadActiveDeliveries();
    loadEarnings();
    loadStatistics();
  }

  void loadCourierProfile() {
    // TODO: Implement API call
    courierName.value = 'John Doe';
    courierId.value = 'CR001';
    phoneNumber.value = '+62 812-3456-7890';
    vehicleType.value = 'Motorcycle';
    licensePlate.value = 'B 1234 XYZ';
    profileImage.value = 'assets/image_profile.png';

    // Document verification status
    isLicenseVerified.value = true;
    isVehicleRegistrationVerified.value = true;
    isInsuranceVerified.value = true;
    isCertified.value = true;
  }

  void loadDashboardData() {
    // TODO: Implement API call
    dailyDeliveries.value = 8;
    dailyEarnings.value = 240000;
    totalDistance.value = 45.5; // in kilometers
    performanceRating.value = 4.8;

    // Update order counters
    pendingOrders.value = 3;
    inProgressOrders.value = 2;
    completedOrders.value = 5;
  }

  void loadAvailableOrders() {
    // TODO: Implement API call
    availableOrders.value = [
      {
        'orderId': '1001',
        'userId': 'USR001',
        'merchants': [
          {
            'merchantId': 'M001',
            'name': 'Merchant Store 1',
            'address': 'Jl. Merchant 1 No. 123',
            'items': [
              {'name': 'Product A', 'quantity': 2},
              {'name': 'Product B', 'quantity': 1},
            ],
          },
          {
            'merchantId': 'M002',
            'name': 'Merchant Store 2',
            'address': 'Jl. Merchant 2 No. 456',
            'items': [
              {'name': 'Product C', 'quantity': 1},
              {'name': 'Product D', 'quantity': 3},
            ],
          },
        ],
        'deliveryAddress': 'Jl. Customer No. 789',
        'customerName': 'Jane Doe',
        'customerPhone': '+62 812-9876-5432',
        'distance': '4.5',
        'estimatedTime': '30',
        'earnings': 45000,
        'notes': 'Please handle with care',
      },
      {
        'orderId': '1002',
        'userId': 'USR002',
        'merchants': [
          {
            'merchantId': 'M003',
            'name': 'Merchant Store 3',
            'address': 'Jl. Merchant 3 No. 321',
            'items': [
              {'name': 'Product E', 'quantity': 1},
            ],
          },
          {
            'merchantId': 'M004',
            'name': 'Merchant Store 4',
            'address': 'Jl. Merchant 4 No. 654',
            'items': [
              {'name': 'Product F', 'quantity': 2},
              {'name': 'Product G', 'quantity': 1},
            ],
          },
        ],
        'deliveryAddress': 'Jl. Customer 2 No. 987',
        'customerName': 'John Smith',
        'customerPhone': '+62 812-3456-7890',
        'distance': '3.8',
        'estimatedTime': '25',
        'earnings': 38000,
        'notes': 'Ring the doorbell twice',
      },
    ];
  }

  void loadActiveDeliveries() {
    // TODO: Implement API call
    activeDeliveries.value = List.generate(
        3,
        (index) => {
              'orderId': 'ORD${1000 + index}',
              'pickupAddress': 'Merchant Address ${index + 1}',
              'deliveryAddress': 'Customer Address ${index + 1}',
              'distance': '${2.5 + index}',
              'estimatedTime': '${15 + index}',
              'status': 'In Progress',
              'customerContact': '+62 812-${3456 + index}-7890',
              'specialNotes': 'Handle with care',
              'payment': {
                'amount': 25000 + (index * 5000),
                'method': 'Cash on Delivery'
              }
            });
  }

  void loadEarnings() {
    // TODO: Implement API call
    weeklyEarnings.value = 1500000;
    monthlyEarnings.value = 6000000;
    loyaltyPoints.value = 500;
    performanceBonus.value = 200000;
  }

  void loadStatistics() {
    // TODO: Implement API call
    totalDeliveries.value = 156;
    averageDeliveryTime.value = 25; // in minutes
    successRate.value = 98.5; // percentage
    customerRating.value = 4.8;
    routeEfficiency.value = 92.3; // percentage
  }

  void toggleOnlineStatus() {
    isOnline.value = !isOnline.value;
    showCustomSnackbar(
      title: 'Status Updated',
      message: isOnline.value ? 'You are now online' : 'You are now offline',
      backgroundColor: Colors.blue,
    );
  }

  void acceptOrder(String orderId) {
    // TODO: Implement API call
    showCustomSnackbar(
      title: 'Success',
      message: 'Order #$orderId accepted',
      backgroundColor: Colors.green,
    );
    loadAvailableOrders();
    loadActiveDeliveries();
    loadDashboardData();
  }

  void rejectDelivery(String orderId) {
    // TODO: Implement API call
    showCustomSnackbar(
      title: 'Rejected',
      message: 'Order #$orderId rejected',
      backgroundColor: Colors.orange,
    );
    loadAvailableOrders();
    loadActiveDeliveries();
  }

  void completeDelivery(String orderId) {
    // TODO: Implement API call
    showCustomSnackbar(
      title: 'Success',
      message: 'Delivery #$orderId completed',
      backgroundColor: Colors.green,
    );
    loadActiveDeliveries();
    loadDashboardData();
    loadStatistics();
  }

  void updateDeliveryStatus(String orderId, String status) {
    // TODO: Implement API call
    showCustomSnackbar(
      title: 'Status Updated',
      message: 'Delivery #$orderId: $status',
      backgroundColor: Colors.blue,
    );
    loadActiveDeliveries();
  }

  void uploadDeliveryProof(String orderId, String proofType) {
    // TODO: Implement API call for uploading delivery proof
    showCustomSnackbar(
      title: 'Upload Success',
      message: '$proofType uploaded for order #$orderId',
      backgroundColor: Colors.green,
    );
  }

  void navigateToLocation(String address) {
    // TODO: Implement navigation logic
    showCustomSnackbar(
      title: 'Navigation',
      message: 'Navigating to: $address',
      backgroundColor: Colors.blue,
    );
  }

  void contactCustomer(String phoneNumber) {
    // TODO: Implement customer contact logic
    showCustomSnackbar(
      title: 'Contact Customer',
      message: 'Calling customer: $phoneNumber',
      backgroundColor: Colors.blue,
    );
  }

  void logout() {
    // TODO: Implement logout logic
    Get.offAllNamed('/login');
  }

  Future<void> refreshData() async {
    loadInitialData();
  }
}

// ignore_for_file: deprecated_member_use

import 'package:antarkanma/app/controllers/map_picker_controller.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

class MapPickerView extends StatefulWidget {
  const MapPickerView({super.key});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> with WidgetsBindingObserver {
  late final MapPickerController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MapPickerController());
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeMap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<MapPickerController>();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.getCurrentLocation();
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Pilih Lokasi',
        style: primaryTextStyle.copyWith(
          fontSize: Dimenssions.font18,
          fontWeight: semiBold,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: logoColorSecondary,
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.my_location,
            color: logoColorSecondary,
          ),
          onPressed: () {
            controller.getCurrentLocation();
          },
          tooltip: 'Lokasi Saat Ini',
        ),
      ],
      backgroundColor: backgroundColor1,
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back();
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildMap(),
            _buildAccuracyIndicator(),
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: _buildLocationInfo(),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildConfirmButton(),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Obx(() => FlutterMap(
          mapController: controller.mapController.value,
          options: MapOptions(
            center: controller.selectedLocation.value,
            zoom: controller.zoomLevel.value,
            onTap: (_, latLng) {
              controller.updateLocation(latLng);
              controller.animateToLocation(latLng);
            },
            minZoom: 5.0,
            maxZoom: 18.0,
            interactiveFlags: InteractiveFlag.all,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
              maxZoom: 19,
              tileProvider: NetworkTileProvider(),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: controller.selectedLocation.value,
                  width: 50,
                  height: 50,
                  builder: (context) => _buildMarker(),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _buildAccuracyIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Obx(() {
        final isHighAccuracy = controller.isHighAccuracy.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isHighAccuracy ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHighAccuracy ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.accuracyText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (controller.isLoading.value)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMarker() {
    return Obx(() {
      final isHighAccuracy = controller.isHighAccuracy.value;
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isHighAccuracy ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              isHighAccuracy ? Icons.location_on : Icons.location_searching,
              color: Colors.white,
              size: 24,
            ),
          ),
          Container(
            width: 2,
            height: 8,
            color: isHighAccuracy ? Colors.green : Colors.orange,
          ),
        ],
      );
    });
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Koordinat:', controller.formattedLocation),
              const SizedBox(height: 12),
              _buildInfoRow('Alamat:', controller.currentAddress.value),
            ],
          )),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: primaryTextStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: primaryTextStyle.copyWith(fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Obx(() {
      // Only show button if location has been selected
      if (!controller.canConfirm.value) {
        return const SizedBox.shrink();
      }

      return FloatingActionButton.extended(
        onPressed: () => controller.confirmLocation(),
        icon: Icon(
          Icons.check,
          color: Colors.white,
        ),
        label: Text(
          'Konfirmasi',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: logoColorSecondary,
      );
    });
  }
}

import 'package:antarkanma/app/modules/courier/views/delivery_list_view.dart';
import 'package:antarkanma/app/modules/courier/views/delivery_management_page.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/modules/courier/views/courier_home_page.dart';
import 'package:antarkanma/app/modules/user/views/profile_page.dart';

class CourierMainPage extends StatefulWidget {
  const CourierMainPage({super.key});

  @override
  State<CourierMainPage> createState() => _CourierMainPageState();
}

class _CourierMainPageState extends State<CourierMainPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Fungsi untuk menentukan konten yang ditampilkan berdasarkan indeks saat ini
    Widget body() {
      switch (currentIndex) {
        case 0:
          return const CourierHomePage(); // Halaman utama kurir
        case 1:
          return const DeliveryManagementPage(); // Halaman untuk manajemen pengiriman
        case 2:
          return ProfilePage();
        case 3:
          return const DeliveryListView(); // Halaman profil
        default:
          return const CourierHomePage();
      }
    }

    // Fungsi untuk membuat item navigasi
    BottomNavigationBarItem createNavItem(
        IconData icon, String label, int index) {
      return BottomNavigationBarItem(
        icon: Icon(
          icon,
          color: currentIndex == index ? Colors.blue : Colors.grey,
        ),
        label: label,
      );
    }

    return Scaffold(
      body: body(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          createNavItem(Icons.home, 'Home', 0),
          createNavItem(Icons.local_shipping, 'Shipments', 1),
          createNavItem(Icons.person, 'Profile', 2),
        ],
      ),
    );
  }
}

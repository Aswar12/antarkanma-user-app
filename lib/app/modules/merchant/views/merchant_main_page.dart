import 'package:antarkanma/app/modules/merchant/views/merchant_home_page.dart';
import 'package:antarkanma/app/modules/merchant/views/order_management_page.dart';
import 'package:antarkanma/app/modules/merchant/views/product_management_view.dart';
import 'package:antarkanma/app/modules/user/views/profile_page.dart';
import 'package:flutter/material.dart';

class MerchantMainPage extends StatefulWidget {
  const MerchantMainPage({super.key});

  @override
  State<MerchantMainPage> createState() => _MerchantMainPageState();
}

class _MerchantMainPageState extends State<MerchantMainPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Fungsi untuk menentukan konten yang ditampilkan berdasarkan indeks saat ini
    Widget body() {
      switch (currentIndex) {
        case 0:
          return const MerchantHomePage(); // Halaman utama untuk Merchant
        case 1:
          return const ProductManagementPage(); // Halaman untuk manajemen produk
        case 2:
          return const OrderManagementPage(); // Halaman untuk manajemen pesanan
        case 3:
          return ProfilePage(); // Halaman profil
        default:
          return const MerchantHomePage();
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
          createNavItem(Icons.list, 'Products', 1),
          createNavItem(Icons.assignment, 'Orders', 2),
          createNavItem(Icons.person, 'Profile', 3),
        ],
      ),
    );
  }
}

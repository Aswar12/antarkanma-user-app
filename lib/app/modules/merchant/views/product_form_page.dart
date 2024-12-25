import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:intl/intl.dart';

class ProductFormPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormPage({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late bool isEditing;
  List<VariantModel> variants = [];
  final priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    isEditing = widget.product != null;
    if (widget.product != null && widget.product!['variants'] != null) {
      variants = List<Map<String, dynamic>>.from(widget.product!['variants'])
          .map((v) => VariantModel.fromJson(v))
          .toList();
    }
  }

  void _showVariantDialog({VariantModel? existingVariant, int? index}) {
    final nameController =
        TextEditingController(text: existingVariant?.name ?? '');
    final valueController =
        TextEditingController(text: existingVariant?.value ?? '');
    final priceAdjustmentController = TextEditingController(
      text: existingVariant?.priceAdjustment.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existingVariant == null ? 'Tambah Varian' : 'Edit Varian',
          style: primaryTextStyle.copyWith(fontWeight: semiBold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Varian',
                labelStyle: secondaryTextStyle,
                hintText: 'Contoh: Ukuran, Warna',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.width12,
                  vertical: Dimenssions.height12,
                ),
              ),
            ),
            SizedBox(height: Dimenssions.height16),
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: 'Nilai Varian',
                labelStyle: secondaryTextStyle,
                hintText: 'Contoh: XL, Merah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.width12,
                  vertical: Dimenssions.height12,
                ),
              ),
            ),
            SizedBox(height: Dimenssions.height16),
            TextField(
              controller: priceAdjustmentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tambahan Harga',
                labelStyle: secondaryTextStyle,
                hintText: 'Masukkan tambahan harga',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.width12,
                  vertical: Dimenssions.height12,
                ),
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: primaryTextStyle.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final variant = VariantModel(
                id: existingVariant?.id,
                productId: existingVariant?.productId,
                name: nameController.text,
                value: valueController.text,
                priceAdjustment:
                    double.tryParse(priceAdjustmentController.text) ?? 0,
                status: existingVariant?.status ?? 'ACTIVE',
              );
              setState(() {
                if (index != null) {
                  variants[index] = variant;
                } else {
                  variants.add(variant);
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: logoColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimenssions.radius8),
              ),
            ),
            child: Text(
              'Simpan',
              style: primaryTextStyle.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Produk' : 'Tambah Produk',
          style: primaryTextStyle.copyWith(color: logoColor),
        ),
        backgroundColor: transparentColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: logoColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageUploadSection(),
            SizedBox(height: Dimenssions.height20),
            _buildTextField('Nama Produk', 'Masukkan nama produk',
                initialValue: widget.product?['name']),
            SizedBox(height: Dimenssions.height16),
            _buildTextField('Deskripsi', 'Masukkan deskripsi produk',
                maxLines: 3, initialValue: widget.product?['description']),
            SizedBox(height: Dimenssions.height16),
            _buildDropdownField('Kategori', ['Kategori 1', 'Kategori 2'],
                initialValue: widget.product?['category']),
            SizedBox(height: Dimenssions.height16),
            _buildTextField('Harga', 'Masukkan harga produk',
                keyboardType: TextInputType.number,
                initialValue: widget.product?['price']?.toString()),
            SizedBox(height: Dimenssions.height16),
            _buildVariantSection(),
            SizedBox(height: Dimenssions.height16),
            _buildStatusSwitch(),
            SizedBox(height: Dimenssions.height24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final Map<String, dynamic> productData = {
                    'name': '', // Get from form
                    'description': '', // Get from form
                    'price': 0, // Get from form
                    'category': '', // Get from form
                    'status': true, // Get from switch
                    'variants': variants.map((v) => v.toJson()).toList(),
                  };
                  Navigator.pop(context, productData);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: logoColor,
                  padding: EdgeInsets.symmetric(vertical: Dimenssions.height16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimenssions.radius8),
                  ),
                ),
                child: Text(
                  'Simpan Produk',
                  style: primaryTextStyle.copyWith(
                    color: Colors.white,
                    fontSize: Dimenssions.font16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimenssions.width16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(Dimenssions.radius8),
      ),
      child: Column(
        children: [
          if (widget.product != null && widget.product!['image'] != null)
            Container(
              width: 200,
              height: 200,
              margin: EdgeInsets.only(bottom: Dimenssions.height16),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.product!['image']),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(Dimenssions.radius8),
              ),
            ),
          Icon(Icons.cloud_upload, size: 48, color: logoColor),
          SizedBox(height: Dimenssions.height8),
          Text(
            'Upload Gambar Produk',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              fontWeight: bold,
            ),
          ),
          SizedBox(height: Dimenssions.height8),
          Text(
            'Drag & drop atau klik untuk memilih file',
            style: secondaryTextStyle,
          ),
          SizedBox(height: Dimenssions.height16),
          ElevatedButton(
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              await picker.pickMultiImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: logoColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimenssions.radius8),
              ),
            ),
            child: Text('Pilih File'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      {int maxLines = 1, TextInputType? keyboardType, String? initialValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font14,
            fontWeight: bold,
          ),
        ),
        SizedBox(height: Dimenssions.height8),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: secondaryTextStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width12,
              vertical: Dimenssions.height12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items,
      {String? initialValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font14,
            fontWeight: bold,
          ),
        ),
        SizedBox(height: Dimenssions.height8),
        DropdownButtonFormField<String>(
          value: initialValue,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: (value) {},
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width12,
              vertical: Dimenssions.height12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantSection() {
    // Group variants by name
    final variantGroups = <String, List<VariantModel>>{};
    for (var variant in variants) {
      if (!variantGroups.containsKey(variant.name)) {
        variantGroups[variant.name] = [];
      }
      variantGroups[variant.name]!.add(variant);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Varian Produk',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font14,
                fontWeight: bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showVariantDialog(),
              icon: Icon(Icons.add, color: logoColor),
              label: Text(
                'Tambah Varian',
                style: primaryTextStyle.copyWith(color: logoColor),
              ),
            ),
          ],
        ),
        SizedBox(height: Dimenssions.height8),
        if (variants.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: Dimenssions.height16),
              child: Text(
                'Belum ada varian',
                style: secondaryTextStyle,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: variantGroups.length,
            itemBuilder: (context, index) {
              final groupName = variantGroups.keys.elementAt(index);
              final groupVariants = variantGroups[groupName]!;
              return Card(
                margin: EdgeInsets.only(bottom: Dimenssions.height16),
                child: Padding(
                  padding: EdgeInsets.all(Dimenssions.width12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: primaryTextStyle.copyWith(
                          fontWeight: semiBold,
                        ),
                      ),
                      Divider(),
                      Wrap(
                        spacing: Dimenssions.width8,
                        runSpacing: Dimenssions.height8,
                        children: groupVariants.map((variant) {
                          return Chip(
                            label: Text(
                              '${variant.value} (${variant.formattedPriceAdjustment})',
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                              ),
                            ),
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                variants.remove(variant);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Status Produk',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font14,
            fontWeight: bold,
          ),
        ),
        Switch(
          value: widget.product?['status'] ?? true,
          onChanged: (value) {
            setState(() {
              // Update status
            });
          },
          activeColor: logoColor,
        ),
      ],
    );
  }
}

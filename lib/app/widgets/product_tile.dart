// ignore_for_file: deprecated_member_use

import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';

class ProductTile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double price;
  final String merchantName;
  final double rating;
  final int reviews;
  final Function()? onTap;

  const ProductTile({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.merchantName,
    required this.rating,
    required this.reviews,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          left: Dimenssions.width20,
          right: Dimenssions.width20,
          bottom: Dimenssions.height20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: Dimenssions.width90,
              height: Dimenssions.height90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimenssions.radius15),
                  bottomLeft: Radius.circular(Dimenssions.radius15),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimenssions.radius15),
                  bottomLeft: Radius.circular(Dimenssions.radius15),
                ),
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/image_shoes.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(Dimenssions.height10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Dimenssions.height5),
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: Dimenssions.iconSize16,
                          color: logoColor,
                        ),
                        SizedBox(width: Dimenssions.width5),
                        Expanded(
                          child: Text(
                            merchantName,
                            style: subtitleTextStyle.copyWith(
                              fontSize: Dimenssions.font12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimenssions.height5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp ${price.toStringAsFixed(0)}',
                          style: priceTextStyle.copyWith(
                            fontSize: Dimenssions.font14,
                            fontWeight: medium,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: Dimenssions.iconSize16,
                              color: Colors.amber,
                            ),
                            SizedBox(width: Dimenssions.width5),
                            Text(
                              '$rating ($reviews)',
                              style: subtitleTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/product_analysis.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

Widget foodItem(ProductAnalysis food,
    {double? imgWidth, onLike, onTapped, bool isProductPage = false}) {

  return Container(
    width: 180,
    height: 180,
    // color: Colors.red,
    margin: EdgeInsets.only(left: 20),
    child: Stack(
      children: <Widget>[
        Container(
            width: 180,
            height: 180,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  elevation: (isProductPage) ? 20 : 12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                ),
                onPressed: onTapped,
                child: Hero(
                    transitionOnUserGestures: true,
                    tag: food.name,
                    child: Image.network(food.imageUrl,
                        width: (imgWidth != null) ? imgWidth : 100)))),
        Positioned(
          bottom: (isProductPage) ? 10 : 70,
          right: 0,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.all(20),
              shape: CircleBorder(),
            ),
            onPressed: onLike,
            child: Icon(
              Icons.favorite_border,
              color: AppColors.textDark,
              size: 30,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: (!isProductPage)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(food.name, style: AppStyles.bodyBold),
                    Text('', style: AppStyles.bodyRegular),
                  ],
                )
              : Text(' '),
        ),
        Positioned(
            top: 10,
            left: 10,
            child: SizedBox(width: 0))
      ],
    ),
  );
}

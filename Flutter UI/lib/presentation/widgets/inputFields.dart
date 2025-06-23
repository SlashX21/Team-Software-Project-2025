import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

Container fryoTextInput(String hintText,
    {onTap, onChanged, onEditingComplete, onSubmitted}) {
  return Container(
    margin: EdgeInsets.only(top: 13),
    child: TextField(
      onTap: onTap,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      cursorColor: AppColors.primary,
      style: AppStyles.bodyRegular,
      decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.textLight),
            borderRadius: BorderRadius.circular(4),
          )),
    ),
  );
}

Container fryoEmailInput(String hintText,
    {onTap, onChanged, onEditingComplete, onSubmitted}) {
  return Container(
    margin: EdgeInsets.only(top: 13),
    child: TextField(
      onTap: onTap,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      keyboardType: TextInputType.emailAddress,
      cursorColor: AppColors.primary,
      style: AppStyles.bodyRegular,
      decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.textLight),
            borderRadius: BorderRadius.circular(4),
          )),
    ),
  );
}


Container fryoPasswordInput(String hintText,
    {onTap, onChanged, onEditingComplete, onSubmitted}) {
  return Container(
    margin: EdgeInsets.only(top: 13),
    child: TextField(
      onTap: onTap,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      obscureText: true,
      cursorColor: AppColors.primary,
      style: AppStyles.bodyRegular,
      decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppStyles.bodyRegular.copyWith(color: AppColors.textLight),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.textLight),
            borderRadius: BorderRadius.circular(4),
          )),
    ),
  );
}

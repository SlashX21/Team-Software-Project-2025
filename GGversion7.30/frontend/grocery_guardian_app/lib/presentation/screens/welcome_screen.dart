import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';

import 'package:page_transition/page_transition.dart';
import './SignUpPage.dart';
import './SignInPage.dart';

class WelcomeScreen extends StatefulWidget {
  final String? pageTitle;

  WelcomeScreen({Key? key, this.pageTitle}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.eco, size: 120, color: AppColors.primary),
          Container(
            margin: EdgeInsets.only(bottom: 10, top: 0),
            child: Text('Grocery Guardian', style: AppStyles.logo),
          ),
          Container(
            width: 200,
            margin: EdgeInsets.only(bottom: 0),
            child: froyoFlatBtn('Sign In', (){ 
              Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft, duration: Duration(milliseconds: 500), child: SignInPage()));
            }),
          ),
          Container(
            width: 200,
            padding: EdgeInsets.all(0),
            child: froyoOutlineBtn('Sign Up', (){
              Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft, duration: Duration(milliseconds: 500), child: SignUpPage()));
            }),
          ),
          Container(
            margin: EdgeInsets.only(top: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text('Language:', style: TextStyle(color: AppColors.textLight)),
                Container(
                  margin: EdgeInsets.only(left: 6),
                  child: Text('English ›', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
                )
              ],
            ),
          )
        ],
      )),
      backgroundColor: AppColors.background,
    );
  }
}
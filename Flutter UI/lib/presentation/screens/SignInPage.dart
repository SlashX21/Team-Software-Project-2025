import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import '../widgets/inputFields.dart';
import 'package:page_transition/page_transition.dart';
import './SignUpPage.dart';
import './home_screen.dart';

class SignInPage extends StatefulWidget {
  final String? pageTitle;

  SignInPage({Key? key, this.pageTitle}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        title: Text('Sign In',
            style: TextStyle(
                color: Colors.grey, fontFamily: 'Poppins', fontSize: 15)),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // Navigator.of(context).pushReplacementNamed('/signup');
              Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft,  child: SignUpPage()));

            },
            child: Text('Sign Up', style: AppStyles.bodyBold.copyWith(color: AppColors.primary)),
          )
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Container(
        padding: EdgeInsets.only(left: 18, right: 18),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Welcome Back!', style: AppStyles.h2),
                Text('Howdy, let\'s authenticate', style: AppStyles.bodyRegular.copyWith(color: AppColors.textLight)),
                fryoTextInput('Username'),
                fryoPasswordInput('Password'),
                TextButton(
                  onPressed: () {},
                  child: Text('Forgot Password?', style: AppStyles.bodyBold.copyWith(color: AppColors.primary)),
                )
              ],
            ),
            Positioned(
              bottom: 15,
              right: -15,
              child: ElevatedButton(
                onPressed: () {
                    Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.rightToLeft, child: HomeScreen()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: CircleBorder(), padding: EdgeInsets.all(13)),
                child: Icon(Icons.arrow_forward, color: AppColors.white),
              ),
            )
          ],
        ),
        height: 245,
        
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
      ),
        ],
      )
    );
  }
}

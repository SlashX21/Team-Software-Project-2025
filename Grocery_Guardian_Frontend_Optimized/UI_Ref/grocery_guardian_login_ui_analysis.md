# Grocery Guardian 登录页面 UI 设计规范

## 🎨 整体设计概览

### 设计风格
- **设计语言**: Material Design 3.0 风格
- **主题**: 健康/食品安全主题的绿色调
- **布局方式**: 垂直居中，简洁现代
- **适配**: 移动端优先设计

## 📱 屏幕规格与布局

### 基础参数
```dart
// 屏幕参考尺寸 (假设标准手机屏幕)
const double screenWidth = 375.0;   // iPhone 标准宽度参考
const double screenHeight = 812.0;  // iPhone 标准高度参考
const double statusBarHeight = 44.0; // 状态栏高度
```

### 安全区域
```dart
// Flutter SafeArea 配置
SafeArea(
  top: true,
  bottom: true,
  // 内容区域
)
```

## 🎨 配色方案 (Color Palette)

### 主色调
```dart
class AppColors {
  // 主绿色 - Logo和主要按钮
  static const Color primaryGreen = Color(0xFF2D5016);
  
  // 浅绿色 - 次要按钮和装饰元素
  static const Color lightGreen = Color(0xFFB8E6B8);
  
  // 背景渐变色
  static const Color backgroundStart = Color(0xFFE8F5E8);
  static const Color backgroundEnd = Color(0xFFF0F8F0);
  
  // 中性色
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF666666);
  static const Color borderGray = Color(0xFFE0E0E0);
  
  // 状态栏
  static const Color statusBarContent = Color(0xFF000000); // 黑色图标
}
```

## 📐 组件尺寸规范

### 1. 应用Logo区域
```dart
// Logo容器
Container(
  width: 120.0,
  height: 120.0,
  decoration: BoxDecoration(
    color: AppColors.primaryGreen,
    borderRadius: BorderRadius.circular(24.0), // 圆角半径
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8.0,
        offset: Offset(0, 4),
      ),
    ],
  ),
  // Logo图标: 白色人形图标
)
```

### 2. 用户头像区域
```dart
// 头像背景圆形
Container(
  width: 80.0,
  height: 80.0,
  decoration: BoxDecoration(
    color: AppColors.lightGreen,
    shape: BoxShape.circle,
  ),
  child: Icon(
    Icons.person_outline,
    size: 40.0,
    color: AppColors.primaryGreen,
  ),
)
```

### 3. 输入框规范
```dart
// 输入框容器
Container(
  width: double.infinity,
  height: 56.0, // Material Design 标准高度
  margin: EdgeInsets.symmetric(horizontal: 32.0),
  decoration: BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(8.0),
    border: Border.all(
      color: AppColors.borderGray,
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4.0,
        offset: Offset(0, 2),
      ),
    ],
  ),
)

// 输入框文字样式
TextStyle inputTextStyle = TextStyle(
  fontSize: 16.0,
  color: AppColors.darkGray,
  fontWeight: FontWeight.w400,
);

// 标签文字样式
TextStyle labelTextStyle = TextStyle(
  fontSize: 14.0,
  color: AppColors.darkGray,
  fontWeight: FontWeight.w500,
);
```

### 4. 按钮规范

#### 主按钮 (Log In)
```dart
Container(
  width: 120.0,
  height: 48.0,
  decoration: BoxDecoration(
    color: AppColors.primaryGreen,
    borderRadius: BorderRadius.circular(24.0), // 圆角胶囊形状
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryGreen.withOpacity(0.3),
        blurRadius: 8.0,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Text(
    'Log In',
    style: TextStyle(
      color: AppColors.white,
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

#### 次要按钮 (Sign Up)
```dart
Container(
  width: 120.0,
  height: 48.0,
  decoration: BoxDecoration(
    color: AppColors.lightGreen,
    borderRadius: BorderRadius.circular(24.0),
    boxShadow: [
      BoxShadow(
        color: AppColors.lightGreen.withOpacity(0.3),
        blurRadius: 6.0,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Text(
    'Sign Up',
    style: TextStyle(
      color: AppColors.primaryGreen,
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### 5. Settings按钮
```dart
// 位置：右下角
Positioned(
  bottom: 60.0,
  right: 24.0,
  child: Container(
    width: 56.0,
    height: 32.0,
    decoration: BoxDecoration(
      color: AppColors.lightGreen,
      borderRadius: BorderRadius.circular(16.0),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.settings_outlined,
          size: 16.0,
          color: AppColors.primaryGreen,
        ),
        SizedBox(width: 4.0),
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 12.0,
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
)
```

## 📏 布局间距 (Spacing)

### 垂直间距
```dart
class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}

// 具体应用:
// Logo 到用户头像: 80.0
// 用户头像到第一个输入框: 40.0
// 输入框之间: 16.0
// 输入框到按钮区域: 32.0
// 按钮之间: 16.0 (水平间距)
```

### 水平间距
```dart
// 屏幕左右边距: 32.0
// 按钮之间间距: 16.0
// Settings按钮右边距: 24.0
```

## 🎭 动画与交互

### 按钮点击效果
```dart
// 点击缩放动画
AnimatedContainer(
  duration: Duration(milliseconds: 150),
  curve: Curves.easeInOut,
  transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
  // 按钮内容
)
```

### 输入框焦点效果
```dart
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  decoration: BoxDecoration(
    border: Border.all(
      color: isFocused ? AppColors.primaryGreen : AppColors.borderGray,
      width: isFocused ? 2.0 : 1.0,
    ),
  ),
)
```

## 🔤 字体规范

### 字体族
```dart
// 使用系统默认字体或 Google Fonts
fontFamily: 'Roboto', // Android
fontFamily: 'SF Pro Display', // iOS

// 或使用 Google Fonts
GoogleFonts.roboto(
  // 字体样式
)
```

### 字体大小层级
```dart
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
  );
}
```

## 📱 响应式设计

### 屏幕适配策略
```dart
// 使用 flutter_screenutil 或类似库
class ResponsiveSize {
  static double width(double size) => size.w;
  static double height(double size) => size.h;
  static double fontSize(double size) => size.sp;
}

// 或使用 MediaQuery
double screenWidth = MediaQuery.of(context).size.width;
double screenHeight = MediaQuery.of(context).size.height;
```

## 🎨 背景渐变
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.backgroundStart,
        AppColors.backgroundEnd,
      ],
      stops: [0.0, 1.0],
    ),
  ),
)
```

## 📋 状态栏配置
```dart
SystemChrome.setSystemUIOverlayStyle(
  SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ),
);
```

## 🔍 可访问性 (Accessibility)

### 语义化标签
```dart
Semantics(
  label: 'User ID input field',
  hint: 'Enter your user ID',
  child: TextField(...),
)

Semantics(
  label: 'Login button',
  hint: 'Tap to login',
  button: true,
  child: ElevatedButton(...),
)
```

## 🛠 Flutter 实现建议

### 推荐的 Widget 结构
```dart
Scaffold(
  body: SafeArea(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(...),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          _buildLogo(),
          SizedBox(height: 80.0),
          
          // User Avatar
          _buildUserAvatar(),
          SizedBox(height: 40.0),
          
          // Input Fields
          _buildInputFields(),
          SizedBox(height: 32.0),
          
          // Buttons
          _buildButtons(),
          
          // Settings Button (Positioned)
        ],
      ),
    ),
  ),
)
```

### 推荐的依赖包
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
  flutter_screenutil: ^5.9.0
  flutter_svg: ^2.0.9
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

这个设计规范为Flutter开发提供了完整的实现指导，确保UI还原度和用户体验的一致性。
#!/usr/bin/env python3
"""
Simple test script to verify loyalty module classes work correctly
This tests the Java classes without needing the Spring Boot app running
"""

import os
import subprocess
import sys

def test_java_compilation():
    """Test that all Java classes compile correctly"""
    print("🔍 Testing Java Compilation...")
    
    try:
        # Change to loyalty directory
        os.chdir("Loyalty")
        
        # Run mvn compile
        result = subprocess.run(
            ["mvn", "clean", "compile"], 
            capture_output=True, 
            text=True, 
            timeout=30
        )
        
        if result.returncode == 0:
            print("✅ Java compilation successful!")
            return True
        else:
            print(f"❌ Java compilation failed:")
            print(result.stderr)
            return False
            
    except Exception as e:
        print(f"❌ Compilation test failed: {e}")
        return False
    finally:
        # Change back to parent directory
        os.chdir("..")

def test_file_structure():
    """Test that all required files exist"""
    print("\n🔍 Testing File Structure...")
    
    required_files = [
        "Loyalty/src/main/java/org/loyalty/controller/LoyaltyController.java",
        "Loyalty/src/main/java/org/loyalty/service/ILoyaltyService.java",
        "Loyalty/src/main/java/org/loyalty/service/LoyaltyService.java",
        "Loyalty/src/main/java/org/loyalty/pojo/DTO/LoyaltyPointsRequest.java",
        "Loyalty/src/main/java/org/loyalty/pojo/DTO/CheckPointsRequest.java",
        "Loyalty/src/main/java/org/loyalty/pojo/response/LoyaltyPointsResponse.java",
        "Loyalty/src/main/java/org/loyalty/pojo/response/ContractInfoResponse.java",
        "Loyalty/src/main/resources/application.properties",
        "Loyalty/pom.xml"
    ]
    
    missing_files = []
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if not missing_files:
        print("✅ All required files exist!")
        return True
    else:
        print("❌ Missing files:")
        for file_path in missing_files:
            print(f"   - {file_path}")
        return False

def test_package_structure():
    """Test that package declarations are correct"""
    print("\n🔍 Testing Package Structure...")
    
    package_tests = [
        ("Loyalty/src/main/java/org/loyalty/controller/LoyaltyController.java", "org.loyalty.controller"),
        ("Loyalty/src/main/java/org/loyalty/service/ILoyaltyService.java", "org.loyalty.service"),
        ("Loyalty/src/main/java/org/loyalty/service/LoyaltyService.java", "org.loyalty.service"),
        ("Loyalty/src/main/java/org/loyalty/pojo/DTO/LoyaltyPointsRequest.java", "org.loyalty.pojo.DTO"),
        ("Loyalty/src/main/java/org/loyalty/pojo/DTO/CheckPointsRequest.java", "org.loyalty.pojo.DTO"),
        ("Loyalty/src/main/java/org/loyalty/pojo/response/LoyaltyPointsResponse.java", "org.loyalty.pojo.response"),
        ("Loyalty/src/main/java/org/loyalty/pojo/response/ContractInfoResponse.java", "org.loyalty.pojo.response"),
    ]
    
    errors = []
    for file_path, expected_package in package_tests:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                if f"package {expected_package};" not in content:
                    errors.append(f"Wrong package in {file_path}")
        except Exception as e:
            errors.append(f"Error reading {file_path}: {e}")
    
    if not errors:
        print("✅ All package declarations are correct!")
        return True
    else:
        print("❌ Package declaration errors:")
        for error in errors:
            print(f"   - {error}")
        return False

def test_imports():
    """Test that imports are correct"""
    print("\n🔍 Testing Import Statements...")
    
    import_tests = [
        ("Loyalty/src/main/java/org/loyalty/controller/LoyaltyController.java", [
            "org.loyalty.pojo.DTO.LoyaltyPointsRequest",
            "org.loyalty.pojo.DTO.CheckPointsRequest",
            "org.loyalty.pojo.response.LoyaltyPointsResponse",
            "org.loyalty.pojo.response.ContractInfoResponse",
            "org.loyalty.service.ILoyaltyService"
        ]),
        ("Loyalty/src/main/java/org/loyalty/service/LoyaltyService.java", [
            "org.loyalty.pojo.DTO.LoyaltyPointsRequest",
            "org.loyalty.pojo.DTO.CheckPointsRequest",
            "org.loyalty.pojo.response.LoyaltyPointsResponse",
            "org.loyalty.pojo.response.ContractInfoResponse"
        ])
    ]
    
    errors = []
    for file_path, expected_imports in import_tests:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                for expected_import in expected_imports:
                    if f"import {expected_import};" not in content:
                        errors.append(f"Missing import {expected_import} in {file_path}")
        except Exception as e:
            errors.append(f"Error reading {file_path}: {e}")
    
    if not errors:
        print("✅ All import statements are correct!")
        return True
    else:
        print("❌ Import statement errors:")
        for error in errors:
            print(f"   - {error}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting Loyalty Module Tests")
    print("=" * 50)
    
    tests = [
        ("File Structure", test_file_structure),
        ("Package Structure", test_package_structure),
        ("Import Statements", test_imports),
        ("Java Compilation", test_java_compilation),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        print(f"\n{'='*20} {test_name} {'='*20}")
        try:
            success = test_func()
            results.append((test_name, success))
            if success:
                print(f"✅ {test_name} PASSED")
            else:
                print(f"❌ {test_name} FAILED")
        except Exception as e:
            print(f"❌ {test_name} ERROR: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 TEST SUMMARY")
    print("=" * 50)
    
    passed = 0
    for test_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{test_name}: {status}")
        if success:
            passed += 1
    
    print(f"\nTotal: {passed}/{len(results)} tests passed")
    
    if passed == len(results):
        print("🎉 All tests passed! Loyalty module is ready for integration.")
        print("\n📋 Next Steps:")
        print("1. Integrate the loyalty module into your main Spring Boot application")
        print("2. Start the main application on port 8080")
        print("3. Test the loyalty endpoints via Flutter app or API calls")
    else:
        print("⚠️  Some tests failed. Fix the issues before integration.")

if __name__ == "__main__":
    main() 
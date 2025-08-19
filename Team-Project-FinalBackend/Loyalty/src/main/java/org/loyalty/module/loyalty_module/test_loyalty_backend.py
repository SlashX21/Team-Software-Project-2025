#!/usr/bin/env python3
"""
Test script for Loyalty Backend API
Tests the Spring Boot loyalty endpoints
"""

import requests
import json
import time

# Configuration
BASE_URL = "http://127.0.0.1:8081"
LOYALTY_BASE_URL = f"{BASE_URL}/loyalty"

# Test data
TEST_USER_ID = "1001"
TEST_AMOUNT = 100

def test_health_check():
    """Test the health check endpoint"""
    print("🔍 Testing Health Check...")
    try:
        response = requests.get(f"{LOYALTY_BASE_URL}/health", timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_contract_info():
    """Test the contract info endpoint"""
    print("\n🔍 Testing Contract Info...")
    try:
        response = requests.get(f"{LOYALTY_BASE_URL}/contract-info", timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Contract info failed: {e}")
        return False

def test_check_user_exists():
    """Test the user exists endpoint"""
    print(f"\n🔍 Testing User Exists (User ID: {TEST_USER_ID})...")
    try:
        data = {"userId": TEST_USER_ID}
        response = requests.post(
            f"{LOYALTY_BASE_URL}/user-exists",
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ User exists check failed: {e}")
        return False

def test_check_points():
    """Test the check points endpoint"""
    print(f"\n🔍 Testing Check Points (User ID: {TEST_USER_ID})...")
    try:
        data = {"userId": TEST_USER_ID}
        response = requests.post(
            f"{LOYALTY_BASE_URL}/check-points",
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Check points failed: {e}")
        return False

def test_award_points():
    """Test the award points endpoint"""
    print(f"\n🔍 Testing Award Points (User ID: {TEST_USER_ID}, Amount: {TEST_AMOUNT})...")
    try:
        data = {"userId": TEST_USER_ID, "amount": TEST_AMOUNT}
        response = requests.post(
            f"{LOYALTY_BASE_URL}/award-points",
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=30  # Longer timeout for blockchain transaction
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Award points failed: {e}")
        return False

def test_redeem_points():
    """Test the redeem points endpoint"""
    print(f"\n🔍 Testing Redeem Points (User ID: {TEST_USER_ID})...")
    try:
        data = {"userId": TEST_USER_ID}
        response = requests.post(
            f"{LOYALTY_BASE_URL}/redeem-points",
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=60  # Longer timeout for blockchain transaction
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Redeem points failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting Loyalty Backend Tests")
    print("=" * 50)
    
    tests = [
        ("Health Check", test_health_check),
        ("Contract Info", test_contract_info),
        ("User Exists", test_check_user_exists),
        ("Check Points", test_check_points),
        ("Award Points", test_award_points),
        ("Redeem Points", test_redeem_points),
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
        
        time.sleep(1)  # Small delay between tests
    
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
        print("🎉 All tests passed! Loyalty backend is working correctly.")
    else:
        print("⚠️  Some tests failed. Check the backend configuration.")

if __name__ == "__main__":
    main() 
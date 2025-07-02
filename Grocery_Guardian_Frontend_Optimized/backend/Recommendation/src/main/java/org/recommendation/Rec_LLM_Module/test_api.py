import requests
import json

def test_recommendation_api():
    """测试推荐API"""
    url = "http://localhost:8001/recommendations/barcode"
    data = {
        "userId": 1,
        "productBarcode": "10596975"
    }
    
    try:
        response = requests.post(url, json=data, timeout=30)
        print(f"状态码: {response.status_code}")
        print(f"响应内容: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"成功: {result.get('success')}")
            print(f"消息: {result.get('message')}")
            if result.get('data'):
                print(f"推荐数量: {len(result['data'].get('recommendations', []))}")
        else:
            print(f"请求失败: {response.status_code}")
            
    except requests.exceptions.RequestException as e:
        print(f"请求异常: {e}")
    except json.JSONDecodeError as e:
        print(f"JSON解析错误: {e}")
    except Exception as e:
        print(f"其他错误: {e}")

if __name__ == "__main__":
    test_recommendation_api() 
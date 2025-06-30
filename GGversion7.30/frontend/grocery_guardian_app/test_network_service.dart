import 'lib/services/network_service.dart';

void main() async {
  print('Starting Grocery Guardian Network Service Test...\n');
  
  // 打印网络诊断报告
  await NetworkService.printDiagnosticReport();
  
  print('Test completed!');
}
import 'scan_history_item.dart';
import 'scan_history_pagination.dart';

class ScanHistoryResponse {
  final List<ScanHistoryItem> items;
  final ScanHistoryPagination pagination;
  
  ScanHistoryResponse({
    required this.items,
    required this.pagination,
  });
  
  factory ScanHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ScanHistoryResponse(
      items: (json['items'] as List<dynamic>)
          .map((item) => ScanHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: ScanHistoryPagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
enum ReceiptLoadingStage {
  uploaded,           // 小票已上传
  ocrProcessing,      // OCR识别中
  analyzingItems,     // 商品分析中
  completed,          // 完成
  error,              // 错误
}

class ReceiptLoadingState {
  final ReceiptLoadingStage stage;
  final double progress;
  final String message;
  final String? secondaryMessage;
  final bool isCompleted;
  final String? errorMessage;

  const ReceiptLoadingState({
    required this.stage,
    required this.progress,
    required this.message,
    this.secondaryMessage,
    this.isCompleted = false,
    this.errorMessage,
  });

  factory ReceiptLoadingState.uploaded() {
    return const ReceiptLoadingState(
      stage: ReceiptLoadingStage.uploaded,
      progress: 0.25,
      message: 'Receipt Uploaded Successfully',
      secondaryMessage: 'Starting OCR processing...',
    );
  }

  factory ReceiptLoadingState.ocrProcessing() {
    return const ReceiptLoadingState(
      stage: ReceiptLoadingStage.ocrProcessing,
      progress: 0.5,
      message: 'Processing Receipt Content',
      secondaryMessage: 'Extracting product information from your receipt...',
    );
  }

  factory ReceiptLoadingState.analyzingItems() {
    return const ReceiptLoadingState(
      stage: ReceiptLoadingStage.analyzingItems,
      progress: 0.75,
      message: 'Analyzing Your Purchase',
      secondaryMessage: 'Generating personalized nutrition recommendations...',
    );
  }

  factory ReceiptLoadingState.completed() {
    return const ReceiptLoadingState(
      stage: ReceiptLoadingStage.completed,
      progress: 1.0,
      message: 'Analysis Complete',
      secondaryMessage: 'Your receipt analysis is ready!',
      isCompleted: true,
    );
  }

  factory ReceiptLoadingState.error(String error) {
    return ReceiptLoadingState(
      stage: ReceiptLoadingStage.error,
      progress: 0.0,
      message: 'Processing Failed',
      secondaryMessage: error,
      errorMessage: error,
    );
  }
}
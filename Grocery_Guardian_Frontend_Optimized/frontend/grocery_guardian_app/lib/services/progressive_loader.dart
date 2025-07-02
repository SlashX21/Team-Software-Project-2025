import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/entities/product_analysis.dart';
import 'api_service.dart';
import 'performance_monitor.dart';
import 'error_handler.dart';

/// Progressive data loading service
class ProgressiveLoader {
  static final ProgressiveLoader _instance = ProgressiveLoader._internal();
  factory ProgressiveLoader() => _instance;
  ProgressiveLoader._internal();

  final Map<String, ProductLoadingState> _loadingStates = {};
  final Map<String, StreamController<ProductLoadingState>> _controllers = {};

  /// Get progressive loading stream for product information
  Stream<ProductLoadingState> loadProduct({
    required String barcode,
    required int userId,
  }) {
    final key = '${barcode}_$userId';
    
    // If already loading, return existing stream
    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<ProductLoadingState>.broadcast();
    _controllers[key] = controller;

    // Start progressive loading
    _startProgressiveLoading(barcode, userId, controller);

    return controller.stream;
  }

  /// Start progressive loading process
  Future<void> _startProgressiveLoading(
    String barcode,
    int userId,
    StreamController<ProductLoadingState> controller,
  ) async {
    final monitor = PerformanceMonitor();
    final errorHandler = ErrorHandler();
    final key = '${barcode}_$userId';

    try {
      // Stage 1: Initialize loading state
      final initialState = ProductLoadingState(
        stage: LoadingStage.initializing,
        progress: 0.0,
        message: 'Starting scan...',
      );
      _loadingStates[key] = initialState;
      controller.add(initialState);

      await Future.delayed(Duration(milliseconds: 200));

      // Stage 2: Detect barcode
      final detectionState = ProductLoadingState(
        stage: LoadingStage.detecting,
        progress: 0.1,
        message: 'Detecting barcode...',
      );
      _loadingStates[key] = detectionState;
      controller.add(detectionState);

      await Future.delayed(Duration(milliseconds: 300));

      // Stage 3: Fetch basic product information
      final basicInfoState = ProductLoadingState(
        stage: LoadingStage.fetchingBasicInfo,
        progress: 0.3,
        message: 'Querying product database...',
      );
      _loadingStates[key] = basicInfoState;
      controller.add(basicInfoState);

      monitor.startTimer('basic_product_fetch');
      
      try {
        // Quickly fetch basic information
        final basicProduct = await ApiService.fetchProductByBarcode(barcode, 0); // 不包含推荐
        
        final basicDuration = monitor.endTimer('basic_product_fetch');

        // Stage 4: Display basic information
        final basicLoadedState = ProductLoadingState(
          stage: LoadingStage.basicInfoLoaded,
          progress: 0.6,
          message: 'Basic information loaded',
          product: basicProduct,
          loadTime: basicDuration,
        );
        _loadingStates[key] = basicLoadedState;
        controller.add(basicLoadedState);

        // Stage 5: Get personalized recommendations (async)
        if (userId > 0) {
          final recommendationState = ProductLoadingState(
            stage: LoadingStage.fetchingRecommendations,
            progress: 0.8,
            message: 'Getting personalized recommendations...',
            product: basicProduct,
            loadTime: basicDuration,
          );
          _loadingStates[key] = recommendationState;
          controller.add(recommendationState);

          // Asynchronously fetch recommendation information
          _loadRecommendationsAsync(barcode, userId, basicProduct, controller, key);
        } else {
          // No user ID, complete directly
          _completeLoading(controller, key, basicProduct, basicDuration);
        }

      } catch (e) {
        // Basic information loading failed
        final errorState = ProductLoadingState(
          stage: LoadingStage.error,
          progress: 0.3,
          message: 'Product information failed to load',
          error: errorHandler.handleApiError(e, context: 'product'),
        );
        _loadingStates[key] = errorState;
        controller.add(errorState);
      }

    } catch (e) {
      // Overall loading failed
      final errorState = ProductLoadingState(
        stage: LoadingStage.error,
        progress: 0.0,
        message: 'Scan failed',
        error: errorHandler.handleApiError(e),
      );
      _loadingStates[key] = errorState;
      controller.add(errorState);
    }
  }

  /// Asynchronously load recommendation information
  Future<void> _loadRecommendationsAsync(
    String barcode,
    int userId,
    ProductAnalysis basicProduct,
    StreamController<ProductLoadingState> controller,
    String key,
  ) async {
    final monitor = PerformanceMonitor();

    try {
      monitor.startTimer('recommendations_fetch');
      
      // Try to get complete product information within timeout (including LLM recommendations)
      final completeProduct = await ApiService.fetchProductByBarcode(barcode, userId)
          .timeout(Duration(seconds: 5), onTimeout: () {
        print('⏰ LLM recommendations timed out after 5 seconds');
        throw TimeoutException('LLM recommendations timed out', Duration(seconds: 5));
      });
      
      final recDuration = monitor.endTimer('recommendations_fetch');

      // If LLM recommendations were obtained, use complete data; otherwise use enhanced basic data
      final enhancedProduct = _enhanceProductWithFallback(completeProduct, basicProduct);

      _completeLoading(controller, key, enhancedProduct, recDuration);

    } on TimeoutException catch (e) {
      // LLM recommendations timed out, use local enhanced data
      print('⏰ LLM timeout, using fallback recommendations: $e');
      final fallbackProduct = _createFallbackRecommendations(basicProduct);
      
      final partialCompleteState = ProductLoadingState(
        stage: LoadingStage.completed,
        progress: 1.0,
        message: 'Loading complete (using local recommendations)',
        product: fallbackProduct,
        loadTime: Duration(seconds: 5),
        hasPartialData: true,
      );
      _loadingStates[key] = partialCompleteState;
      controller.add(partialCompleteState);
      controller.close();
      _controllers.remove(key);
      
    } catch (e) {
      // Recommendation loading failed, but keep basic information
      print('❌ Recommendations failed to load: $e');
      
      final fallbackProduct = _createFallbackRecommendations(basicProduct);
      
      final partialCompleteState = ProductLoadingState(
        stage: LoadingStage.completed,
        progress: 1.0,
        message: 'Loading complete (personalized recommendations temporarily unavailable)',
        product: fallbackProduct,
        loadTime: Duration.zero,
        hasPartialData: true,
      );
      _loadingStates[key] = partialCompleteState;
      controller.add(partialCompleteState);
      controller.close();
      _controllers.remove(key);
    }
  }

  /// Enhance product information, combining LLM and basic data
  ProductAnalysis _enhanceProductWithFallback(ProductAnalysis? llmProduct, ProductAnalysis basicProduct) {
    if (llmProduct != null && 
        (llmProduct.summary.isNotEmpty || 
         llmProduct.detailedAnalysis.isNotEmpty || 
         llmProduct.actionSuggestions.isNotEmpty)) {
      // LLM data available, use LLM data
      return llmProduct;
    }
    
    // LLM data not available, use local enhancement
    return _createFallbackRecommendations(basicProduct);
  }

  /// Create local fallback recommendations
  ProductAnalysis _createFallbackRecommendations(ProductAnalysis basicProduct) {
    String summary = 'Product information loaded successfully.';
    String detailedAnalysis = '';
    List<String> suggestions = [];

    // Generate simple recommendations based on ingredients and allergens
    if (basicProduct.detectedAllergens.isNotEmpty) {
              summary += 'Allergens detected: ${basicProduct.detectedAllergens.join(', ')}.';
              suggestions.add('If you are allergic to ${basicProduct.detectedAllergens.join(', ')}, please avoid consuming this product');
    } else {
              summary += 'No common allergens detected.';
    }

    if (basicProduct.ingredients.isNotEmpty) {
      detailedAnalysis = 'Main ingredients include: ${basicProduct.ingredients.take(5).join(', ')}';
      if (basicProduct.ingredients.length > 5) {
                  detailedAnalysis += ' and ${basicProduct.ingredients.length - 5} more ingredients';
      }
              suggestions.add('Please check the complete ingredient list');
              suggestions.add('Consume in moderation as part of a balanced diet');
    }

    if (suggestions.isEmpty) {
      suggestions.addAll(['Consume in moderation', 'Maintain nutritional balance', 'Consult a professional if you have questions']);
    }

    return basicProduct.copyWith(
      summary: summary,
      detailedAnalysis: detailedAnalysis,
      actionSuggestions: suggestions,
    );
  }

  /// Complete loading process
  void _completeLoading(
    StreamController<ProductLoadingState> controller,
    String key,
    ProductAnalysis product,
    Duration loadTime,
  ) {
    final completeState = ProductLoadingState(
      stage: LoadingStage.completed,
      progress: 1.0,
      message: 'Loading complete',
      product: product,
      loadTime: loadTime,
    );
    _loadingStates[key] = completeState;
    controller.add(completeState);
    controller.close();
    _controllers.remove(key);
  }

  /// Cancel loading
  void cancelLoading(String barcode, int userId) {
    final key = '${barcode}_$userId';
    final controller = _controllers[key];
    if (controller != null) {
      controller.close();
      _controllers.remove(key);
      _loadingStates.remove(key);
    }
  }

  /// Get current loading state
  ProductLoadingState? getCurrentState(String barcode, int userId) {
    final key = '${barcode}_$userId';
    return _loadingStates[key];
  }

  /// Clean up resources
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _loadingStates.clear();
  }
}

/// Loading stage enumeration
enum LoadingStage {
  initializing,          // Initialize
  detecting,            // Detect barcode
  fetchingBasicInfo,    // Fetch basic information
  basicInfoLoaded,      // Basic information loaded
  fetchingRecommendations, // Fetch recommendation information
  completed,            // Fully loaded complete
  error,                // Error state
}

/// Product loading state
class ProductLoadingState {
  final LoadingStage stage;
  final double progress;
  final String message;
  final ProductAnalysis? product;
  final Duration? loadTime;
  final ApiErrorResult? error;
  final bool hasPartialData;

  ProductLoadingState({
    required this.stage,
    required this.progress,
    required this.message,
    this.product,
    this.loadTime,
    this.error,
    this.hasPartialData = false,
  });

  bool get isLoading => stage != LoadingStage.completed && stage != LoadingStage.error;
  bool get hasError => stage == LoadingStage.error;
  bool get isCompleted => stage == LoadingStage.completed;
  bool get hasBasicInfo => product != null;

  @override
  String toString() {
    return 'ProductLoadingState(stage: $stage, progress: $progress, message: $message)';
  }
}

/// Product analysis extension, add copyWith method
extension ProductAnalysisExtension on ProductAnalysis {
  ProductAnalysis copyWith({
    String? name,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? detectedAllergens,
    String? summary,
    String? detailedAnalysis,
    List<String>? actionSuggestions,
  }) {
    return ProductAnalysis(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      detectedAllergens: detectedAllergens ?? this.detectedAllergens,
      summary: summary ?? this.summary,
      detailedAnalysis: detailedAnalysis ?? this.detailedAnalysis,
      actionSuggestions: actionSuggestions ?? this.actionSuggestions,
    );
  }
}
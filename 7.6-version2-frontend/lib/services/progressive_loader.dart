import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/entities/product_analysis.dart';
import 'api_service.dart';
import 'api.dart';
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
        print('🔍 Fetching product with barcode: $barcode');
        final basicProduct = await fetchProductByBarcode(barcode, 0); // Exclude recommendations
        print('✅ Product fetch result: ${basicProduct.name}');
        
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
        print('❌ Product fetch failed for barcode $barcode: $e');
        print('❌ Error type: ${e.runtimeType}');
        print('❌ Error details: ${e.toString()}');
        
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
    final errorHandler = ErrorHandler();

    try {
      monitor.startTimer('recommendations_fetch');
      
      // Try to get complete product information within timeout (including LLM recommendations)
      final completeProduct = await fetchProductByBarcode(barcode, userId)
          .timeout(Duration(seconds: 30), onTimeout: () {
        print('⏰ LLM recommendations timed out after 30 seconds');
        // Return a product with a timeout message instead of throwing an error.
        return basicProduct.copyWith(
          summary: 'AI Analysis in Progress',
          detailedAnalysis: 'AI analysis is taking longer than expected. The basic product information is available.',
        );
      });
      
      final recDuration = monitor.endTimer('recommendations_fetch');

      // Use complete product data from recommendation system
      _completeLoading(controller, key, completeProduct, recDuration);

    } catch (e) {
      // Recommendation loading failed, but we have basic data, so we proceed.
      print('❌ Recommendations failed to load: $e');
      
      final productWithError = basicProduct.copyWith(
        summary: 'AI Analysis Unavailable',
        detailedAnalysis: 'AI analysis service is currently unavailable. Basic product information is shown.',
      );

      _completeLoading(controller, key, productWithError, Duration.zero);
    }
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
    List<ProductAnalysis>? recommendations,
    String? barcode,
  }) {
    return ProductAnalysis(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      detectedAllergens: detectedAllergens ?? this.detectedAllergens,
      summary: summary ?? this.summary,
      detailedAnalysis: detailedAnalysis ?? this.detailedAnalysis,
      actionSuggestions: actionSuggestions ?? this.actionSuggestions,
      recommendations: recommendations ?? this.recommendations,
      barcode: barcode ?? this.barcode,
    );
  }
}
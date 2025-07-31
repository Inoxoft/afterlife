import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';

/// A reusable widget that provides loading states and error boundaries
/// to improve UX across the application
class LoadingErrorWrapper extends StatelessWidget {
  const LoadingErrorWrapper({
    super.key,
    required this.child,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.loadingMessage = 'Loading...',
    this.showSpinner = true,
    this.showLoadingText = true,
    this.customLoadingWidget,
    this.customErrorWidget,
  });

  final Widget child;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final String loadingMessage;
  final bool showSpinner;
  final bool showLoadingText;
  final Widget? customLoadingWidget;
  final Widget? customErrorWidget;

  @override
  Widget build(BuildContext context) {
    // Log loading and error states for debugging
    if (isLoading) {
      AppLogger.debug('LoadingErrorWrapper: Loading state active', tag: 'UI');
    }
    if (error != null) {
      AppLogger.warning(
        'LoadingErrorWrapper: Error state active',
        context: {'error': error},
      );
    }

    // Show error state
    if (error != null && !isLoading) {
      return customErrorWidget ?? _buildErrorWidget(context);
    }

    // Show loading state
    if (isLoading) {
      return customLoadingWidget ?? _buildLoadingWidget(context);
    }

    // Show content
    return child;
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warmGold),
              ),
            ),
            if (showLoadingText) const SizedBox(height: 16),
          ],
          if (showLoadingText)
            Text(
              loadingMessage,
              style: TextStyle(color: AppTheme.silverMist, fontSize: 16),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTheme.titleStyle.copyWith(
              color: AppTheme.silverMist,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(
              color: AppTheme.silverMist.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warmGold,
                foregroundColor: AppTheme.deepIndigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}

/// A specialized loading wrapper for async operations
class AsyncLoadingWrapper extends StatelessWidget {
  const AsyncLoadingWrapper({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.onRetry,
  });

  final Future future;
  final Widget Function(dynamic data) builder;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const LoadingErrorWrapper(
                isLoading: true,
                child: SizedBox.shrink(),
              );
        }

        if (snapshot.hasError) {
          final errorMessage = snapshot.error.toString();
          AppLogger.error(
            'AsyncLoadingWrapper: Future failed',
            error: snapshot.error,
          );

          return errorBuilder?.call(errorMessage) ??
              LoadingErrorWrapper(
                error: errorMessage,
                onRetry: onRetry,
                child: const SizedBox.shrink(),
              );
        }

        if (!snapshot.hasData) {
          return LoadingErrorWrapper(
            error: 'No data received',
            onRetry: onRetry,
            child: const SizedBox.shrink(),
          );
        }

        return builder(snapshot.data);
      },
    );
  }
}

/// Extension to easily wrap any widget with loading/error states
extension LoadingErrorExtension on Widget {
  Widget withLoadingError({
    bool isLoading = false,
    String? error,
    VoidCallback? onRetry,
    String loadingMessage = 'Loading...',
  }) {
    return LoadingErrorWrapper(
      isLoading: isLoading,
      error: error,
      onRetry: onRetry,
      loadingMessage: loadingMessage,
      child: this,
    );
  }
}

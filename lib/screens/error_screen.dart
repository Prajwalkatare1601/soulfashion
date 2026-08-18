import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

enum AppErrorType {
  invalidCredentials,
  noInternet,
  unexpected;

  static AppErrorType fromException(dynamic exception) {
    final errStr = exception.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('network_error') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('connection failed') ||
        errStr.contains('handshake failed') ||
        errStr.contains('network') ||
        errStr.contains('internet')) {
      return AppErrorType.noInternet;
    } else if (errStr.contains('invalid login credentials') ||
        errStr.contains('invalid credentials') ||
        errStr.contains('email not confirmed') ||
        errStr.contains('user_not_found') ||
        errStr.contains('invalid_grant')) {
      return AppErrorType.invalidCredentials;
    }
    return AppErrorType.unexpected;
  }
}

class ErrorScreen extends StatelessWidget {
  final AppErrorType errorType;
  final String technicalDetails;
  final VoidCallback? onRetry;

  const ErrorScreen({
    Key? key,
    required this.errorType,
    required this.technicalDetails,
    this.onRetry,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required dynamic exception,
    VoidCallback? onRetry,
  }) async {
    final errorType = AppErrorType.fromException(exception);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ErrorScreen(
          errorType: errorType,
          technicalDetails: exception.toString(),
          onRetry: onRetry,
        ),
      ),
    );
  }

  String _getTitle() {
    switch (errorType) {
      case AppErrorType.invalidCredentials:
        return 'Incorrect Credentials';
      case AppErrorType.noInternet:
        return 'Connection Problem';
      case AppErrorType.unexpected:
      default:
        return 'Unexpected Error';
    }
  }

  String _getMessage() {
    switch (errorType) {
      case AppErrorType.invalidCredentials:
        return "The email address or password you entered doesn't match our records. Please verify your login details and try again.";
      case AppErrorType.noInternet:
        return "We can't connect to our servers. Please check your internet connection (Wi-Fi or mobile data) and try again.";
      case AppErrorType.unexpected:
      default:
        return "Something went wrong on our end. We couldn't complete the request. Please try again or contact support if the issue persists.";
    }
  }

  String _getImagePath() {
    switch (errorType) {
      case AppErrorType.invalidCredentials:
        return 'assets/images/login_error_illustration.png';
      case AppErrorType.noInternet:
        return 'assets/images/no_internet_illustration.png';
      case AppErrorType.unexpected:
      default:
        return 'assets/images/login_error_illustration.png';
    }
  }

  IconData _getIcon() {
    switch (errorType) {
      case AppErrorType.invalidCredentials:
        return Icons.lock_outline_rounded;
      case AppErrorType.noInternet:
        return Icons.wifi_off_rounded;
      case AppErrorType.unexpected:
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = _getImagePath();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Illustration Header
              Center(
                child: Container(
                  height: 260,
                  width: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if image load fails
                      return Container(
                        color: AppTheme.primary.withOpacity(0.05),
                        child: Icon(
                          _getIcon(),
                          size: 80,
                          color: AppTheme.primary.withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Error Title
              Text(
                _getTitle(),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Error Message
              Text(
                _getMessage(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Action buttons
              if (onRetry != null) ...[
                CustomButton(
                  text: 'Try Again',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry!();
                  },
                ),
                const SizedBox(height: 12),
              ],
              
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Go Back'),
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: Color(0xFFE3E8EE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Advanced technical section
              Card(
                color: theme.colorScheme.surface,
                elevation: 0,
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'Advanced details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    iconColor: AppTheme.textSecondary,
                    collapsedIconColor: AppTheme.textSecondary,
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              technicalDetails,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: technicalDetails),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Technical details copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Copy Details',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

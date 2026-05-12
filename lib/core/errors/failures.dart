// Abstract base class for all failures
abstract class Failure {
  final String message;
  final String? code;
  
  const Failure(this.message, {this.code});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;
  
  @override
  int get hashCode => message.hashCode ^ code.hashCode;
  
  @override
  String toString() => 'Failure{message: $message, code: $code}';
}

// Network related failures
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String? code}) : super(message, code: code);
  
  factory NetworkFailure.noConnection() {
    return const NetworkFailure('لا يوجد اتصال بالإنترنت', code: 'NO_CONNECTION');
  }
  
  factory NetworkFailure.timeout() {
    return const NetworkFailure('انتهت مهلة الاتصال', code: 'TIMEOUT');
  }
  
  factory NetworkFailure.serverError() {
    return const NetworkFailure('خطأ في الخادم', code: 'SERVER_ERROR');
  }
  
  factory NetworkFailure.unauthorized() {
    return const NetworkFailure('غير مصرح بالوصول', code: 'UNAUTHORIZED');
  }
  
  factory NetworkFailure.forbidden() {
    return const NetworkFailure('ممنوع الوصول', code: 'FORBIDDEN');
  }
  
  factory NetworkFailure.notFound() {
    return const NetworkFailure('الصفحة غير موجودة', code: 'NOT_FOUND');
  }
}

// Server related failures
class ServerFailure extends Failure {
  const ServerFailure(String message, {String? code}) : super(message, code: code);
  
  factory ServerFailure.databaseError() {
    return const ServerFailure('خطأ في قاعدة البيانات', code: 'DATABASE_ERROR');
  }
  
  factory ServerFailure.internalServerError() {
    return const ServerFailure('خطأ داخلي في الخادم', code: 'INTERNAL_SERVER_ERROR');
  }
  
  factory ServerFailure.serviceUnavailable() {
    return const ServerFailure('الخدمة غير متاحة', code: 'SERVICE_UNAVAILABLE');
  }
}

// Cache related failures
class CacheFailure extends Failure {
  const CacheFailure(String message, {String? code}) : super(message, code: code);
  
  factory CacheFailure.notFound() {
    return const CacheFailure('البيانات غير موجودة في الذاكرة المؤقتة', code: 'CACHE_NOT_FOUND');
  }
  
  factory CacheFailure.writeError() {
    return const CacheFailure('خطأ في كتابة البيانات', code: 'CACHE_WRITE_ERROR');
  }
  
  factory CacheFailure.readError() {
    return const CacheFailure('خطأ في قراءة البيانات', code: 'CACHE_READ_ERROR');
  }
  
  factory CacheFailure.clearError() {
    return const CacheFailure('خطأ في مسح البيانات', code: 'CACHE_CLEAR_ERROR');
  }
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {String? code}) : super(message, code: code);
  
  factory ValidationFailure.emptyField(String fieldName) {
    return ValidationFailure('حقل $fieldName لا يمكن أن يكون فارغاً', code: 'EMPTY_FIELD');
  }
  
  factory ValidationFailure.invalidEmail() {
    return const ValidationFailure('البريد الإلكتروني غير صحيح', code: 'INVALID_EMAIL');
  }
  
  factory ValidationFailure.invalidPhone() {
    return const ValidationFailure('رقم الهاتف غير صحيح', code: 'INVALID_PHONE');
  }
  
  factory ValidationFailure.invalidPassword() {
    return const ValidationFailure('كلمة المرور يجب أن تكون 8 أحرف على الأقل', code: 'INVALID_PASSWORD');
  }
  
  factory ValidationFailure.passwordMismatch() {
    return const ValidationFailure('كلمات المرور غير متطابقة', code: 'PASSWORD_MISMATCH');
  }
  
  factory ValidationFailure.invalidNumber(String fieldName) {
    return ValidationFailure('حقل $fieldName يجب أن يكون رقماً', code: 'INVALID_NUMBER');
  }
  
  factory ValidationFailure.invalidAmount() {
    return const ValidationFailure('المبلغ غير صحيح', code: 'INVALID_AMOUNT');
  }
  
  factory ValidationFailure.invalidDate() {
    return const ValidationFailure('التاريخ غير صحيح', code: 'INVALID_DATE');
  }
  
  factory ValidationFailure.duplicateValue(String fieldName) {
    return ValidationFailure('قيمة $fieldName مكررة', code: 'DUPLICATE_VALUE');
  }
  
  factory ValidationFailure.minLength(String fieldName, int length) {
    return ValidationFailure('حقل $fieldName يجب أن يكون $length أحرف على الأقل', code: 'MIN_LENGTH');
  }
  
  factory ValidationFailure.maxLength(String fieldName, int length) {
    return ValidationFailure('حقل $fieldName يجب أن يكون $length حرف كحد أقصى', code: 'MAX_LENGTH');
  }
}

// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure(String message, {String? code}) : super(message, code: code);
  
  factory PermissionFailure.denied() {
    return const PermissionFailure('تم رفض الإذن', code: 'PERMISSION_DENIED');
  }
  
  factory PermissionFailure.permanentlyDenied() {
    return const PermissionFailure('تم رفض الإذن بشكل دائم', code: 'PERMISSION_PERMANENTLY_DENIED');
  }
  
  factory PermissionFailure.restricted() {
    return const PermissionFailure('الإذن مقيد', code: 'PERMISSION_RESTRICTED');
  }
  
  factory PermissionFailure.limited() {
    return const PermissionFailure('الإذن محدود', code: 'PERMISSION_LIMITED');
  }
}

// Business logic failures
class BusinessFailure extends Failure {
  const BusinessFailure(String message, {String? code}) : super(message, code: code);
  
  factory BusinessFailure.insufficientStock() {
    return const BusinessFailure('المخزون غير كافٍ', code: 'INSUFFICIENT_STOCK');
  }
  
  factory BusinessFailure.productNotFound() {
    return const BusinessFailure('المنتج غير موجود', code: 'PRODUCT_NOT_FOUND');
  }
  
  factory BusinessFailure.customerNotFound() {
    return const BusinessFailure('العميل غير موجود', code: 'CUSTOMER_NOT_FOUND');
  }
  
  factory BusinessFailure.supplierNotFound() {
    return const BusinessFailure('المورد غير موجود', code: 'SUPPLIER_NOT_FOUND');
  }
  
  factory BusinessFailure.invoiceNotFound() {
    return const BusinessFailure('الفاتورة غير موجودة', code: 'INVOICE_NOT_FOUND');
  }
  
  factory BusinessFailure.invoiceAlreadyPaid() {
    return const BusinessFailure('الفاتورة مدفوعة بالفعل', code: 'INVOICE_ALREADY_PAID');
  }
  
  factory BusinessFailure.invalidInvoiceStatus() {
    return const BusinessFailure('حالة الفاتورة غير صحيحة', code: 'INVALID_INVOICE_STATUS');
  }
  
  factory BusinessFailure.negativeBalance() {
    return const BusinessFailure('الرصيد سالب', code: 'NEGATIVE_BALANCE');
  }
  
  factory BusinessFailure.creditLimitExceeded() {
    return const BusinessFailure('تم تجاوز حد الائتمان', code: 'CREDIT_LIMIT_EXCEEDED');
  }
}

// File handling failures
class FileFailure extends Failure {
  const FileFailure(String message, {String? code}) : super(message, code: code);
  
  factory FileFailure.notFound() {
    return const FileFailure('الملف غير موجود', code: 'FILE_NOT_FOUND');
  }
  
  factory FileFailure.readError() {
    return const FileFailure('خطأ في قراءة الملف', code: 'FILE_READ_ERROR');
  }
  
  factory FileFailure.writeError() {
    return const FileFailure('خطأ في كتابة الملف', code: 'FILE_WRITE_ERROR');
  }
  
  factory FileFailure.invalidFormat() {
    return const FileFailure('تنسيق الملف غير صحيح', code: 'INVALID_FORMAT');
  }
  
  factory FileFailure.sizeExceeded() {
    return const FileFailure('حجم الملف يتجاوز الحد المسموح', code: 'SIZE_EXCEEDED');
  }
}

// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(String message, {String? code}) : super(message, code: code);
  
  factory AuthFailure.invalidCredentials() {
    return const AuthFailure('البريد الإلكتروني أو كلمة المرور غير صحيحة', code: 'INVALID_CREDENTIALS');
  }
  
  factory AuthFailure.userNotFound() {
    return const AuthFailure('المستخدم غير موجود', code: 'USER_NOT_FOUND');
  }
  
  factory AuthFailure.emailAlreadyExists() {
    return const AuthFailure('البريد الإلكتروني مستخدم بالفعل', code: 'EMAIL_ALREADY_EXISTS');
  }
  
  factory AuthFailure.weakPassword() {
    return const AuthFailure('كلمة المرور ضعيفة', code: 'WEAK_PASSWORD');
  }
  
  factory AuthFailure.sessionExpired() {
    return const AuthFailure('انتهت الجلسة', code: 'SESSION_EXPIRED');
  }
  
  factory AuthFailure.tokenInvalid() {
    return const AuthFailure('الرمز غير صحيح', code: 'TOKEN_INVALID');
  }
  
  factory AuthFailure.accountDisabled() {
    return const AuthFailure('الحساب معطل', code: 'ACCOUNT_DISABLED');
  }
  
  factory AuthFailure.emailNotVerified() {
    return const AuthFailure('البريد الإلكتروني غير مؤكد', code: 'EMAIL_NOT_VERIFIED');
  }
}

// Utility function to convert exceptions to failures
Failure exceptionToFailure(dynamic exception) {
  if (exception is Failure) return exception;
  
  // Handle common exceptions
  final message = exception.toString();
  if (message.contains('SocketException')) {
    return NetworkFailure.noConnection();
  }
  if (message.contains('TimeoutException')) {
    return NetworkFailure.timeout();
  }
  if (message.contains('HttpException')) {
    return NetworkFailure.serverError();
  }
  if (message.contains('FormatException')) {
    return ServerFailure.internalServerError();
  }
  
  // Default fallback
  return ServerFailure.internalServerError();
}

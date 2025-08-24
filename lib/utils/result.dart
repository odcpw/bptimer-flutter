/// `Result<T, E>` - Result-based error handling for BPtimer
/// 
/// Provides explicit success/error states to replace exception throwing.
/// Matches the PWA's preference for result-based error handling over try-catch blocks.
/// 
/// Usage:
/// ```dart
/// Result<String, String> operation() {
///   if (success) return Success('data');
///   return Failure('error message');
/// }
/// ```

library;

/// Base result type for operations that can succeed or fail
abstract class Result<T, E> {
  const Result();
  
  /// Check if this result represents success
  bool get isSuccess => this is Success<T, E>;
  
  /// Check if this result represents failure
  bool get isFailure => this is Failure<T, E>;
  
  /// Get success data (null if failure)
  T? get data => isSuccess ? (this as Success<T, E>).data : null;
  
  /// Get error information (null if success)
  E? get error => isFailure ? (this as Failure<T, E>).error : null;
  
  /// Transform success data with a function
  Result<U, E> map<U>(U Function(T) transform) {
    if (isSuccess) {
      return Success(transform((this as Success<T, E>).data));
    }
    return Failure((this as Failure<T, E>).error);
  }
  
  /// Transform error with a function
  Result<T, F> mapError<F>(F Function(E) transform) {
    if (isFailure) {
      return Failure(transform((this as Failure<T, E>).error));
    }
    return Success((this as Success<T, E>).data);
  }
  
  /// Execute function on success, return original result
  Result<T, E> onSuccess(void Function(T) action) {
    if (isSuccess) {
      action((this as Success<T, E>).data);
    }
    return this;
  }
  
  /// Execute function on failure, return original result
  Result<T, E> onFailure(void Function(E) action) {
    if (isFailure) {
      action((this as Failure<T, E>).error);
    }
    return this;
  }
  
  /// Get data or default value if failure
  T getOrElse(T defaultValue) {
    return isSuccess ? (this as Success<T, E>).data : defaultValue;
  }
  
  /// Get data or compute default value if failure
  T getOrCompute(T Function() computeDefault) {
    return isSuccess ? (this as Success<T, E>).data : computeDefault();
  }
}

/// Success result containing data
class Success<T, E> extends Result<T, E> {
  @override
  final T data;
  
  const Success(this.data);
  
  @override
  bool operator ==(Object other) {
    return other is Success<T, E> && other.data == data;
  }
  
  @override
  int get hashCode => data.hashCode;
  
  @override
  String toString() => 'Success($data)';
}

/// Failure result containing error information
class Failure<T, E> extends Result<T, E> {
  @override
  final E error;
  
  const Failure(this.error);
  
  @override
  bool operator ==(Object other) {
    return other is Failure<T, E> && other.error == error;
  }
  
  @override
  int get hashCode => error.hashCode;
  
  @override
  String toString() => 'Failure($error)';
}

/// Common error messages for database operations
class DatabaseError {
  static const String connectionFailed = 'Failed to connect to database';
  static const String saveFailed = 'Failed to save data';
  static const String loadFailed = 'Failed to load data';
  static const String deleteFailed = 'Failed to delete data';
  static const String updateFailed = 'Failed to update data';
  static const String notFound = 'Record not found';
  static const String invalidData = 'Invalid data format';
  static const String storageError = 'Storage operation failed';
}

/// Common error messages for favorites operations
class FavoritesError {
  static const String nameTooShort = 'Favorite name cannot be empty';
  static const String noPractices = 'Favorite must have at least one practice';
  static const String nameExists = 'A favorite with this name already exists';
  static const String limitReached = 'Maximum number of favorites reached';
  static const String notFound = 'Favorite not found';
  static const String saveFailed = 'Failed to save favorite';
  static const String loadFailed = 'Failed to load favorites';
}

/// Common error messages for timer operations
class TimerError {
  static const String alreadyRunning = 'Timer is already running';
  static const String notRunning = 'Timer is not running';
  static const String sessionTooShort = 'Session too short to save';
  static const String audioFailed = 'Failed to play audio';
  static const String saveFailed = 'Failed to save session';
  static const String invalidDuration = 'Invalid duration specified';
}

/// Type aliases for common Result patterns
typedef DatabaseResult<T> = Result<T, String>;
typedef SimpleResult = Result<bool, String>;
typedef VoidResult = Result<void, String>;
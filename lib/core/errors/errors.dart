sealed class AuthFailure implements Exception {
  String get message;
  const AuthFailure();
}

class AuthInvalidEmail extends AuthFailure {
  @override
  String get message => 'Invalid email address.';
  const AuthInvalidEmail();
}

class AuthWrongPassword extends AuthFailure {
  @override
  String get message => 'Incorrect password.';
  const AuthWrongPassword();
}

class AuthInvalidCredentials extends AuthFailure {
  @override
  String get message => 'Invalid email or password.';
  const AuthInvalidCredentials();
}

class AuthUserNotFound extends AuthFailure {
  @override
  String get message => 'No account found with this email.';
  const AuthUserNotFound();
}

class AuthEmailAlreadyInUse extends AuthFailure {
  @override
  String get message => 'An account already exists with this email.';
  const AuthEmailAlreadyInUse();
}

class AuthWeakPassword extends AuthFailure {
  @override
  String get message => 'Password is too weak.';
  const AuthWeakPassword();
}

class AuthNetworkError extends AuthFailure {
  @override
  String get message => 'Network error. Check your connection.';
  const AuthNetworkError();
}

class AuthUnknown extends AuthFailure {
  @override
  final String message;
  const AuthUnknown(this.message);
}

sealed class TaskFailure implements Exception {
  String get message;
  const TaskFailure();
}

class TaskNotFound extends TaskFailure {
  @override
  String get message => 'Task not found.';
  const TaskNotFound();
}

class TaskPermissionDenied extends TaskFailure {
  @override
  String get message => 'You do not have permission to perform this action.';
  const TaskPermissionDenied();
}

class TaskNetworkError extends TaskFailure {
  @override
  String get message => 'Network error. Please check your connection.';
  const TaskNetworkError();
}

class TaskUnknown extends TaskFailure {
  @override
  final String message;
  const TaskUnknown(this.message);
}

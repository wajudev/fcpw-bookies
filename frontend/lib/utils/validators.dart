class Validators {
  static String? scoreValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a score';
    }

    final score = int.tryParse(value);
    if (score == null) {
      return 'Must be a number';
    }

    if (score < 0) {
      return 'Score cannot be negative';
    }

    if (score > 99) {
      return 'Score cannot exceed 99';
    }

    return null; // Valid
  }

  static String? usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.length > 20) {
      return 'Username cannot exceed 20 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? goalsValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final goals = int.tryParse(value);
    if (goals == null) {
      return 'Must be a number';
    }

    if (goals < 0) {
      return 'Goals cannot be negative';
    }

    if (goals > 999) {
      return 'Goals cannot exceed 999';
    }

    return null;
  }
}

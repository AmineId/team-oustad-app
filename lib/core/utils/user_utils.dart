/// Utility functions for user data handling

/// Get full name from user data
/// Handles both old format (fullName) and new format (firstName + lastName)
String getUserFullName(Map<String, dynamic>? user, {String defaultValue = 'Sans nom'}) {
  if (user == null) return defaultValue;
  
  // Try fullName first (for existing users)
  final fullName = user['fullName'] as String?;
  if (fullName != null && fullName.isNotEmpty) {
    return fullName;
  }
  
  // Try firstName + lastName (for new format)
  final firstName = user['firstName'] as String?;
  final lastName = user['lastName'] as String?;
  
  if (firstName != null && lastName != null) {
    return '$firstName $lastName'.trim();
  } else if (firstName != null) {
    return firstName;
  } else if (lastName != null) {
    return lastName;
  }
  
  return defaultValue;
}

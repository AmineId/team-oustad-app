/// Utility functions for user data handling
library;

/// Get full name from user data
/// Handles both old format (fullName) and new format (firstName + lastName)
String getUserFullName(Map<String, dynamic>? user, {String defaultValue = 'Sans nom'}) {
  if (user == null) return defaultValue;
  
  // Try fullName first (for existing users)
  final fullName = user['fullName']?.toString();
  if (fullName != null && fullName.isNotEmpty) {
    return fullName;
  }
  
  // Try firstName + lastName (for new format)
  final firstName = user['firstName']?.toString();
  final lastName = user['lastName']?.toString();
  
  if (firstName != null && lastName != null) {
    return '$firstName $lastName'.trim();
  } else if (firstName != null) {
    return firstName;
  } else if (lastName != null) {
    return lastName;
  }
  
  return defaultValue;
}

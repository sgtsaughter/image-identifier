extension StringExtensions on String {
  String toCapitalize() {
    if (isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
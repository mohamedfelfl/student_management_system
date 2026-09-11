import '../constants/app_constants.dart';

/// Helper utility for extracting and normalizing student serial numbers
/// from raw QR code data, barcode scanner inputs, and printed ID card payloads.
class QrCodeHelper {
  // Regex matching standard prefixed serials like EM-01-00003, EL-01-00003, EM-10777, etc.
  static final RegExp _prefixedSerialPattern = RegExp(
    r'[A-Za-z]{2,4}-\d+(?:-\d+)*',
    caseSensitive: false,
  );

  // Regex matching pure numeric serial numbers (e.g. 10777, 40777, 10000-69999)
  static final RegExp _numericSerialPattern = RegExp(
    r'\b\d{4,8}\b',
  );

  // Regex matching complete prefixed serial pattern
  static final RegExp _completePrefixedSerial = RegExp(
    r'^[A-Za-z]{2,4}-\d+(?:-\d+)*$',
    caseSensitive: false,
  );

  /// Checks if the input already contains a complete standard or legacy serial.
  /// Used for early trigger in hardware scanner streams before trailing characters arrive.
  static bool hasCompleteSerial(String? rawInput) {
    if (rawInput == null || rawInput.isEmpty) return false;
    final trimmed = rawInput.trim();
    if (_completePrefixedSerial.hasMatch(trimmed)) return true;
    if (_numericSerialPattern.hasMatch(trimmed) && trimmed.length >= 5) return true;
    return false;
  }

  /// Extracts the primary clean student serial number from scanned QR code data or user input.
  static String extractSerialNumber(String? rawInput) {
    if (rawInput == null) return '';
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return '';

    // 1. Check for prefixed serial (e.g. EM-10777, EL-01-00003)
    final prefixMatch = _prefixedSerialPattern.firstMatch(trimmed);
    if (prefixMatch != null) {
      return prefixMatch.group(0)!.toUpperCase();
    }

    // 2. If delimited by pipe, semicolon, colon, or comma, check segments
    final delimiterRegex = RegExp(r'[|:;,]');
    if (delimiterRegex.hasMatch(trimmed)) {
      final segments = trimmed
          .split(delimiterRegex)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final segment in segments) {
        final segMatch = _prefixedSerialPattern.firstMatch(segment);
        if (segMatch != null) {
          return segMatch.group(0)!.toUpperCase();
        }
        if (_numericSerialPattern.hasMatch(segment)) {
          return segment;
        }
        if (segment.toUpperCase().startsWith('${AppConstants.studentCodePrefix}-') ||
            segment.toUpperCase().startsWith(AppConstants.studentCodePrefix.toUpperCase())) {
          return segment.toUpperCase();
        }
      }

      // If no prefix match, check if any segment looks like stu_ legacy id
      for (final segment in segments) {
        if (segment.startsWith('stu_') || segment.startsWith('STU_')) {
          return segment;
        }
      }

      if (segments.isNotEmpty) {
        return segments.last;
      }
    }

    // 3. Check for standalone numeric serial (e.g. 10777, 40777)
    final numMatch = _numericSerialPattern.firstMatch(trimmed);
    if (numMatch != null) {
      return numMatch.group(0)!;
    }

    return trimmed;
  }

  /// Extracts all candidate tokens from the scanned payload in order of priority.
  /// For instance: `SMS|stu_bd02c7b92a2b49da8a|10777` -> `['10777', 'stu_bd02c7b92a2b49da8a', 'SMS']`.
  static List<String> extractAllCandidates(String? rawInput) {
    if (rawInput == null) return const [];
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return const [];

    final Set<String> candidates = {};

    // 1. Primary extracted serial
    final primary = extractSerialNumber(trimmed);
    if (primary.isNotEmpty) candidates.add(primary);

    // 2. Any other prefixed or numeric matches
    for (final m in _prefixedSerialPattern.allMatches(trimmed)) {
      final s = m.group(0)?.toUpperCase();
      if (s != null && s.isNotEmpty) candidates.add(s);
    }
    for (final m in _numericSerialPattern.allMatches(trimmed)) {
      final s = m.group(0);
      if (s != null && s.isNotEmpty) candidates.add(s);
    }

    // 3. Delimited segments
    final delimiterRegex = RegExp(r'[|:;,\-\s]');
    final parts = trimmed
        .split(delimiterRegex)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    for (final p in parts) {
      if (p.startsWith('stu_') || p.startsWith('STU_')) {
        candidates.add(p);
      } else if (RegExp(r'^\d+$').hasMatch(p)) {
        candidates.add(p);
      }
    }

    // 4. Raw trimmed string
    candidates.add(trimmed);

    return candidates.toList();
  }
}

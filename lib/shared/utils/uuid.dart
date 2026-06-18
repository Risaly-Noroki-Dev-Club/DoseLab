import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Centralised UUID generator so the random source is mockable in tests.
String newId() => _uuid.v4();

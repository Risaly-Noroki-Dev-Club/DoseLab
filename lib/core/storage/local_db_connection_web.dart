import 'package:drift/drift.dart';
// ignore: experimental_member_use
import 'package:drift/web.dart';

QueryExecutor openConnection() => WebDatabase('doselab');

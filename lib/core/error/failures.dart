import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Single sealed error type used at the boundary between data and
/// presentation layers. UI code should pattern-match with `.when()`
/// rather than relying on exceptions bubbling up.
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network({String? message, int? statusCode}) =
      NetworkFailure;

  const factory Failure.notFound({String? message}) = NotFoundFailure;

  const factory Failure.unmappedChinese(String input) = UnmappedChineseFailure;

  const factory Failure.storage({required String message}) = StorageFailure;

  const factory Failure.auth({required String message}) = AuthFailure;

  const factory Failure.parsing({required String message}) = ParsingFailure;

  const factory Failure.unknown({String? message}) = UnknownFailure;
}

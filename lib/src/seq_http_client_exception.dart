import 'package:dart_seq/dart_seq.dart';
import 'package:http/http.dart';

class SeqHttpClientException extends SeqClientException {
  SeqHttpClientException(
    String message, {
    Object? innerException,
    StackTrace? innerStackTrace,
    this.response,
  }) : super(message, innerException, innerStackTrace);

  final Response? response;
}
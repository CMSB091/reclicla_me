import 'dart:convert';
import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';
import 'package:http/http.dart' as http;

Duration linearBackoff(int tries) => Duration(milliseconds: tries * 100);

class SeqHttpClient implements SeqClient {
  SeqHttpClient({
    required String host,
    String? apiKey,
    int maxRetries = 5,
    Duration Function(int tries)? backoff,
  })  : assert(host.isNotEmpty, 'host must not be empty'),
        assert(host.startsWith('http'), 'the host must contain a scheme'),
        assert(null == apiKey || apiKey.isNotEmpty, 'apiKey must not be empty'),
        assert(maxRetries >= 0, 'maxRetries must be >= 0'),
        _headers = {
          'Content-Type': 'application/vnd.serilog.clef',
          if (apiKey != null) 'X-Seq-ApiKey': apiKey,
        },
        _maxRetries = maxRetries,
        _endpoint = Uri.parse('$host/api/events/raw'),
        _backoff = backoff ?? linearBackoff;

  final Map<String, String> _headers;
  final Duration Function(int tries) _backoff;
  final int _maxRetries;
  final Uri _endpoint;

  String? _minimumLevelAccepted;

  @override
  String? get minimumLevelAccepted => _minimumLevelAccepted;

  @override
  Future<void> sendEvents(List<SeqEvent> events) async {
    final body = _collapseEvents(events);
    if (body.isEmpty) {
      SeqLogger.diagnosticLog(SeqLogLevel.verbose, 'No events to send.');

      return;
    }

    http.Response response;
    try {
      response = await _sendRequest(body);
    } catch (e, stack) {
      throw SeqClientException('Failed to send request', e, stack);
    }

    await _handleResponse(response);
  }

  String _collapseEvents(List<SeqEvent> events) =>
      events.reversed.map(jsonEncode).join('\n');

  Future<http.Response> _sendRequest(String body) async {
    http.Response? response;
    Exception? lastException;

    var tries = 0;

    const noRetryStatusCodes = [201, 400, 401, 403, 413, 429, 500];
    do {
      try {
        response = await http.post(
          _endpoint,
          headers: _headers,
          body: body,
        );
      } on Exception catch (e) {
        lastException = e;

        final backoffDuration = _backoff(tries);

        SeqLogger.diagnosticLog(
          SeqLogLevel.error,
          'Error when sending request. Backing off by {BackoffDuration}s',
          e,
          {'BackoffDuration': backoffDuration.inSeconds},
        );

        await Future<void>.delayed(backoffDuration);
      }
    } while (!noRetryStatusCodes.contains(response?.statusCode) &&
        ++tries < _maxRetries);

    if (lastException != null) {
      throw lastException;
    }

    return response!;
  }

  Future<void> _handleResponse(http.Response response) async {
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw SeqHttpClientException(
        'The response body was not a JSON object',
        response: response,
      );
    }

    final seqResponse = SeqResponse.fromJson(json);

    if (response.statusCode == 201) {
      if (seqResponse.minimumLevelAccepted != _minimumLevelAccepted) {
        _minimumLevelAccepted = seqResponse.minimumLevelAccepted;
      }

      return;
    }

    final problem = seqResponse.error ?? 'no problem details known';

    final message = switch (response.statusCode) {
      400 => 'The request was malformed: $problem',
      401 => 'Authorization is required: $problem',
      403 =>
        "The provided credentials don't have ingestion permission: $problem",
      413 => 'The payload itself exceeds the configured maximum size: $problem',
      429 => 'Too many requests',
      500 =>
        "An internal error prevented the events from being ingested; check Seq's diagnostic log for more information: $problem",
      503 =>
        "The Seq server is starting up and can't currently service the request, or, free storage space has fallen below the minimum required threshold; this status code may also be returned by HTTP proxies and other network infrastructure when Seq is unreachable: $problem",
      _ => 'Unexpected status code (${response.statusCode}). Error: $problem',
    };

    throw SeqHttpClientException(message, response: response);
  }
}
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// Start WooCommerce Group Code

class WooCommerceGroup {
  static String getBaseUrl() =>
      'https://elbauldepandora.com/wp-json/wc/v3';
  static Map<String, String> headers = {};
  static WooCommerceFetchCall wooCommerceFetchCall = WooCommerceFetchCall();
}

class WooCommerceFetchCall {
  Future<ApiCallResponse> call({
    String? endpoint = 'products/categories',
    int? page,
  }) async {
    final baseUrl = WooCommerceGroup.getBaseUrl();
    
    // Construir los parámetros dinámicamente para omitir 'page' si es nulo
    final Map<String, dynamic> params = {
      'per_page': 100,
      'hide_empty': false,
      'status': "publish",
    };
    
    if (page != null) {
      params['page'] = page;
    }

    return ApiManager.instance.makeApiCall(
      callName: 'WooCommerceFetch',
      apiUrl: '$baseUrl/$endpoint',
      callType: ApiCallType.GET,
      headers: {
        'Authorization':
            'Basic Y2tfYmVjNWIwMGM0NWQwMGFjZWEyMTM0ZGU2Yzg2YjMzOTNmNjE3NDJlNTpjc180MWNkNTA2YjlmOWJmZTg2ZWEyOTliZWEwMWYxNjQzNzU2MTc1YmM4',
      },
      params: params,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

/// End WooCommerce Group Code

class ActualizarProductosCall {
  static Future<ApiCallResponse> call({
    String? productoIdInput = '',
    int? cantidadSumar,
  }) async {
    final ffApiRequestBody = '''
{
  "producto_id_input": "${escapeStringForJson(productoIdInput)}",
  "cantidad_sumar": $cantidadSumar
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'actualizarProductos',
      apiUrl:
          'https://uzhfziprpmxnelwpczgo.supabase.co/rest/v1/rpc/actualizar_stock',
      callType: ApiCallType.POST,
      headers: {
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6aGZ6aXBycG14bmVsd3BjemdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MDQ0MDMsImV4cCI6MjA5Mjk4MDQwM30.SqQEt7uS96eTPJdO81aLz6KJPdDX9UCtlzBGRhXeNH8',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6aGZ6aXBycG14bmVsd3BjemdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MDQ0MDMsImV4cCI6MjA5Mjk4MDQwM30.SqQEt7uS96eTPJdO81aLz6KJPdDX9UCtlzBGRhXeNH8',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}

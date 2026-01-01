import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<dynamic> main(final context) async {
  final apiKey = Platform.environment['CHARGILY_API_KEY'];
  final userId = context.req.headers['x-appwrite-user-id'];

  // Validate API key
  if (apiKey == null || apiKey.isEmpty) {
    context.error('CHARGILY_API_KEY is not configured');
    return context.res.json({
      'success': false,
      'error': 'Payment service configuration error',
    }, 500);
  }

  try {
    final body = jsonDecode(context.req.body);
    
    // Extract subscription data
    final int amount = body['amount'] ?? 0;
    final String planType = body['plan_type'] ?? 'monthly';
    final String planName = body['plan_name'] ?? 'اشتراك شهري';
    final int durationDays = body['duration_days'] ?? 30;

    context.log('Creating Chargily checkout for user: $userId');
    context.log('Plan: $planType - Amount: $amount DZD');

    final response = await http.post(
      Uri.parse('https://pay.chargily.net/test/api/v2'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'currency': 'dzd',
        'payment_method': 'edahabia', // or 'cib' for CIB cards
        'chargily_pay_fees_allocation': 'merchant',
        'success_url': 'https://adjaj-app.com/payment-success',
        'failure_url': 'https://adjaj-app.com/payment-failed',
        'description': 'اشتراك عِدّاج - $planName',
        'metadata': {
          'user_id': userId,
          'plan_type': planType,
          'plan_name': planName,
          'duration_days': durationDays,
          'app': 'adjaj',
        },
        'webhook_endpoint': Platform.environment['WEBHOOK_URL'] ?? '',
      }),
    );

    context.log('Chargily API response status: ${response.statusCode}');
    context.log('Chargily API response body: ${response.body}');

    // Check if the request was successful
    if (response.statusCode != 200 && response.statusCode != 201) {
      context.error('Chargily API error: ${response.statusCode}');
      return context.res.json({
        'success': false,
        'error': 'Payment service returned error: ${response.statusCode}',
        'details': response.body,
      }, response.statusCode);
    }

    // Parse the Chargily response
    final chargilyResponse = jsonDecode(response.body);

    // Extract the checkout_url from the response
    final checkoutUrl = chargilyResponse['checkout_url'];

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      context.error('No checkout_url in Chargily response');
      return context.res.json({
        'success': false,
        'error': 'Payment service did not return a checkout URL',
      }, 500);
    }

    context.log('✅ Checkout URL generated: $checkoutUrl');

    return context.res.json({
      'success': true,
      'checkout_url': checkoutUrl,
      'invoice_id': chargilyResponse['id'],
      'amount': chargilyResponse['amount'],
      'currency': chargilyResponse['currency'],
      'plan_type': planType,
    });
  } catch (e, stackTrace) {
    context.error('Exception in payment function: $e');
    context.error('Stack trace: $stackTrace');
    return context.res.json({
      'success': false,
      'error': e.toString(),
    }, 500);
  }
}

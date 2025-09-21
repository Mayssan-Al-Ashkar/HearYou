import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  AuthService(this._client);

  Future<void> registerFcmToken({required String uid, required String token}) async {
    await _client.postJson('/auth/register-fcm', {
      'uid': uid,
      'token': token,
    });
  }
}



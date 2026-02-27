import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/data/models/chat_model.dart';
import 'package:get/get.dart';

class ChatRepository {
  final dio.Dio _dio = dio.Dio();

  String? get _token => StorageService.instance.getToken();

  Future<Chat?> initiateChat(int orderId, {int? driverId}) async {
    try {
      final response = await _dio.post(
        '${Config.baseUrl}/chat/initiate',
        data: {
          'order_id': orderId,
          if (driverId != null) 'driver_id': driverId,
        },
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 &&
          response.data['meta']['status'] == 'success') {
        return Chat.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Chat Error: $e');
      return null;
    }
  }

  Future<List<ChatMessage>> getMessages(int chatId) async {
    try {
      final response = await _dio.get(
        '${Config.baseUrl}/chat/$chatId/messages',
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 &&
          response.data['meta']['status'] == 'success') {
        final List data = response.data['data'];
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Messages Error: $e');
      return [];
    }
  }

  Future<ChatMessage?> sendMessage(int chatId,
      {String? message, File? image}) async {
    try {
      final dynamic data;

      if (image != null) {
        data = dio.FormData.fromMap({
          'message': message,
          'image': await dio.MultipartFile.fromFile(image.path),
        });
      } else {
        data = {
          'message': message,
        };
      }

      final response = await _dio.post(
        '${Config.baseUrl}/chat/$chatId/send',
        data: data,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
            if (image == null) 'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 &&
          response.data['meta']['status'] == 'success') {
        print('DEBUG RESPONSE DATA: ${response.data['data']}');
        return ChatMessage.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Send Message Error: $e');
      return null;
    }
  }
}

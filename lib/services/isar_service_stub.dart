import 'package:isar/isar.dart';

class IsarService {
  static final IsarService instance = IsarService._internal();
  IsarService._internal();
  
  Isar get isar => throw UnimplementedError("Isar no está disponible en Web");
  
  Future<void> init() async {
    print("Isar no soportado en Web");
  }
  
  Future<void> close() async {}
}
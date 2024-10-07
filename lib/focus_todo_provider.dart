import 'package:flutter/foundation.dart';

class FocusTodoProvider with ChangeNotifier {
  String? _focusTodo;

  String? get focusTodo => _focusTodo;

  void setFocusTodo(String? todo) {
    _focusTodo = todo;
    notifyListeners();
  }
}

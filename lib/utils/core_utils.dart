import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

abstract class CoreUtils {
  const CoreUtils();

  static void toastSuccess(String message, {String title = "Success"}) {
    CoreUtils._toast(
      title: title,
      message: message,
      type: ToastificationType.success,
      color: Colors.green,
    );
  }

  static void toastError(String message, {String title = "Error"}) {
    CoreUtils._toast(
      title: title,
      message: message,
      type: ToastificationType.error,
      color: Colors.redAccent,
    );
  }

  static String formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  static void _toast({
    required String title,
    required String message,
    required ToastificationType type,
    required Color color,
  }) {
    toastification.show(
      type: type,
      style: ToastificationStyle.fillColored,
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      description: Text(
        message,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      closeButton: ToastCloseButton(
        showType: CloseButtonShowType.always,
        buttonBuilder: (context, onClose) {
          return GestureDetector(
            onTap: onClose,
            child: Icon(Icons.cancel_outlined, color: Colors.white),
          );
        },
      ),
      closeOnClick: false,
      dragToClose: true,
      showIcon: false,
      alignment: Alignment.bottomCenter,
      primaryColor: color,
      autoCloseDuration: const Duration(seconds: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      borderRadius: BorderRadius.circular(8),
    );
  }
}

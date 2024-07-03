import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';

String primary(){
  String primary = "0xFF3A98B9";
  return primary;
}

Widget spaceVert(BuildContext context, double size){
  return SizedBox(
    height: MediaQuery.sizeOf(context).height*size,
  );
}

Widget spaceHoriz(BuildContext context, double size){
  return SizedBox(
    width: MediaQuery.sizeOf(context).width*size,
  );
}

String convertToIdr(dynamic number) {
  NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: '',
      decimalDigits: 0
  );
  return currencyFormatter.format(number);
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = '.'; // Change this to '.' for other locales

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Short-circuit if the new value is empty
    if (newValue.text.length == 0) {
      return newValue.copyWith(text: '');
    }

    // Handle "deletion" of separator character
    String oldValueText = oldValue.text.replaceAll(separator, '');
    String newValueText = newValue.text.replaceAll(separator, '');

    if (oldValue.text.endsWith(separator) &&
        oldValue.text.length == newValue.text.length + 1) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }

    // Only process if the old value and new value are different
    if (oldValueText != newValueText) {
      int selectionIndex =
          newValue.text.length - newValue.selection.extentOffset;
      final chars = newValueText.split('');

      String newString = '';
      for (int i = chars.length - 1; i >= 0; i--) {
        if ((chars.length - 1 - i) % 3 == 0 && i != chars.length - 1)
          newString = separator + newString;
        newString = chars[i] + newString;
      }

      return TextEditingValue(
        text: newString.toString(),
        selection: TextSelection.collapsed(
          offset: newString.length - selectionIndex,
        ),
      );
    }

    // If the new value and old value are the same, just return as-is
    return newValue;
  }
}

warning(String text, BuildContext context){
  Dialogs.materialDialog(
      barrierDismissible: false,
      color: Colors.white,
      msg: text,
      msgAlign: TextAlign.center,
      lottieBuilder: LottieBuilder.asset("assets/animations/warning.json"),
      context: context,
      actions: [
        IconsButton(
          onPressed: (){
            Navigator.pop(context);
          },
          text: 'OK',
        )
      ]
  );
}

success(String text, BuildContext context, Widget goto){
  Dialogs.materialDialog(
      barrierDismissible: false,
      color: Colors.white,
      msg: text,
      msgAlign: TextAlign.center,
      lottieBuilder: LottieBuilder.asset("assets/animations/success.json"),
      context: context,
      actions: [
        IconsButton(
          onPressed: (){
            Get.off(()=> goto);
          },
          text: 'OK',
        )
      ]
  );
}

loading(BuildContext context){
  Dialogs.materialDialog(
      barrierDismissible: false,
      color: Colors.white,
      lottieBuilder: LottieBuilder.asset("assets/animations/loading1.json"),
      context: context,
  );
}
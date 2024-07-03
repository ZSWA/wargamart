import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Controller/MainPage.dart';

import '../GlobalVar.dart';

class AddVoucher extends StatefulWidget {
  const AddVoucher({super.key});

  @override
  State<AddVoucher> createState() => _AddVoucherState();
}

class _AddVoucherState extends State<AddVoucher> {
  TextEditingController _name = TextEditingController();
  TextEditingController _price = TextEditingController();
  TextEditingController _startDate = TextEditingController();
  TextEditingController _endDate = TextEditingController();
  TextEditingController _description = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late Uint8List imageToRead;
  String profile = "";
  String voucherDate = "";
  String voucherEndDate = "";

  Widget _tfield(String label, TextEditingController controller,TextInputType type){
    return SizedBox(
      height: MediaQuery.sizeOf(context).height*0.06,
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            labelText: label,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
            )
        ),
      ),
    );
  }

  void setProfile(BuildContext context) async {
    loading(context);

    final pickerImage = await _picker.pickImage(source: ImageSource.gallery,imageQuality: 15);
    Navigator.of(context).pop();

    Uint8List? bytes = await pickerImage?.readAsBytes();
    double size = File(pickerImage!.path).lengthSync() / (1024*1024);
    print("size : $size");
    if(size > 5){
      warning("Ukuran file maksimal 5MB", context);
    }else{
      setState((){
        profile = pickerImage.path;
      });
    }
  }

  addToVoucher(File imageFile)async{
    loading(context);
    List voucher = [];

    try{
      String fileName = imageFile.path.split("/").last;
      Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('Voucher/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);

      TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference _voucher = firestore.collection('Voucher');

      QuerySnapshot querySnapshot = await _voucher.get();
      for (var doc in querySnapshot.docs) {
        Map data = doc.data() as Map;
        voucher.add(data['id']);
      }

      int largestNumber = voucher.isEmpty ? 0 : voucher.reduce((currentMax, next) => currentMax > next ? currentMax : next);

      int price = 0;

      if(_price.text.contains(".")){
        price = int.parse(_price.text.replaceAll(".", "").trim());
      }else if(_price.text.contains(",")){
        price = int.parse(_price.text.replaceAll(",", "").trim());
      }else if(_price.text.contains("-")){
        price = int.parse(_price.text.replaceAll("-", "").trim());
      }else if(_price.text.contains(" ")){
        price = int.parse(_price.text.trim());
      }

      await _voucher.add({
        'id': largestNumber + 1,
        'name': _name.text,
        'price': price,
        'description': _description.text,
        'endDate' : voucherEndDate,
        'startDate' : voucherDate,
        'createdAt': DateTime.now().toString(),
        'isUsed': false,
        'image': downloadUrl
      });

      Navigator.pop(context);
      success("Berhasil menambah voucher", context,MainPage(index: 2));
    } catch (e) {
      // Handle registration errors
      Navigator.pop(context);
      print('Error add voucher: $e');
      warning(e.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Get.off(()=> const MainPage(index: 2));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> const MainPage(index: 2));
            },
            child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
          ),
          title: Text("Tambah Voucher"),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: MediaQuery.sizeOf(context).width*0.95,
          child: FloatingActionButton(
            backgroundColor: Color(int.parse(primary())),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)
            ),
            onPressed: (){
              addToVoucher(File(profile));
            },
            child: Text("Tambah Voucher",style: TextStyle(
                color: Colors.white
            ),),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                profile != "" ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(profile),
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).height*0.15,),
                ) : SizedBox(
                  height: MediaQuery.sizeOf(context).height*0.15,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: Colors.grey
                        ),
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: Center(
                      child: Icon(Icons.image,size: 40,color: Colors.grey,),
                    ),
                  ),
                ),
                spaceVert(context, 0.01),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width*0.95,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(int.parse(primary()))
                      ),
                      onPressed: (){
                        setProfile(context);
                      },
                      child: Text("Pilih Gambar",style: TextStyle(
                          color: Colors.white
                      ),)
                  ),
                ),
                spaceVert(context, 0.01),
                _tfield("Nama Voucher", _name, TextInputType.text),
                spaceVert(context, 0.01),
                _tfield("Nominal Voucher", _price, TextInputType.number),
                spaceVert(context, 0.01),
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.06,
                  child: DateTimePicker(
                    // maxLines: 2,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                        labelText: "Mulai Voucher",
                        suffixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder()
                    ),
                    type: DateTimePickerType.dateTime,
                    dateMask: 'dd MMM yyyy HH:mm',
                    firstDate: DateTime.now().subtract(Duration(days: 0)),
                    lastDate: DateTime(9999),
                    onChanged: (val) {
                      setState(() {
                        String cekDateM = val;
                        String cek = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                        String dateTime = DateTime.now().toUtc().toString().substring(11, 23);

                        String dateTimeWithOffset = '$cek $dateTime';
                        voucherDate = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                      });
                    },
                    validator: (val) {
                      setState(() {
                        String cekDateM = val.toString();
                        String cek = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                        String dateTime = DateTime.now().toUtc().toString().substring(11, 23);

                        String dateTimeWithOffset = '$cek $dateTime';
                        voucherDate = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                      });
                      return null;
                    },
                    onSaved: (val) {
                      setState(() {
                        String cekDateM = val.toString();
                        String cek = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                        String dateTime = DateTime.now().toUtc().toString().substring(11, 23);

                        String dateTimeWithOffset = '$cek $dateTime';
                        voucherDate = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                      });
                    },
                  ),
                ),
                spaceVert(context, 0.01),
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.06,
                  child: DateTimePicker(
                    // maxLines: 2,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                        labelText: "Selesai Voucher",
                        suffixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder()
                    ),
                    type: DateTimePickerType.dateTime,
                    dateMask: 'dd MMM yyyy HH:mm',
                    firstDate: DateTime.now().subtract(Duration(days: 0)),
                    lastDate: DateTime(9999),
                    onChanged: (val) {
                      setState(() {
                        String cekDateM = val;
                        String cek = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                        String dateTime = DateTime.now().toUtc().toString().substring(11, 23);

                        String dateTimeWithOffset = '$cek $dateTime';
                        voucherEndDate = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                      });
                    },
                    validator: (val) {
                      setState(() {
                        String cekDateM = val.toString();
                        String cek = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                        String dateTime = DateTime.now().toUtc().toString().substring(11, 23);

                        String dateTimeWithOffset = '$cek $dateTime';
                        voucherEndDate = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                      });
                      return null;
                    },
                    onSaved: (val) {
                      setState(() {
                        String cekDateM = val.toString();
                        String cek = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                        String dateTime = DateTime.now().toUtc().toString().substring(11, 23);

                        String dateTimeWithOffset = '$cek $dateTime';
                        voucherEndDate = DateFormat("yyyy-MM-dd HH:mm:ss.ssssss")
                            .format(DateTime.parse(cekDateM));
                      });
                    },
                  ),
                ),
                spaceVert(context, 0.01),
                TextField(
                  controller: _description,
                  maxLines: 5,
                  decoration: InputDecoration(
                      labelText: "Deskripsi",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)
                      )
                  ),
                ),
                spaceVert(context, 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

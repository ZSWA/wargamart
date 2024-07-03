import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/GlobalVar.dart';
import 'package:wargamart/User/LoginPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  TextEditingController _confPassword = TextEditingController();
  bool hidePass = true;
  bool hideConfPass = true;
  final ImagePicker _picker = ImagePicker();
  late Uint8List imageToRead;
  String profile = "";

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
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Get.off(()=> const LoginPage());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> const LoginPage());
            },
            child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
          ),
          title: Text("Daftar"),
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
              if(_name.text.isEmpty && _name.text == ""){
                warning("Nama tidak boleh kosong", context);
              }else if(_email.text.isEmpty && _email.text == ""){
                warning("Email tidak boleh kosong", context);
              }else if(_password.text.isEmpty && _password.text == ""){
                warning("Kata sandi tidak boleh kosong", context);
              }else if(_password.text.length < 8){
                warning("Kata sandi minimal 8 karakter", context);
              }else if(_password.text != _confPassword.text){
                warning("Konfirmasi kata sandi tidak sama", context);
              }else{
                uploadImageToFirebase(File(profile));
              }
            },
            child: Text("Daftar",style: TextStyle(
              color: Colors.white
            ),),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              profile == "" ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey
                  )
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 50,
                  child: Icon(Icons.person,size: 30,color: Colors.grey,),
                ),
              ) : CircleAvatar(
                radius: 50,
                backgroundImage: FileImage(File(profile)),
              ),
              spaceVert(context, 0.01),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(int.parse(primary()))
                ),
                  onPressed: (){
                    setProfile(context);
                  },
                  child: Text("Pilih Foto",style: TextStyle(
                    color: Colors.white
                  ),)),
              spaceVert(context, 0.02),
              _tfield("Nama Lengkap", _name, TextInputType.text),
              spaceVert(context, 0.01),
              _tfield("Email", _email, TextInputType.emailAddress),
              spaceVert(context, 0.01),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.06,
                child: TextField(
                  controller: _password,
                  obscureText: hidePass,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      suffixIcon: GestureDetector(
                          onTap: (){
                            if(hidePass){
                              setState(() {
                                hidePass = false;
                              });
                            }else{
                              setState(() {
                                hidePass = true;
                              });
                            }
                          },
                          child: Icon(Icons.remove_red_eye,color: hidePass ? Colors.grey : Color(int.parse(primary())),)),
                      labelText: "Kata Sandi",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),
              spaceVert(context, 0.01),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.06,
                child: TextField(
                  controller: _confPassword,
                  keyboardType: TextInputType.text,
                  obscureText: hideConfPass,
                  decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      suffixIcon: GestureDetector(
                          onTap: (){
                            if(hideConfPass){
                              setState(() {
                                hideConfPass = false;
                              });
                            }else{
                              setState(() {
                                hideConfPass = true;
                              });
                            }
                          },
                          child: Icon(Icons.remove_red_eye,color: hideConfPass ? Colors.grey : Color(int.parse(primary())),)),
                      labelText: "Konfirmasi Kata Sandi",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  uploadImageToFirebase(File imageFile) async {
    loading(context);
    try{
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email.text,
        password: _password.text,
      );
      // If the registration is successful, userCredential will contain the user information
      print('User registered: ${userCredential.user?.uid}');

      String fileName = imageFile.path.split("/").last;
      Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('UserProfile/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);

      TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference user = firestore.collection('Users');

      await user.add({
        'image': downloadUrl,
        'userId': userCredential.user?.uid,
        'email' : _email.text,
        'full_name' : _name.text,
        "type": "customer"
      });

      Navigator.pop(context);
      success("Registrasi berhasil\nSilahkan masuk kembali", context,LoginPage());
    } catch (e) {
      // Handle registration errors
      Navigator.pop(context);
      print('Error registering user: $e');
      warning(e.toString(), context);
    }
  }
}

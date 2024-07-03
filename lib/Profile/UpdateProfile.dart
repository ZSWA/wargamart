import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Controller/MainPage.dart';

import '../GlobalVar.dart';

class UpdateProfile extends StatefulWidget {
  final Map data;
  const UpdateProfile({super.key, required this.data});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late Uint8List imageToRead;
  String profile = "";

  Widget _tfield(String label, TextEditingController controller,TextInputType type,bool enabled){
    return SizedBox(
      height: MediaQuery.sizeOf(context).height*0.06,
      child: TextField(
        controller: controller,
        keyboardType: type,
        enabled: enabled,
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
  void initState() {
    setState(() {
      _name.text = widget.data['full_name'];
      _email.text = widget.data['email'];
      profile = widget.data['image'];
    });
    super.initState();
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
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> const MainPage(index: 2));
            },
            child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
          ),
          title: Text("Ubah Profile"),
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
              uploadImageToFirebase(File(profile));
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
              profile == widget.data['image'] ? CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(widget.data['image']),
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
              _tfield("Email", _email, TextInputType.emailAddress,false),
              spaceVert(context, 0.01),
              _tfield("Nama Lengkap", _name, TextInputType.text,true),
              spaceVert(context, 0.01),
            ],
          ),
        ),
      ),
    );
  }

  uploadImageToFirebase(File imageFile) async {
    loading(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String downloadUrl = "";

    try{
      if(profile != widget.data['image']){
        String fileName = imageFile.path.split("/").last;
        Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('UserProfile/$fileName');
        UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);

        TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => null);
        downloadUrl = await storageSnapshot.ref.getDownloadURL();
      }

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference user = firestore.collection('Users');

      QuerySnapshot querySnapshot = await user.where("userId", isEqualTo: prefs.getString("userId")).get();

      String docId = "";

      for (var doc in querySnapshot.docs) {
        docId = doc.id;
      }

      await user.doc(docId).update({
        'image': profile != widget.data['image'] ? downloadUrl : widget.data['image'],
        'full_name' : _name.text,
      });


      Navigator.pop(context);
      success("Berhasil mengubah profile", context,MainPage(index: 2));
    } catch (e) {
      // Handle registration errors
      Navigator.pop(context);
      print('Error registering user: $e');
      warning(e.toString(), context);
    }
  }
}

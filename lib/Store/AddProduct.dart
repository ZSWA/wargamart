import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/shared/types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Controller/MainPage.dart';

import '../GlobalVar.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  TextEditingController _name = TextEditingController();
  TextEditingController _price = TextEditingController();
  TextEditingController _sendFrom = TextEditingController();
  TextEditingController _condition = TextEditingController();
  TextEditingController _cat = TextEditingController();
  TextEditingController _description = TextEditingController();
  TextEditingController _stock = TextEditingController();
  TextEditingController _weight = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late Uint8List imageToRead;
  String profile = "";
  CollectionReference category = FirebaseFirestore.instance.collection('Category');
  bool fetchingCat = false;
  List _category = [];
  String categoryVal = "";
  List condition = [
    "Like New",
    "New",
    "Second"
  ];

  getCat() async {
    setState(() {
      fetchingCat = true;
    });
    try {
      QuerySnapshot querySnapshot = await category.get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          _category.add(doc.data());
          _category.sort((a,b) => a['name'].compareTo(b['name']));
        });
      });
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetchingCat = false;
    });
  }

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

  addToProduct(File imageFile)async{
    loading(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List product = [];

    try{
      String fileName = imageFile.path.split("/").last;
      Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('Product/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);

      TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference _product = firestore.collection('Product');

      QuerySnapshot querySnapshot = await _product.get();
      for (var doc in querySnapshot.docs) {
        Map data = doc.data() as Map;
        product.add(data['id']);
      }

      int largestNumber = product.isEmpty ? 0 : product.reduce((currentMax, next) => currentMax > next ? currentMax : next);

      int price = 0;
      int stock = 0;
      int weight = 0;

      if(_price.text.contains(".")){
        price = int.parse(_price.text.replaceAll(".", "").trim());
      }else if(_price.text.contains(",")){
        price = int.parse(_price.text.replaceAll(",", "").trim());
      }else if(_price.text.contains("-")){
        price = int.parse(_price.text.replaceAll("-", "").trim());
      }else if(_price.text.contains(" ")){
        price = int.parse(_price.text.trim());
      }

      if(_weight.text.contains(".")){
        weight = int.parse(_weight.text.replaceAll(".", "").trim());
      }else if(_weight.text.contains(",")){
        weight = int.parse(_weight.text.replaceAll(",", "").trim());
      }else if(_weight.text.contains("-")){
        weight = int.parse(_weight.text.replaceAll("-", "").trim());
      }else if(_weight.text.contains(" ")){
        weight = int.parse(_weight.text.trim());
      }

      if(_stock.text.contains(".")){
        stock = int.parse(_stock.text.replaceAll(".", "").trim());
      }else if(_stock.text.contains(",")){
        stock = int.parse(_stock.text.replaceAll(",", "").trim());
      }else if(_stock.text.contains("-")){
        stock = int.parse(_stock.text.replaceAll("-", "").trim());
      }else if(_stock.text.contains(" ")){
        stock = int.parse(_stock.text.trim());
      }

      await _product.add({
        'id': largestNumber + 1,
        'name': _name.text,
        'price': price,
        'category': _cat.text,
        'send_from' : _sendFrom.text,
        'condition' : _condition.text,
        'description': _description.text,
        'stock' : stock,
        'weight' : weight,
        'sold': 0,
        'min_bought': 1,
        'image': downloadUrl
      });

      Navigator.pop(context);
      success("Berhasil menambah produk", context,MainPage(index: 2));
    } catch (e) {
      // Handle registration errors
      Navigator.pop(context);
      print('Error add product: $e');
      warning(e.toString(), context);
    }
  }

  @override
  void initState() {
    getCat();
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
          backgroundColor: Colors.white,
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> const MainPage(index: 2));
            },
            child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
          ),
          title: Text("Tambah Produk"),
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
              addToProduct(File(profile));
            },
            child: Text("Tambah Produk",style: TextStyle(
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
                _tfield("Nama Produk", _name, TextInputType.text),
                spaceVert(context, 0.01),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height*0.06,
                  child: TextField(
                    controller: _cat,
                    onTap: (){
                      Dialogs.materialDialog(
                        color: Colors.white,
                        title: "Pilih Kategori",
                        customViewPosition: CustomViewPosition.BEFORE_MESSAGE,
                        customView: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ListView.builder(
                              itemCount: _category.length,
                              shrinkWrap: true,
                              itemBuilder: (context,index){
                                return GestureDetector(
                                  onTap: (){
                                    setState(() {
                                      _cat.text = _category[index]['name'];
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    margin: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height*0.01),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Color(int.parse(primary())),
                                        ),
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Text(_category[index]['name']),
                                  ),
                                );
                              }),
                        ),
                        context: context,
                      );
                    },
                    readOnly: true,
                    decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        labelText: "Kategori",
                        suffixIcon: Icon(Icons.arrow_drop_down_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                        )
                    ),
                  ),
                ),
                spaceVert(context, 0.01),
                _tfield("Harga Produk", _price, TextInputType.number),
                spaceVert(context, 0.01),
                _tfield("Dikirim dari", _sendFrom, TextInputType.text),
                spaceVert(context, 0.01),
                _tfield("Stok", _stock, TextInputType.number),
                spaceVert(context, 0.01),
                _tfield("Berat", _weight, TextInputType.number),
                spaceVert(context, 0.01),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height*0.06,
                  child: TextField(
                    controller: _condition,
                    onTap: (){
                      Dialogs.materialDialog(
                        color: Colors.white,
                        title: "Pilih Kondisi Produk",
                        customViewPosition: CustomViewPosition.BEFORE_MESSAGE,
                        customView: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ListView.builder(
                              itemCount: condition.length,
                              shrinkWrap: true,
                              itemBuilder: (context,index){
                                return GestureDetector(
                                  onTap: (){
                                    setState(() {
                                      _condition.text = condition[index];
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(5),
                                    margin: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height*0.01),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Color(int.parse(primary())),
                                        ),
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Text(condition[index]),
                                  ),
                                );
                              }),
                        ),
                        context: context,
                      );
                    },
                    readOnly: true,
                    decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        labelText: "Kondisi",
                        suffixIcon: Icon(Icons.arrow_drop_down_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                        )
                    ),
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

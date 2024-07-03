import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Order/OrderSummary.dart';

import '../GlobalVar.dart';

class UpdatedAddress extends StatefulWidget {
  final List cartItem;
  final Map data;
  const UpdatedAddress({super.key, required this.cartItem, required this.data});

  @override
  State<UpdatedAddress> createState() => _UpdatedAddressState();
}

class _UpdatedAddressState extends State<UpdatedAddress> {
  TextEditingController _name = TextEditingController();
  TextEditingController _village = TextEditingController();
  TextEditingController _subdistrict = TextEditingController();
  TextEditingController _district = TextEditingController();
  TextEditingController _postalCode = TextEditingController();

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

  updateAddress()async{
    loading(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference addressItem = firestore.collection('Address');

    QuerySnapshot querySnapshot = await addressItem.where("userId", isEqualTo: prefs.getString("userId")).get();

    String docId = "";

    for (var doc in querySnapshot.docs) {
      docId = doc.id;
    }

    addressItem.doc(docId).update({
      'name': _name.text,
      'userId': prefs.getString("userId"),
      'village' : _village.text,
      'subdistrict' : _subdistrict.text,
      'district': _district.text,
      'postal_code' : _postalCode.text,
    });

    Navigator.pop(context);
    success("Berhasil merubah alamat", context,OrderSummary(cartItem: widget.cartItem));
  }

  @override
  void initState() {
    setState(() {
      _name.text = widget.data['name'];
      _village.text = widget.data['village'];
      _subdistrict.text = widget.data['subdistrict'];
      _district.text = widget.data['district'];
      _postalCode.text = widget.data['postal_code'];
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Get.off(()=> OrderSummary(cartItem: widget.cartItem));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> OrderSummary(cartItem: widget.cartItem));
            },
            child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
          ),
          title: Text("Ubah Alamat"),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: MediaQuery.sizeOf(context).width*0.95,
          child: FloatingActionButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)
            ),
            backgroundColor: Color(int.parse(primary())),
            onPressed: (){
              updateAddress();
            },
            child: Text("Simpan",style: TextStyle(
                color: Colors.white
            ),),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tfield("Nama", _name, TextInputType.text),
                spaceVert(context, 0.01),
                _tfield("Desa", _village, TextInputType.text),
                spaceVert(context, 0.01),
                _tfield("Kecamatan", _subdistrict, TextInputType.text),
                spaceVert(context, 0.01),
                _tfield("Kabupaten/ Kota", _district, TextInputType.text),
                spaceVert(context, 0.01),
                _tfield("Kode Pos", _postalCode, TextInputType.number),
                spaceVert(context, 0.01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

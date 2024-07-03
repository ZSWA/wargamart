import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/GlobalVar.dart';
import 'package:wargamart/Order/OrderSummary.dart';

class AddAddress extends StatefulWidget {
  final List cartItem;
  const AddAddress({super.key, required this.cartItem});

  @override
  State<AddAddress> createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
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

  addToAddress()async{
    loading(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference addressItem = firestore.collection('Address');

    await addressItem.add({
      'name': _name.text,
      'userId': prefs.getString("userId"),
      'village' : _village.text,
      'subdistrict' : _subdistrict.text,
      'district': _district.text,
      'postal_code' : _postalCode.text,
    });

    Navigator.pop(context);
    success("Berhasil membuat alamat", context,OrderSummary(cartItem: widget.cartItem));
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
          backgroundColor: Colors.white,
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> OrderSummary(cartItem: widget.cartItem));
            },
            child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
          ),
          title: Text("Tambah Alamat",style: TextStyle(
            color: Colors.black
          ),),
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
              if(_name.text.isEmpty && _name.text == ""){
                warning("Nama tidak boleh kosong", context);
              }else if(_village.text.isEmpty && _village.text == ""){
                warning("Desa tidak boleh kosong", context);
              }else if(_subdistrict.text.isEmpty && _subdistrict.text == ""){
                warning("Kecamatan tidak boleh kosong", context);
              }else if(_district.text.isEmpty && _district.text == ""){
                warning("Kabupaten/ Kota tidak boleh kosong", context);
              }else if(_postalCode.text.isEmpty && _postalCode.text == ""){
                warning("Kode pos tidak boleh kosong", context);
              }else{
                addToAddress();
              }
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

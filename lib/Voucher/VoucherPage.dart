import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:wargamart/Voucher/DetailVoucher.dart';

import '../GlobalVar.dart';

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  List _voucher = [];
  bool fetchingVoucher = false;
  CollectionReference voucher = FirebaseFirestore.instance.collection('Voucher');

  getVoucher() async {
    setState(() {
      fetchingVoucher = true;
    });
    try {
      QuerySnapshot querySnapshot = await voucher.where("isUsed", isEqualTo: false).get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          _voucher.add(doc.data());
          _voucher.sort((a,b) => a['name'].compareTo(b['name']));
        });
      });
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetchingVoucher = false;
    });
  }

  @override
  void initState() {
    getVoucher();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Voucher"),
      ),
      body: fetchingVoucher ? Center(
        child: LottieBuilder.asset("assets/animations/loading1.json",width: 100,height: 100,),
      ) : Padding(
        padding: const EdgeInsets.all(15.0),
        child: _voucher.isEmpty ? Center(
          child: Text("Belum ada voucher"),
        ) : ListView.builder(
          itemCount: _voucher.length,
            itemBuilder: (context, index){
              return voucherCard(
                _voucher[index]['image'],
                _voucher[index]['name'],
                _voucher[index]['price'],
                _voucher[index]['id'],
              );
            }),
      ),
    );
  }

  Widget voucherCard(String image, String name, int price, int id) {
    return GestureDetector(
      onTap: (){
        Get.off(()=> DetailVoucher(id: id));
      },
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height*0.01),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Color(int.parse(primary()))
          )
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FadeInImage.assetNetwork(
                fit: BoxFit.cover,
                width: MediaQuery.sizeOf(context).width*0.3,
                height: MediaQuery.sizeOf(context).height*0.1,
                image: image,
                placeholderScale: 10,
                placeholder: 'assets/animations/loading_image.gif',
                imageErrorBuilder: (context, error, trace) {
                  return  const Image(
                      image: AssetImage("assets/images/default.png")
                  );
                },
              ),
            ),
            spaceHoriz(context, 0.02),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,maxLines: 1,overflow: TextOverflow.ellipsis,style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),),
                spaceVert(context, 0.01),
                Text("Rp ${convertToIdr(price)}"),
              ],
            ),

          ],
        ),
      ),
    );
  }
}

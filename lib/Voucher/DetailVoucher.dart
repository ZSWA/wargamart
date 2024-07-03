import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Controller/MainPage.dart';
import 'package:wargamart/GlobalVar.dart';

class DetailVoucher extends StatefulWidget {
  final int id;
  const DetailVoucher({super.key, required this.id});

  @override
  State<DetailVoucher> createState() => _DetailVoucherState();
}

class _DetailVoucherState extends State<DetailVoucher> {
  CollectionReference cart = FirebaseFirestore.instance.collection('Voucher');
  bool fetching = false;
  Map _detail = {};

  getDetailVoucher() async {
    setState(() {
      fetching = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();

    QuerySnapshot querySnapshot = await cart.where("id", isEqualTo: widget.id).get();
    for (var doc in querySnapshot.docs) {
      setState(() {
        _detail.addAll(doc.data() as Map);
      });

      if (kDebugMode) {
        print(_detail);
      }
    }
    setState(() {
      fetching = false;
    });
  }

  @override
  void initState() {
    getDetailVoucher();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String startDate = "";
    String endDate = "";
    if(_detail.isNotEmpty){
      startDate = DateFormat("dd/MMMM/yyyy HH:mm").format(DateTime.parse(_detail['startDate']));
      endDate = DateFormat("dd/MMMM/yyyy HH:mm").format(DateTime.parse(_detail['endDate']));
    }

    return WillPopScope(
      onWillPop: ()async{
        Get.off(()=> MainPage(index: 1));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> MainPage(index: 1));
            },
            child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
          ),
          title: Text("Detail"),
        ),
        body: fetching ? Center(
          child: LottieBuilder.asset("assets/animations/loading1.json",width: 100,height: 100,),
        ) : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInImage.assetNetwork(
              fit: BoxFit.cover,
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height*0.2,
              image: _detail['image'],
              placeholder: 'assets/animations/loading_image.gif',
              imageErrorBuilder: (context, error, trace) {
                return  const Image(
                    image: AssetImage("assets/images/default.png")
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_detail['name'],style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  ),),
                  spaceVert(context, 0.01),
                  Text("$startDate - $endDate"),
                  spaceVert(context, 0.01),
                  Text(_detail['description']),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Controller/MainPage.dart';
import 'package:wargamart/Order/DetailOrder.dart';

import '../GlobalVar.dart';

class MyOrderPage extends StatefulWidget {
  const MyOrderPage({super.key});

  @override
  State<MyOrderPage> createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage> {
  List _myOrder = [];
  bool fetching = false;
  CollectionReference myOrder = FirebaseFirestore.instance.collection('Checkout');

  getOrder() async {
    setState(() {
      fetching = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      QuerySnapshot querySnapshot = await myOrder.where("userId", isEqualTo: prefs.getString('userId')).get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          _myOrder.add(doc.data());
          _myOrder.sort((a,b) => b['createdAt'].compareTo(a['createdAt']));
        });
      });

      if (kDebugMode) {
        print(_myOrder);
      }

    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetching = false;
    });
  }

  @override
  void initState() {
    getOrder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Get.off(()=> MainPage(index: 2));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> MainPage(index: 2));
            },
            child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
          ),
          title: Text("Pesanan Saya"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: ListView.builder(
              itemCount: _myOrder.length,
              itemBuilder: (context, index){
                return orderCard(
                  _myOrder[index]['createdAt'],
                  _myOrder[index]['cart'].first,
                  _myOrder[index]['totalPay'],
                  _myOrder[index]['cart'].length,
                  _myOrder[index],
                );
              }),
        )
      ),
    );
  }

  Widget orderCard(String createdAt, Map firstProduct, int totalPay,int totalProduct,Map data) {
    String fixDate = DateFormat("dd MMMM yyyy HH:mm").format(DateTime.parse(createdAt));
    return GestureDetector(
      onTap: (){
        Get.off(()=> DetailOrder(data: data));
      },
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height*0.01),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Color(int.parse(primary())),
                borderRadius: BorderRadius.circular(5)
              ),
              child: Text(fixDate, style: TextStyle(
                color: Colors.white,
                fontSize: 10
              ),),
            ),
            spaceVert(context, 0.01),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FadeInImage.assetNetwork(
                    width: MediaQuery.sizeOf(context).width*0.3,
                    height: MediaQuery.sizeOf(context).height*0.1,
                    fit: BoxFit.cover,
                    image: firstProduct['image'],
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
                    SizedBox(
                        width: MediaQuery.sizeOf(context).width*0.6,
                        child: Text(firstProduct['name'],maxLines: 1,overflow: TextOverflow.ellipsis,style: TextStyle(
                            fontWeight: FontWeight.bold
                        ),)
                    ),
                    spaceVert(context, 0.01),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width*0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Rp ${convertToIdr(firstProduct['price'])}"),
                          Text("x${firstProduct['total'].toString()}")
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
            Visibility(
                visible: totalProduct == 1 ? false : true,
                child: spaceVert(context, 0.01)),
            Visibility(
                visible: totalProduct == 1 ? false : true,
                child: Text("+${totalProduct - 1} lainnya}")
            ),
            spaceVert(context, 0.01),
            Divider(
              thickness: 2,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total bayar"),
                Text("Rp ${convertToIdr(totalPay)}"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

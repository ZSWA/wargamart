import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Controller/MainPage.dart';
import 'package:wargamart/GlobalVar.dart';
import 'package:wargamart/Order/OrderSummary.dart';
import 'package:wargamart/Store/StorePage.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  CollectionReference cart = FirebaseFirestore.instance.collection('Cart');
  bool fetching = false;
  Map _cart = {};
  List _cartData = [];
  String userId = "";

  getCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userId = prefs.getString("userId")!;
    });

    QuerySnapshot querySnapshot = await cart.where("userId", isEqualTo: prefs.getString("userId")).get();
    for (var doc in querySnapshot.docs) {
      setState(() {
        _cart.addAll(doc.data() as Map);
      });

      if (kDebugMode) {
        print(_cart);
      }
    }

    setState(() {
      _cartData = _cart['cart'];
    });
  }

  @override
  void initState() {
    getCart();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Get.off(()=> const MainPage(index: 0));

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: (){
              Get.off(()=> const MainPage(index: 0));
            },
              child: Icon(Icons.arrow_back,size: 30,color: Colors.black,)
          ),
          title: Text("Keranjang",style: TextStyle(
            color: Colors.black
          ),),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Visibility(
          visible: _cartData.isEmpty ? false : true,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width*0.95,
            child: FloatingActionButton(
              backgroundColor: Color(int.parse(primary())),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)
              ),
              onPressed: ()async{
                Get.off(()=> OrderSummary(cartItem: _cartData,));
              },
              child: Text("Checkout",style: TextStyle(
                color: Colors.white
              ),),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: cart.where("userId", isEqualTo: userId).snapshots(),
          builder: (context, snapshot){
            if(snapshot.hasData){
              if(snapshot.data!.docs.isNotEmpty){
                if(snapshot.data!.docs.first['cart'].isEmpty){
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Belum ada produk dikeranjang"),
                      ],
                    ),
                  );
                }else{
                  List documents = snapshot.data!.docs.first['cart'];
                  _cartData = documents;
                  print(_cartData);
                  return ListView.builder(
                      shrinkWrap: true,
                      itemCount: documents.length,
                      itemBuilder: (context, index){
                        return cartCard(
                            documents[index]['id'],
                            documents[index]['image'],
                            documents[index]['name'],
                            documents[index]['total'],
                            documents[index]['price'],
                            documents[index],
                            documents
                        );
                      });
                }
              }else{
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Belum ada produk dikeranjang"),
                    ],
                  ),
                );
              }
            }else if(snapshot.hasError){
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }else{
              return Center(
                child: LottieBuilder.asset("assets/animations/loading1.json",width: 100,height: 100,),
              );
            }
          },
        ),
      ),
    );
  }

  Widget cartCard(int id, String image, String name, int total, int price,Map data,List _cartData) {
    price = price * total;

    List _cData = _cartData;

    add()async{
      SharedPreferences prefs = await SharedPreferences.getInstance();

      data.update("total", (value) => data['total'] + 1);
      _cData.add(data);
      _cData.remove(_cData.where((e) => e['id'] == id).toList().first);

      QuerySnapshot querySnapshot = await cart.where("userId", isEqualTo: prefs.getString("userId")).get();

      String docId = "";

      for (var doc in querySnapshot.docs) {
        docId = doc.id;
      }

      cart.doc(docId).update({
        'cart' : _cData,
        'updatedAt': DateTime.now().toString()
      });

      if (kDebugMode) {
        print("data add");
      }
    }

    minus()async{
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if(data['total'] == 1){
        if(_cData.length == 1){
          QuerySnapshot querySnapshot = await cart.where("userId", isEqualTo: prefs.getString("userId")).get();

          String docId = "";

          for (var doc in querySnapshot.docs) {
            docId = doc.id;
          }

          cart.doc(docId).update({
            'cart' : [],
            'updatedAt': DateTime.now().toString()
          });

          if (kDebugMode) {
            print("data add");
          }
        }else{
          _cData.remove(_cData.where((e) => e['id'] == id).toList().first);

          QuerySnapshot querySnapshot = await cart.where("userId", isEqualTo: prefs.getString("userId")).get();

          String docId = "";

          for (var doc in querySnapshot.docs) {
            docId = doc.id;
          }

          cart.doc(docId).update({
            'cart' : _cData,
            'updatedAt': DateTime.now().toString()
          });

          if (kDebugMode) {
            print("data add");
          }
        }

      }else{
        data.update("total", (value) => data['total'] - 1);
        _cData.add(data);
        _cData.remove(_cData.where((e) => e['id'] == id).toList().first);

        QuerySnapshot querySnapshot = await cart.where("userId", isEqualTo: prefs.getString("userId")).get();

        String docId = "";

        for (var doc in querySnapshot.docs) {
          docId = doc.id;
        }

        cart.doc(docId).update({
          'cart' : _cData,
          'updatedAt': DateTime.now().toString()
        });

        if (kDebugMode) {
          print("data add");
        }
      }
    }

    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height*0.01),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FadeInImage.assetNetwork(
              fit: BoxFit.cover,
              width: MediaQuery.sizeOf(context).width*0.3,
              height: MediaQuery.sizeOf(context).height*0.1,
              image: image,
              placeholder: 'assets/animations/loading_image.gif',
              placeholderFit: BoxFit.cover,
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
                  child: Text(name,maxLines: 1,overflow: TextOverflow.ellipsis,)),
              Text("Rp ${convertToIdr(price)}",style: TextStyle(
                color: Color(int.parse(primary()))
              ),),
              spaceVert(context, 0.01),
              Container(
                width: MediaQuery.sizeOf(context).width*0.3,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: (){
                        minus();
                      },
                      child: Container(
                          padding: EdgeInsets.all(5),
                          color: Colors.white,
                          child: Icon(Icons.remove,size: 15,)),
                    ),
                    Text("|"),
                    Text(convertToIdr(total)),
                    // StreamBuilder<QuerySnapshot>(
                    //     stream: cart.where("userId", isEqualTo: userId).snapshots(),
                    //     builder: (context,snapshot){
                    //       if(snapshot.hasError){
                    //         return Text("error");
                    //       }else if(snapshot.hasData){
                    //         List cData = snapshot.data!.docs.first['cart'].where((e) => e['id'] == id).toList();
                    //
                    //         return Text(convertToIdr(cData.first['total']));
                    //       }else{
                    //         return SizedBox(
                    //             height: 10,
                    //             width: 10,
                    //             child: CircularProgressIndicator());
                    //       }
                    //     }),
                    Text("|"),
                    GestureDetector(
                      onTap: (){
                        add();
                      },
                      child: Container(
                          padding: EdgeInsets.all(5),
                          color: Colors.white,
                          child: Icon(Icons.add,size: 15,)),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

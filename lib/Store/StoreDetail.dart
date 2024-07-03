import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:wargamart/Controller/MainPage.dart';

import '../GlobalVar.dart';
import 'StorePage.dart';

class StoreDetail extends StatefulWidget {
  final int id;
  const StoreDetail({super.key, required this.id});

  @override
  State<StoreDetail> createState() => _StoreDetailState();
}

class _StoreDetailState extends State<StoreDetail> {
  Map detail = {};
  CollectionReference product = FirebaseFirestore.instance.collection('Product');
  CollectionReference cart = FirebaseFirestore.instance.collection('Cart');
  bool fetching = false;
  List _cart = [];
  List _cartId = [];

  getData() async {
    setState(() {
      fetching = true;
    });
    try {
      QuerySnapshot querySnapshot = await product.where("id", isEqualTo: widget.id).get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          detail = doc.data() as Map;
        });

        print(detail);
      });

      await getCart();
    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      fetching = false;
    });
  }

  getCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      QuerySnapshot querySnapshot = await cart.get();
      querySnapshot.docs.forEach((doc) {
        Map data = doc.data() as Map;

        setState(() {
          _cart.add(doc.data());
          _cartId.add(data['id']);
        });

        print(_cart);
        print(_cartId);
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  addToCart()async{
    loading(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference cartItem = firestore.collection('Cart');

    if(_cart.isNotEmpty){
      int largestNumber = _cartId.reduce((currentMax, next) => currentMax > next ? currentMax : next);

      if(_cart.where((e) => e['userId'] == prefs.getString("userId")).toList().isEmpty){
        Map dataCart = detail;
        Map<String, dynamic> total = {'total':1};
        dataCart.addAll(total);

        await cartItem.add({
          'id': largestNumber + 1,
          'userId': prefs.getString("userId"),
          'cart' : [dataCart],
          'createdAt' : DateTime.now().toString(),
          'updatedAt': DateTime.now().toString()
        });
      }else{
        Map data = _cart.where((e) => e['userId'] == prefs.getString("userId")).toList().first;
        List dataCart = data['cart'];
        if(dataCart.where((e) => e['id'] == detail['id']).toList().isNotEmpty){
          Map data = dataCart.where((e) => e['id'] == detail['id']).toList().first;
          data.update("total", (value) => data['total'] + 1);
          dataCart.add(data);
          dataCart.remove(dataCart.where((e) => e['id'] == detail['id']).toList().first);
        }else{
          Map data = detail;
          Map<String, dynamic> total = {'total':1};
          data.addAll(total);

          dataCart.add(data);
        }

        if (kDebugMode) {
          print(dataCart);
        }

        QuerySnapshot querySnapshot = await cart.where("userId", isEqualTo: prefs.getString("userId")).get();

        String docId = "";

        for (var doc in querySnapshot.docs) {
          docId = doc.id;
        }

        cart.doc(docId).update({
          'cart' : dataCart,
          'updatedAt': DateTime.now().toString()
        });
      }
    }else{
      await cartItem.add({
        'id': 1,
        'userId': prefs.getString("userId"),
        'cart' : [detail]
      });
    }

    print('Data added to Firestore');
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil ditambah ke keranjang"),duration: Duration(seconds: 2),));
    // setState(() {
    //   _cart = [];
    //   _cartId = [];
    //   detail = {};
    // });
    //
    // await getData();


    // success("Berhasil ditambahkan", context,StoreDetail(id: widget.id));
    // try {
    //
    //
    // } catch (e) {
    //   print('Error adding data: $e');
    // }
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (BuildContext context) {
          return const MainPage(index: 0);
        }), (r) {
          return false;
        });

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: GestureDetector(
              onTap: (){
                Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(builder: (BuildContext context) {
                  return const MainPage(index: 0);
                }), (r) {
                  return false;
                });
              },
              child: Icon(Icons.arrow_back,size: 30,color: Colors.black,)
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Visibility(
          visible: fetching ? false : true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Divider(
                thickness: 3,
                height: MediaQuery.sizeOf(context).height*0.05,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width*0.4,
                    child: FloatingActionButton(
                      heroTag: "chat",
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)
                      ),
                        backgroundColor: Colors.red,
                        onPressed: (){
                        warning("This feature is under maintance", context);
                        },
                      child: Text("Chat Penjual",style: TextStyle(
                        color: Colors.white
                      ),),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width*0.4,
                    child: FloatingActionButton(
                      heroTag: "chart",
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)
                      ),
                        backgroundColor: Colors.blue,
                        onPressed: (){
                        addToCart();
                        },
                      child: Text("+ Keranjang",style: TextStyle(
                        color: Colors.white
                      ),),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: fetching ? Center(
          child: LottieBuilder.asset("assets/animations/loading1.json",width: 100,height: 100,),
        ) : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FadeInImage.assetNetwork(
                  width: MediaQuery.sizeOf(context).width*0.95,
                  height: MediaQuery.sizeOf(context).height*0.2,
                  image: detail['image'],
                  fit: BoxFit.cover,
                  placeholder: 'assets/animations/loading_image.gif',
                  imageErrorBuilder: (context, error, trace) {
                    return  const Image(
                        image: AssetImage("assets/images/default.png")
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rp ${convertToIdr(detail['price'])}",style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue
                  ),),
                  spaceVert(context, 0.005),
                  Text(detail['name']),
                  spaceVert(context, 0.005),
                  Text("Terjual ${convertToIdr(detail['sold'])}",style: TextStyle(
                    fontSize: 12
                  ),),
                  spaceVert(context, 0.01),
                  Text("Detail Produk",style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),),
                  spaceVert(context, 0.01),
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width*0.3,
                        child: Text("Kondisi",style: TextStyle(
                          color: Colors.grey
                        ),),
                      ),
                      Text(detail['condition'])
                    ],
                  ),
                  Divider(
                    thickness: 2,
                    height: MediaQuery.sizeOf(context).height*0.02,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width*0.3,
                        child: Text("Kategori",style: TextStyle(
                          color: Colors.grey
                        ),),
                      ),
                      Text(detail['category'])
                    ],
                  ),
                  Divider(
                    thickness: 2,
                    height: MediaQuery.sizeOf(context).height*0.02,
                  ),
                  // Row(
                  //   children: [
                  //     SizedBox(
                  //       width: MediaQuery.sizeOf(context).width*0.3,
                  //       child: Text("Min. Pembelian",style: TextStyle(
                  //         color: Colors.grey
                  //       ),),
                  //     ),
                  //     Text(detail['min_bought'].toString())
                  //   ],
                  // ),
                  // Divider(
                  //   thickness: 2,
                  //   height: MediaQuery.sizeOf(context).height*0.02,
                  // ),
                  spaceVert(context, 0.01),
                  Text("Deskripsi Produk"),
                  spaceVert(context, 0.01),
                  Text(detail['description']),
                  spaceVert(context, 0.01),
                  GestureDetector(
                    onTap: (){
                      showModalBottomSheet(
                          isScrollControlled: true,
                          constraints: BoxConstraints(
                              maxHeight: MediaQuery.sizeOf(context).height*0.7,
                              minWidth: MediaQuery.sizeOf(context).width
                          ),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10)
                              )
                          ),
                          context: context,
                          builder: (context){
                            return Padding(
                                padding: EdgeInsets.fromLTRB(10, 10, 10, MediaQuery.of(context).viewInsets.bottom),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          height: MediaQuery.sizeOf(context).height*0.006,
                                          width: MediaQuery.sizeOf(context).width*0.3,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(10)
                                          ),
                                        ),
                                      ),
                                      spaceVert(context, 0.01),
                                      Text("Detail Produk",style: TextStyle(
                                        fontWeight: FontWeight.bold
                                      ),),
                                      spaceVert(context, 0.01),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.sizeOf(context).width*0.3,
                                            child: Text("Kondisi",style: TextStyle(
                                                color: Colors.grey
                                            ),),
                                          ),
                                          Text(detail['condition'])
                                        ],
                                      ),
                                      Divider(
                                        thickness: 2,
                                        height: MediaQuery.sizeOf(context).height*0.02,
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.sizeOf(context).width*0.3,
                                            child: Text("Kategori",style: TextStyle(
                                                color: Colors.grey
                                            ),),
                                          ),
                                          Text(detail['category'])
                                        ],
                                      ),
                                      Divider(
                                        thickness: 2,
                                        height: MediaQuery.sizeOf(context).height*0.02,
                                      ),
                                      // Row(
                                      //   children: [
                                      //     SizedBox(
                                      //       width: MediaQuery.sizeOf(context).width*0.3,
                                      //       child: Text("Min. Pembelian",style: TextStyle(
                                      //           color: Colors.grey
                                      //       ),),
                                      //     ),
                                      //     Text(detail['min_bought'].toString())
                                      //   ],
                                      // ),
                                      // Divider(
                                      //   thickness: 2,
                                      //   height: MediaQuery.sizeOf(context).height*0.02,
                                      // ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.sizeOf(context).width*0.3,
                                            child: Text("Berat",style: TextStyle(
                                                color: Colors.grey
                                            ),),
                                          ),
                                          Text(convertToIdr(detail['weight']))
                                        ],
                                      ),
                                      Divider(
                                        thickness: 2,
                                        height: MediaQuery.sizeOf(context).height*0.02,
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.sizeOf(context).width*0.3,
                                            child: Text("Dikirim Dari",style: TextStyle(
                                                color: Colors.grey
                                            ),),
                                          ),
                                          Text(detail['send_from'])
                                        ],
                                      ),
                                      Divider(
                                        thickness: 2,
                                        height: MediaQuery.sizeOf(context).height*0.02,
                                      ),
                                      spaceVert(context, 0.01),
                                      Text("Deskripsi Produk"),
                                      spaceVert(context, 0.01),
                                      Text(detail['description']),
                                      spaceVert(context, 0.01),
                                    ],
                                  ),
                                )
                            );
                          });
                    },
                    child: Text("Selengkapnya",style: TextStyle(
                      color: Colors.blue
                    ),),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

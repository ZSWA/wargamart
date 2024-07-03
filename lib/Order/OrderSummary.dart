import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/shared/types.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Address/AddAddress.dart';
import 'package:wargamart/Address/UpdateAddress.dart';
import 'package:wargamart/Cart/CartPage.dart';
import 'package:wargamart/Controller/MainPage.dart';
import 'package:wargamart/GlobalVar.dart';
import 'package:wargamart/Order/DetailOrder.dart';
import 'package:wargamart/Order/MyOrderPage.dart';

class OrderSummary extends StatefulWidget {
  final List cartItem;
  const OrderSummary({super.key, required this.cartItem});

  @override
  State<OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<OrderSummary> {
  Map address = {};
  int totalPrice = 0;
  List delivery = [];
  Map selectedDelivery = {};
  List voucher = [];
  Map selectedVoucher = {};
  List payment = [];
  Map selectedPayment = {};
  bool fetchingDelivery = false;
  bool fetchingVoucher = false;
  bool fetchingPayment = false;
  bool fetchingAddress = false;
  CollectionReference _delivery = FirebaseFirestore.instance.collection('Delivery');
  CollectionReference _voucher = FirebaseFirestore.instance.collection('Voucher');
  CollectionReference _paymentMetode = FirebaseFirestore.instance.collection('Payment');
  CollectionReference _address = FirebaseFirestore.instance.collection('Address');
  int totalPay = 0;

  getDelivery() async {
    setState(() {
      fetchingDelivery = true;
    });
    try {
      QuerySnapshot querySnapshot = await _delivery.get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          delivery.add(doc.data());
          delivery.sort((a,b) => a['name'].compareTo(b['name']));
        });
      });
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetchingDelivery = false;
    });
  }

  getAddress() async {
    setState(() {
      fetchingAddress = true;
    });
    try {
      QuerySnapshot querySnapshot = await _address.get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          address.addAll(doc.data() as Map);
        });
      });
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetchingAddress = false;
    });
  }

  getVoucher() async {
    setState(() {
      fetchingVoucher = true;
    });
    try {
      QuerySnapshot querySnapshot = await _voucher.where("isUsed", isEqualTo: false).get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          voucher.add(doc.data());
          voucher.sort((a,b) => a['name'].compareTo(b['name']));
        });
      });
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetchingVoucher = false;
    });
  }

  getPayment() async {
    setState(() {
      fetchingPayment = true;
    });
    try {
      QuerySnapshot querySnapshot = await _paymentMetode.where("active", isEqualTo: true).get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          payment.add(doc.data());
          payment.sort((a,b) => a['name'].compareTo(b['name']));
        });
      });
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetchingPayment = false;
    });
  }

  setTotalPrice(){
    List priceList = [];

    for(int i = 0;i<widget.cartItem.length;i++){
      priceList.add(widget.cartItem[i]['price'] * widget.cartItem[i]['total']);

      setState(() {
        totalPrice = priceList.reduce((value, e) => value + e);
      });

    }
  }

  checkout()async{
    loading(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference _checkout = firestore.collection('Checkout');
    CollectionReference _cart = firestore.collection('Cart');
    CollectionReference _product = firestore.collection('Product');
    List checkout = [];
    String cartDocId = "";
    String voucherDocId = "";

    try{
      QuerySnapshot querySnapshot = await _checkout.where("userId", isEqualTo: prefs.getString("userId")).get();
      for (var doc in querySnapshot.docs) {
        Map data = doc.data() as Map;
        checkout.add(data['id']);
      }

      QuerySnapshot querySnapshot1 = await _cart.where("userId", isEqualTo: prefs.getString("userId")).get();
      for (var doc in querySnapshot1.docs) {
        cartDocId = doc.id;
      }

      int largestNumber = checkout.isEmpty ? 0 : checkout.reduce((currentMax, next) => currentMax > next ? currentMax : next);

      int totPay = 0;

      if(selectedVoucher.isNotEmpty){
        if((totalPrice < (selectedVoucher['price']))){
          totPay = 0;
        }else{
          totPay = int.parse(((totalPrice + (selectedDelivery.isEmpty ? 0 : selectedDelivery['price'])) - (selectedVoucher.isEmpty ? 0 : selectedVoucher['price'])).toString());
        }
      }else{
        totPay = int.parse((totalPrice + (selectedDelivery.isEmpty ? 0 : selectedDelivery['price'])).toString());
      }

      print("total pay : $totPay");

      await _checkout.add({
        'userId' : prefs.getString('userId'),
        'id': largestNumber,
        'delivery' : selectedDelivery,
        'address' : address,
        'paymentMode': selectedPayment,
        'voucher': selectedVoucher,
        'cart': widget.cartItem,
        'totalPay': totPay,
        'createdAt': DateTime.now().toString()
      });

      for(int i = 0;i<widget.cartItem.length;i++){
        QuerySnapshot querySnapshot3 = await _product.where("id", isEqualTo: widget.cartItem[i]['id']).get();
        String proId = "";
        for(var doc in querySnapshot3.docs){
          proId = doc.id;
        }

        await _product.doc(proId).update({
          'sold' : widget.cartItem[i]['sold'] + widget.cartItem[i]['total']
        });
      }

      if(selectedVoucher.isNotEmpty){
        QuerySnapshot querySnapshot2 = await _voucher.where("id", isEqualTo: selectedVoucher['id']).get();
        for (var doc in querySnapshot2.docs) {
          voucherDocId = doc.id;
        }

        await _voucher.doc(voucherDocId).update({
          'isUsed' : true
        });
      }

      await _cart.doc(cartDocId).update({
        'cart' : [],
        'updatedAt': DateTime.now().toString()
      });

      Navigator.pop(context);
      success("Berhasil membuat pesanan", context,DetailOrder(data: {
        'userId' : prefs.getString('userId'),
        'id': largestNumber,
        'delivery' : selectedDelivery,
        'address' : address,
        'paymentMode': selectedPayment,
        'voucher': selectedVoucher,
        'cart': widget.cartItem,
        'totalPay': totPay,
        'createdAt': DateTime.now().toString()
      }));
    } catch (e) {
      // Handle registration errors
      Navigator.pop(context);
      print('Error Checkout: $e');
      warning(e.toString(), context);
    }
  }

  @override
  void initState() {
    setTotalPrice();
    getAddress();
    getDelivery();
    getVoucher();
    getPayment();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: (){
            Get.off(()=> const CartPage());
          },
          child: Icon(Icons.arrow_back,size: 30,color: Colors.black,),
        ),
        title: Text("Ringkasan Pesanan"),
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
            if(address.isEmpty){
              warning("Mohon pilih alamat", context);
            }else if(selectedDelivery.isEmpty){
              warning("Mohon pilih opsi pengiriman", context);
            }else if(selectedPayment.isEmpty){
              warning("Mohon pilih metode pembayaran", context);
            }else{
              checkout();
            }
          },
          child: Text("Bayar Rp. ${convertToIdr(totalPrice + (selectedDelivery.isEmpty ? 0 : selectedDelivery['price']) - (selectedVoucher.isEmpty ? 0 : selectedVoucher['price']))}",style: TextStyle(
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
              Text("Alamat",style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              address.isNotEmpty ? Center(
                child: Container(
                  padding: EdgeInsets.all(10),
                  width: MediaQuery.sizeOf(context).width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey
                    )
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address['name'] ?? ""),
                      spaceVert(context, 0.01),
                      Text("${address['village']}, ${address['subdistrict']}, ${address['district']}"),
                      Text("${address['postal_code']}")
                    ],
                  ),
                ),
              ) : GestureDetector(
                onTap: (){
                  Get.off(()=> AddAddress(cartItem: widget.cartItem));
                },
                child: Center(
                  child: Container(
                    height: MediaQuery.sizeOf(context).height*0.1,
                    width: MediaQuery.sizeOf(context).width,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey
                      )
                    ),
                    child: Text("+ Tambah Alamat"),
                  ),
                ),
              ),
              spaceVert(context, 0.01),
              Visibility(
                visible: address.isNotEmpty ? true : false,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(int.parse(primary()))
                    ),
                      onPressed: (){
                      Get.off(()=> UpdatedAddress(cartItem: widget.cartItem, data: address));
                      },
                      child: Text("Ubah Alamat",style: TextStyle(
                        color: Colors.white
                      ),)),
                ),
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Text("Pesanan",style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.cartItem.length,
                  itemBuilder: (context, index){
                    List data = widget.cartItem;
                    return cartCard(
                      data[index]['name'],
                      data[index]['total'],
                      data[index]['price'],
                      data[index]['image'],
                    );
                  }),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Text("Pengiriman",style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  selectedDelivery.isEmpty ? Text("Opsi Pengiriman") : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedDelivery['name']),
                      Text("Rp ${convertToIdr(selectedDelivery['price'])}")
                    ],
                  ),
                  GestureDetector(
                    onTap: (){
                      Dialogs.materialDialog(
                          color: Colors.white,
                          title: "Pilih Pengiriman",
                          customViewPosition: CustomViewPosition.BEFORE_MESSAGE,
                          customView: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ListView.builder(
                                itemCount: delivery.length,
                                shrinkWrap: true,
                                itemBuilder: (context,index){
                                  return GestureDetector(
                                    onTap: (){
                                      setState(() {
                                        selectedDelivery = delivery[index];
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(delivery[index]['name']),
                                          Text("Rp ${convertToIdr(delivery[index]['price'])}")
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                          ),
                          context: context,
                      );
                    },
                    child: Row(
                      children: [
                        Text("Pilih pengiriman",style: TextStyle(
                          color: Colors.blue
                        ),),
                        Icon(Icons.arrow_forward_ios,color: Colors.blue,),
                      ],
                    ),
                  )
                ],
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Pesanan"),
                  Text("Rp ${convertToIdr(totalPrice + (selectedDelivery.isEmpty ? 0 : selectedDelivery['price']))}")
                ],
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Text("Voucher",style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  selectedVoucher.isEmpty ? Text("Opsi Voucher") : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedVoucher['name']),
                      Text("Rp ${convertToIdr(selectedVoucher['price'])}")
                    ],
                  ),
                  GestureDetector(
                    onTap: (){
                      Dialogs.materialDialog(
                        color: Colors.white,
                        title: "Pilih Voucher",
                        customViewPosition: CustomViewPosition.BEFORE_MESSAGE,
                        customView: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: voucher.isEmpty ? Center(
                            child: Text("Belum ada voucher"),
                          ) : ListView.builder(
                              itemCount: voucher.length,
                              shrinkWrap: true,
                              itemBuilder: (context,index){
                                return GestureDetector(
                                  onTap: (){
                                    setState(() {
                                      selectedVoucher = voucher[index];
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(voucher[index]['name']),
                                        Text("Rp ${convertToIdr(voucher[index]['price'])}")
                                      ],
                                    ),
                                  ),
                                );
                              }),
                        ),
                        context: context,
                      );
                    },
                    child: Row(
                      children: [
                        Text("Pilih voucher",style: TextStyle(
                            color: Colors.blue
                        ),),
                        Icon(Icons.arrow_forward_ios,color: Colors.blue,),
                      ],
                    ),
                  )
                ],
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Text("Metode Pembayaran",style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  selectedPayment.isEmpty ? Text("Opsi Metode Pembayaran") : Text(selectedPayment['name']),
                  GestureDetector(
                    onTap: (){
                      Dialogs.materialDialog(
                        color: Colors.white,
                        title: "Pilih Metode Pembayaran",
                        customViewPosition: CustomViewPosition.BEFORE_MESSAGE,
                        customView: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ListView.builder(
                              itemCount: payment.length,
                              shrinkWrap: true,
                              itemBuilder: (context,index){
                                return GestureDetector(
                                  onTap: (){
                                    setState(() {
                                      selectedPayment = payment[index];
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
                                    child: Text(payment[index]['name']),
                                  ),
                                );
                              }),
                        ),
                        context: context,
                      );
                    },
                    child: Row(
                      children: [
                        Text("Pilih Metode Pembayaran",style: TextStyle(
                            color: Colors.blue
                        ),),
                        Icon(Icons.arrow_forward_ios,color: Colors.blue,),
                      ],
                    ),
                  )
                ],
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Row(
                children: [
                  Icon(Icons.receipt,size: 20,color: Color(int.parse(primary())),),
                  spaceHoriz(context, 0.02),
                  Text("Ringkasan Pembayaran")
                ],
              ),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Pesanan"),
                  Text("Rp ${convertToIdr(totalPrice)}"),
                ],
              ),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Pengiriman"),
                  Text("Rp ${convertToIdr(selectedDelivery.isEmpty ? 0 : selectedDelivery['price'])}"),
                ],
              ),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Voucher"),
                  Text("- Rp ${convertToIdr(selectedVoucher.isEmpty ? 0 : selectedVoucher['price'])}"),
                ],
              ),
              spaceVert(context, 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget cartCard(String name, int total, int price,String image) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height*0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FadeInImage.assetNetwork(
              width: MediaQuery.sizeOf(context).width*0.3,
              height: MediaQuery.sizeOf(context).height*0.1,
              image: image,
              fit: BoxFit.cover,
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
                  child: Text(name,maxLines: 1,overflow: TextOverflow.ellipsis,style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),)
              ),
              spaceVert(context, 0.01),
              SizedBox(
                width: MediaQuery.sizeOf(context).width*0.6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rp ${convertToIdr(price)}"),
                    Text("x${total.toString()}")
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

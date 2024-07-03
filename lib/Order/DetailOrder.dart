import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Order/MyOrderPage.dart';

import '../GlobalVar.dart';

class DetailOrder extends StatefulWidget {
  final Map data;
  const DetailOrder({super.key, required this.data});

  @override
  State<DetailOrder> createState() => _DetailOrderState();
}

class _DetailOrderState extends State<DetailOrder> {
  int totalPrice = 0;

  setTotalPrice(){
    List priceList = [];

    for(int i = 0;i<widget.data['cart'].length;i++){
      priceList.add(widget.data['cart'][i]['price'] * widget.data['cart'][i]['total']);

      setState(() {
        totalPrice = priceList.reduce((value, e) => value + e);
      });

    }
  }

  @override
  void initState() {
    setTotalPrice();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            Get.off(() => MyOrderPage());
          },
          child: Icon(Icons.arrow_back, size: 30, color: Colors.black,),
        ),
        title: Text("Detail"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Alamat", style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              Center(
                child: Container(
                  padding: EdgeInsets.all(10),
                  width: MediaQuery
                      .sizeOf(context)
                      .width,
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
                      Text(widget.data['address']['name'] ?? "",style: TextStyle(
                        fontWeight: FontWeight.bold
                      ),),
                      spaceVert(context, 0.01),
                      Text(
                          "${widget.data['address']['village']}, ${widget.data['address']['subdistrict']}, ${widget.data['address']['district']}"),
                      Text("${widget.data['address']['postal_code']}")
                    ],
                  ),
                ),
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Text("Pesanan", style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.data['cart'].length,
                  itemBuilder: (context, index) {
                    List data = widget.data['cart'];
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
              Text("Pengiriman", style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.data['delivery']['name'],style: TextStyle(
                        fontWeight: FontWeight.bold
                      ),),
                      Text("Rp ${convertToIdr(widget.data['delivery']['price'])}")
                    ],
                  ),
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
                  Text("Total Pesanan",style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),),
                  Text("Rp ${convertToIdr(totalPrice + (widget.data['delivery']['price']))}")
                ],
              ),
              Visibility(
                visible: widget.data['voucher'].toString() == "{}" ? false : true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    spaceVert(context, 0.01),
                    Divider(
                      thickness: 2,
                    ),
                    spaceVert(context, 0.01),
                    Text("Voucher", style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    ),),
                    spaceVert(context, 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.data['voucher']['name'] ?? "",style: TextStyle(
                              fontWeight: FontWeight.bold
                            ),),
                            Text("Rp ${convertToIdr(widget.data['voucher']['price'] ?? 0)}")
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Text("Metode Pembayaran", style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),),
              spaceVert(context, 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.data['paymentMode']['name']),
                ],
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Row(
                children: [
                  Icon(Icons.receipt, size: 20,
                    color: Color(int.parse(primary())),),
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
                  Text("Rp ${convertToIdr(widget.data['delivery']['price'])}"),
                ],
              ),
              Visibility(
                  visible: widget.data['voucher'].toString() == "{}" ? false : true,
                  child: spaceVert(context, 0.01)),
              Visibility(
                visible: widget.data['voucher'].toString() == "{}" ? false : true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Voucher"),
                    Text("- Rp ${convertToIdr(widget.data['voucher']['price'] ?? 0)}"),
                  ],
                ),
              ),
              spaceVert(context, 0.01),
              Divider(
                thickness: 2,
              ),
              spaceVert(context, 0.01),
              Center(
                child: Text("Total Bayar",style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
                ),),
              ),
              Center(
                child: Text("Rp. ${convertToIdr(widget.data['totalPay'])}",style: TextStyle(
                  fontSize: 18
                ),),
              ),
              spaceVert(context, 0.05)
            ],
          ),
        ),
      ),
    );
  }

  Widget cartCard(String name, int total, int price, String image) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height*0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FadeInImage.assetNetwork(
              width: MediaQuery.sizeOf(context).width * 0.3,
              height: MediaQuery.sizeOf(context).height*0.1,
              image: image,
              fit: BoxFit.cover,
              placeholder: 'assets/animations/loading_image.gif',
              imageErrorBuilder: (context, error, trace) {
                return const Image(
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
                  width: MediaQuery
                      .sizeOf(context)
                      .width * 0.6,
                  child: Text(name, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),)
              ),
              spaceVert(context, 0.01),
              SizedBox(
                width: MediaQuery
                    .sizeOf(context)
                    .width * 0.6,
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

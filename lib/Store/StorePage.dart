import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convert/convert.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/shared/types.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:wargamart/Cart/CartPage.dart';

import '../Controller/MainPage.dart';
import '../GlobalVar.dart';
import 'StoreDetail.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  TextEditingController _search = TextEditingController();
  final CarouselController _controller = CarouselController();
  CollectionReference product = FirebaseFirestore.instance.collection('Product');
  CollectionReference banner = FirebaseFirestore.instance.collection('Banner');
  CollectionReference category = FirebaseFirestore.instance.collection('Category');
  bool fetching = false;
  bool fetchingBann = false;
  bool fetchingCat = false;
  List _product = [];
  List _banner = [];
  List _category = [];
  String selectedCat = "All";

  getData() async {
    setState(() {
      fetching = true;
    });
    late QuerySnapshot querySnapshot;
    try {
      if(selectedCat == "All"){
        querySnapshot = await product.get();
      }else{
        querySnapshot = await product.where("category", isEqualTo: selectedCat).get();
      }
      querySnapshot.docs.forEach((doc) {
        setState(() {
          _product.add(doc.data());
        });
      });
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetching = false;
    });
  }

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

      setState(() {
        _category.insert(0, {"name": "All"});
      });
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      fetchingCat = false;
    });
  }

  getBan() async {
    setState(() {
      fetchingBann = true;
    });
    try {
      QuerySnapshot querySnapshot = await banner.get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          _banner.add(doc.data());
        });
      });

      await getCat();
      await getData();
    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      fetchingBann = false;
    });
  }

  @override
  void initState() {
    getBan();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text("Warga Mart",style: TextStyle(
          color: Colors.black
        ),),
        actions: [
          GestureDetector(
            onTap: (){
              Get.off(()=> const CartPage());
            },
            child: Icon(Icons.shopping_cart,size: 30,),
          ),
          spaceHoriz(context, 0.02)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height*0.06,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey
                      )
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    labelText: "Ketik untuk mencari..",
                    suffixIcon: Icon(Icons.search)
                  ),
                ),
              ),
              spaceVert(context, 0.01),
              fetchingBann ? SizedBox(
                height: MediaQuery.sizeOf(context).height*0.22,
                child: LottieBuilder.asset("assets/animations/skeleton.json"),
              ) : CarouselSlider(
                carouselController: _controller,
                options: CarouselOptions(
                    autoPlay: true,
                    // onPageChanged: (index,reason){
                    //   setState(() {
                    //     _current = index;
                    //   });
                    // },
                    enableInfiniteScroll: false,
                    height: MediaQuery.of(context).size.height*0.22
                ),
                items: _banner.map((i) {
                  return GestureDetector(
                    onTap: (){
                      Dialogs.materialDialog(
                          dialogShape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15)
                              )
                          ),
                          color: Colors.white,
                          customViewPosition: CustomViewPosition.BEFORE_MESSAGE,
                          customView: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxHeight: MediaQuery.sizeOf(context).height*0.7
                              ),
                              child: FadeInImage.assetNetwork(
                                fit: BoxFit.cover,
                                width: MediaQuery.sizeOf(context).width,
                                image: i['image'],
                                placeholder: 'assets/animations/loading_image.gif',
                                imageErrorBuilder: (context, error, trace) {
                                  return  const Image(
                                      image: AssetImage("assets/images/default.png")
                                  );
                                },
                              )
                          ),
                          context: context,
                          actions: [
                            IconsButton(
                              onPressed: (){
                                Get.back();
                              },
                              text: 'OK',
                            )
                          ]
                      );
                    },
                    child: Builder(
                      builder: (BuildContext context) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FadeInImage.assetNetwork(
                              fit: BoxFit.cover,
                              width: MediaQuery.sizeOf(context).width,
                              image: i['image'],
                              placeholder: 'assets/animations/loading_image.gif',
                              imageErrorBuilder: (context, error, trace) {
                                return  const Image(
                                    image: AssetImage("assets/images/default.png")
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
              spaceVert(context, 0.01),
              SizedBox(
                height: MediaQuery.sizeOf(context).height*0.05,
                child: fetchingCat ? ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    itemBuilder: (context, index){
                      return Container(
                        width: MediaQuery.sizeOf(context).width*0.2,
                        alignment: Alignment.center,
                        margin: EdgeInsets.fromLTRB(index == 0 ? 0 : 5, 0, 5, 0),
                        decoration: BoxDecoration(
                            color: Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: LottieBuilder.asset("assets/animations/skeleton.json")
                      );
                    }) : ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: _category.length,
                    itemBuilder: (context, index){
                      return GestureDetector(
                        onTap: ()async{
                          setState(() {
                            selectedCat = _category[index]['name'];
                            _product = [];
                            fetching = true;
                          });

                          await getData();

                          setState(() {
                            fetching = false;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(10),
                          margin: EdgeInsets.fromLTRB(index == 0 ? 0 : 5, 0, 5, 0),
                          decoration: BoxDecoration(
                            color: Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(_category[index]['name'],style: TextStyle(
                            color: _category[index]['name'] == selectedCat ? Colors.grey[700] : Colors.white
                          ),),
                        ),
                      );
                    }),
              ),
              spaceVert(context, 0.01),
              fetching ? GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20
                  ),
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey
                            ),
                            borderRadius: BorderRadius.circular(5)
                        ),
                        child: LottieBuilder.asset("assets/animations/loading.json"));
                  }) : Container(
                    child: _product.isEmpty ? SizedBox(
                      height: MediaQuery.sizeOf(context).height*0.4,
                      child: Center(
                        child: Text("Belum ada produk"),
                      ),
                    ) : GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20
                    ),
                    itemCount: _product.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ProductCard(
                          _product[index]['id'],
                          _product[index]['image'],
                          _product[index]['name'],
                          _product[index]['price'],
                          _product[index]['sold'],
                      );
                    }),
                  )
            ],
          ),
        ),
      ),
    );
  }

  Widget ProductCard(int id, String image, String name, int price, int sold) {
    return GestureDetector(
      onTap: (){
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (BuildContext context) {
          return StoreDetail(id: id,);
        }), (r) {
          return false;
        });
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey
          ),
          borderRadius: BorderRadius.circular(5)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FadeInImage.assetNetwork(
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height*0.15,
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
            spaceVert(context, 0.01),
            Text(name,maxLines: 2,overflow: TextOverflow.ellipsis,),
            spaceVert(context, 0.01),
            Text("Rp. ${convertToIdr(price)}",style: TextStyle(
              color: Colors.blue
            ),),
            spaceVert(context, 0.005),
            Text("${convertToIdr(sold)} Terjual")
          ],
        ),
      ),
    );
  }
}

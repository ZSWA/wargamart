import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/GlobalVar.dart';
import 'package:wargamart/Order/MyOrderPage.dart';
import 'package:wargamart/Profile/UpdateProfile.dart';
import 'package:wargamart/Store/AddProduct.dart';
import 'package:wargamart/Voucher/AddVoucher.dart';

import '../User/LoginPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool fetching = false;
  CollectionReference user = FirebaseFirestore.instance.collection('Users');
  Map _user = {};

  getData() async {
    setState(() {
      fetching = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      QuerySnapshot querySnapshot = await user.where("userId", isEqualTo: prefs.getString("userId")).get();
      querySnapshot.docs.forEach((doc) {
        setState(() {
          _user = doc.data() as Map;
        });
      });

      if (kDebugMode) {
        print(_user);
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
    getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: fetching ? Center(
        child: LottieBuilder.asset("assets/animations/loading1.json",width: 100,height: 100,),
      ) : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          spaceVert(context, 0.08),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_user['image']),
            ),
          ),
          spaceVert(context, 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width*0.9
                ),
                child: Text(_user['full_name'],style: TextStyle(
                  fontSize: 16
                ),maxLines: 1,overflow: TextOverflow.ellipsis,textAlign: TextAlign.center,),
              ),
              spaceHoriz(context, 0.01),
              Visibility(
                  visible: _user['type'] == "seller" ? true : false,
                  child: Icon(Icons.verified,size: 15,color: Color(int.parse(primary())),))
            ],
          ),
          spaceVert(context, 0.02),
          Divider(
            thickness: 2,
          ),
          GestureDetector(
            onTap: (){
              Get.off(()=> UpdateProfile(data: _user));
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ubah Profile"),
                  Icon(Icons.arrow_forward_ios)
                ],
              ),
            ),
          ),
          Divider(
            thickness: 2,
          ),
          Visibility(
            visible: _user['type'] == "seller" ? true : false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: (){
                    Get.off(()=> AddProduct());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tambah Produk"),
                        Icon(Icons.arrow_forward_ios)
                      ],
                    ),
                  ),
                ),
                Divider(
                  thickness: 2,
                ),
                GestureDetector(
                  onTap: (){
                    Get.off(()=> AddVoucher());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tambah Voucher"),
                        Icon(Icons.arrow_forward_ios)
                      ],
                    ),
                  ),
                ),
                Divider(
                  thickness: 2,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: (){
              Get.off(()=> MyOrderPage());
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Pesanan Saya"),
                  Icon(Icons.arrow_forward_ios)
                ],
              ),
            ),
          ),
          Divider(
            thickness: 2,
          ),
          GestureDetector(
            onTap: ()async{
              SharedPreferences prefs = await SharedPreferences.getInstance();

              Dialogs.materialDialog(
                  barrierDismissible: false,
                  color: Colors.white,
                  msg: "Apakah anda ingin keluar?",
                  msgAlign: TextAlign.center,
                  lottieBuilder: LottieBuilder.asset("assets/animations/warning.json"),
                  context: context,
                  actions: [
                    IconsButton(
                      onPressed: (){
                        prefs.clear();
                        Get.off(()=> const LoginPage());
                      },
                      text: 'Keluar',
                    ),
                    IconsButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      text: 'Batal',
                    ),
                  ]
              );


            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Log-Out",style: TextStyle(
                    color: Colors.red
                  ),),
                  Icon(Icons.arrow_forward_ios,color: Colors.red,)
                ],
              ),
            ),
          ),
          Divider(
            thickness: 2,
          ),
        ],
      ),
    );
  }
}

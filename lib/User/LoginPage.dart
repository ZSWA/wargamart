import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wargamart/Controller/MainPage.dart';
import 'package:wargamart/GlobalVar.dart';
import 'package:wargamart/User/RegisterPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  bool hide = true;

  signIn(String email, String password) async {
    loading(context);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      addAccess(userCredential.user!.uid, userCredential.user!.email!);

      if (kDebugMode) {
        print('User ID: ${userCredential.user?.uid}');
      }

      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context){
            return MainPage(index: 0);
      }), (route) => false);

    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  addAccess(String id, String email)async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString("userId", id);
    prefs.setString("email", email);
  }

  checkLoginStatus()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if(prefs.getString("userId") != null){
      return "login";
    }else{
      return "no";
    }
  }

  @override
  void initState() {
    checkLoginStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: checkLoginStatus(),
        builder: (context, snapshot){
          if(snapshot.hasData){
            if(snapshot.data == "login"){
              return MainPage(index: 0);
            }else{
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Warga Mart",style: TextStyle(
                            color: Colors.black,
                            fontSize: 40
                        ),),
                        spaceVert(context, 0.05),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height*0.06,
                          child: TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                labelText: "Username",
                                border: OutlineInputBorder()
                            ),
                          ),
                        ),
                        spaceVert(context, 0.01),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height*0.06,
                          child: TextField(
                            controller: _password,
                            obscureText: hide,
                            decoration: InputDecoration(
                                fillColor: Colors.white,
                                filled: true,
                                labelText: "Password",
                                border: OutlineInputBorder(),
                                suffixIcon: GestureDetector(
                                    onTap: (){
                                      if(hide){
                                        setState(() {
                                          hide = false;
                                        });
                                      }else{
                                        setState(() {
                                          hide = true;
                                        });
                                      }
                                    },
                                    child: Icon(Icons.remove_red_eye,color: hide ? Colors.grey : Color(int.parse(primary())),))
                            ),
                          ),
                        ),
                        spaceVert(context, 0.02),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height*0.06,
                          width: MediaQuery.sizeOf(context).width,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(int.parse(primary()))
                              ),
                              onPressed: ()async{
                                await signIn(_email.text, _password.text);
                              },
                              child: Text("Masuk",style: TextStyle(
                                  color: Colors.white
                              ),)),
                        ),
                        spaceVert(context, 0.01),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Belum punya akun? "),
                            GestureDetector(
                              onTap: (){
                                Get.off(()=> RegisterPage());
                              },
                              child: Text("daftar sekarang!",style: TextStyle(
                                color: Color(int.parse(primary())),
                                decoration: TextDecoration.underline
                              ),),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            }
          }else if(snapshot.hasError){
            return Scaffold(
              body: Center(
                child: Text(snapshot.error.toString()),
              ),
            );
          }else{
            return Scaffold(
              body: Center(
                child: LottieBuilder.asset("assets/animations/loading1.json",width: 100,height: 100,),
              ),
            );
          }
        });
  }
}

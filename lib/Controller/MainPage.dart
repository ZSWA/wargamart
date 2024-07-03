import 'package:flutter/material.dart';
import 'package:motion_tab_bar_v2/motion-badge.widget.dart';
import 'package:motion_tab_bar_v2/motion-tab-bar.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';
import 'package:wargamart/GlobalVar.dart';
import 'package:wargamart/Profile/ProfilePage.dart';
import 'package:wargamart/Store/StorePage.dart';
import 'package:wargamart/Voucher/VoucherPage.dart';

class MainPage extends StatefulWidget {
  final int index;
  const MainPage({super.key, required this.index});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin{
  MotionTabBarController? _motionTabBarController;
  List<String> tab = ["Store", "Voucher", "Profil"];

  @override
  void initState() {

    setState(() {
      _motionTabBarController = MotionTabBarController(
        initialIndex: widget.index,
        length: 3,
        vsync: this,
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _motionTabBarController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      bottomNavigationBar: MotionTabBar(
        controller: _motionTabBarController,
        initialSelectedTab: tab[widget.index],
        labels: tab,
        icons: const [Icons.shopping_basket, Icons.discount, Icons.person],
        //
        // // optional badges, length must be same with labels
        // badges: [
        //   // Default Motion Badge Widget
        //   const MotionBadgeWidget(
        //     text: '99+',
        //     textColor: Colors.white, // optional, default to Colors.white
        //     color: Colors.red, // optional, default to Colors.red
        //     size: 18, // optional, default to 18
        //   ),
        //
        //   // custom badge Widget
        //   Container(
        //     color: Colors.black,
        //     padding: const EdgeInsets.all(2),
        //     child: const Text(
        //       '48',
        //       style: TextStyle(
        //         fontSize: 14,
        //         color: Colors.white,
        //       ),
        //     ),
        //   ),
        //
        //   // allow null
        //   null,
        //
        //   // Default Motion Badge Widget with indicator only
        //   const MotionBadgeWidget(
        //     isIndicator: true,
        //     color: Colors.red, // optional, default to Colors.red
        //     size: 5, // optional, default to 5,
        //     show: true, // true / false
        //   ),
        // ],
        tabSize: 40,
        tabBarHeight: MediaQuery.sizeOf(context).height*0.05,
        textStyle: TextStyle(
          fontSize: 12,
          color: Color(int.parse(primary())),
          fontWeight: FontWeight.w500,
        ),
        tabIconColor: Colors.grey,
        tabIconSize: 28.0,
        tabIconSelectedSize: 26.0,
        tabSelectedColor: Color(int.parse(primary())),
        tabIconSelectedColor: Colors.white,
        tabBarColor: Colors.white,
        onTabItemSelected: (int value) {
          setState(() {
            _motionTabBarController!.index = value;
          });
        },
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(), // swipe navigation handling is not supported
        // controller: _tabController,
        controller: _motionTabBarController,
        children: const <Widget>[
          StorePage(),
          VoucherPage(),
          ProfilePage()
        ],
      ),
    );
  }
}

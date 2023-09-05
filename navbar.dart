import 'package:bahtra/aclass/kelas_relay.dart';
import 'package:bahtra/admin/lesen.dart';
import 'package:bahtra/admin/setting_home.dart';
import 'package:bahtra/fav/fav_senarai_utama.dart';
import 'package:bahtra/localdb/link_pref.dart';
import 'package:bahtra/db_connector.dart';
import 'package:bahtra/test/contaier_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_grid/grid_home.dart';
import 'home_senarai/senarai_home.dart';
import 'package:bahtra/admin/setting_bizz.dart';
import 'bizz_grid/grid_bizz.dart';
import 'bizz_senarai/senarai_bizz.dart';
import 'package:bahtra/sector/sector.dart';
import 'package:bahtra/sensor_home/daftar_sensor.dart';
import 'package:bahtra/sensor_home/senarai_sensor.dart';
import 'package:bahtra/user/user_baru.dart';
import 'package:bahtra/bizz_fav/bizzfav_utama.dart';
import 'package:bahtra/config/design.dart';
import 'package:bahtra/sensor_bizz/sector_sensor.dart';

class NavBar extends StatefulWidget {

  int muka;
  String xslevel;
  NavBar({this.muka, this.xslevel});
  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {

  @override

  final List<Widget> page = [

    ContainerDesign(),
    SenaraiHome(),
    GridHome(),
    SenaraiFav(),
    LinkPilihan(),
    SettingHome(),
    //SemuaSekaliHome(),

//bizz
//    Senarbahtra(),
//    GridBizz(),
//    //SenaraiSektor(),
//    SenarbahtraFav(),
//    LinkPilihan(),
//    SettingBizz(),
    //SemuaSekaliBizz(),


  ];
////////////////////////////////////////////////////////////////////////////////
  final DBConn db = DBConn();
  String xslevel;

  Future _xsLevel() async{
    xslevel = await db.xsLevel();
  }
////////////////////////////////////////////////////////////////////////////////
//Nak menentukan samada page adalah default atau page by user tab kat button 
//bawah
  int _currentIndex;
  _currentPage() async{
    widget.muka != null ? _currentIndex = widget.muka :  _currentIndex = 0;
  }

////////////////////////////////////////////////////////////////////////////////
  PageController pageController = PageController();
  onTabTapped(int index){
       if(mounted){
          setState(() {
            _currentIndex = index;
          });
       }
  }
///////////////////////////////////////////////////////////////////////////////////////

  @override

  void initState() {
    super.initState();
    _xsLevel();
    _currentPage();
    pageController = PageController(initialPage: _currentIndex);  //change icon state base on index number
  }
////////////////////////////////////////////////////////////////////////////////

  void dispose() {
    print("dispose di panggil");
    super.dispose();
    pageController.dispose();
  }

  Widget build(BuildContext context) {

    final myClass = Provider.of<MyClass>(context, listen: false);

    //kita gunakan PageView 


    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onTabTapped,

        children: [
          SenaraiHome(),
          GridHome(),
          SenaraiFav(),
          LinkPilihan(),
          if(myClass.pangkat == "admin" || widget.xslevel == "admin")
            SettingHome(),
//          Senarbahtra(),
//          GridBizz(),
//         //SenaraiSektor(),
//         SenarbahtraFav(),
//         LinkPilihan(),
//          SettingBizz(),
        ],
      ),




      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index){
          print("index : $index");
          setState(() {
            _currentIndex = index;
          });
          pageController.jumpToPage(_currentIndex);
        },

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            title: Text('List'),

          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.grid_on),
            title: Text('Grid'),
          ),


          BottomNavigationBarItem(
            icon: Icon(Icons.filter_none),
            title: Text('Shortcut'),
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.phonelink_setup),
            title: Text('Link'),
          ),


          if(myClass.pangkat == "admin" || widget.xslevel == "admin")
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              title: Text('setting'),
            ),
        ],
      ),
    );
  }
}

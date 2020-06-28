import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ble/additional.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter BLE Demo',
      home: MyHomePage(title: 'Flutter BLE Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {



  String r="";


  BleManager _bleManager = BleManager(); 
  bool _isScanning= false;               
  List<BleDeviceItem> deviceList = [];   
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  int count=0;
  int limit=0;
  var devices=List();


  @override
  void initState() {
    init(); 
    super.initState();


    var initializationSettingsAndroid = new AndroidInitializationSettings("app_icon");
    var initializationSettingsIos = new IOSInitializationSettings();

    var initializationSettings = new InitializationSettings(initializationSettingsAndroid,initializationSettingsIos);

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,onSelectNotification:onSelectNotification); 

  }

  void init() async {

     
      await _bleManager.createClient(
        restoreStateIdentifier: "example-restore-state-identifier",
        restoreStateAction: (peripherals) {
          peripherals?.forEach((peripheral) {
            print("Restored peripheral: ${peripheral.name}");
          });
        })
        .catchError((e) => print("Couldn't create BLE client  $e"))
        .then((_) => _checkPermissions()) 
        .catchError((e) => print("Permission check error $e"));
        //.then((_) => _waitForBluetoothPoweredOn())        

        scan();


        BluetoothState currentState = await _bleManager.bluetoothState();
        _bleManager.observeBluetoothState().listen((btState) {
         
          if(btState== BluetoothState.POWERED_OFF)
          {
            _bleManager.enableRadio();
          }
          });

  }
  
  _checkPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.contacts.request().isGranted) {    
      }
      
    Map<Permission, PermissionStatus> statuses = await [Permission.location].request();
    if (await Permission.locationWhenInUse.serviceStatus.isDisabled) {
  _showDialog();
}

      print(statuses[Permission.location]);
         
    }
  }

   void _showDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("ALERT"),
          content: new Text(" Please on location "),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
 



  Future onSelectNotification(String payload) {

    debugPrint("payload : $payload");
    showDialog(
      context: context,
      builder: (_) => new AlertDialog(
        title: new Text('Notification'),
        content: new Text('$payload'),
      ),
    );
   
  }

  // ON/OFF 
  void scan() async {
    limit=0;
    
      deviceList.clear();
      print("deviceList1");
      
      _bleManager.startPeripheralScan().listen((scanResult) {          
        var name = scanResult.peripheral.name ?? scanResult.advertisementData.localName ?? "Unknown";
        print(name);
        /*
        print("Scanned Name ${name}, RSSI ${scanResult.rssi}");        
        print("\tidentifier(mac) ${scanResult.peripheral.identifier}"); //mac address
        print("\tservice UUID : ${scanResult.advertisementData.serviceUuids}");        
        print("\tmanufacture Data : ${scanResult.advertisementData.manufacturerData}");        
        print("\tTx Power Level : ${scanResult.advertisementData.txPowerLevel}");
        print("\t${scanResult.peripheral}");
        */ 
        
        var findDevice = deviceList.any((element)    {        
                
          if(element.peripheral.identifier == scanResult.peripheral.identifier) 
          {
            
            element.peripheral = scanResult.peripheral;
            element.advertisementData = scanResult.advertisementData;            
            element.rssi = scanResult.rssi;
            if(element.rssi >-85 && element.rssi <-71)
            {
              if(!devices.contains(element.peripheral))  
              {
                 devices.add(element.peripheral);
                count=count+1;
                
                print(limit);
                if(count<2)
                {
                  limit=limit+1;
                  if(limit<5) 
                  {
                    Future.delayed(const Duration(seconds: 2));
                     showNotification();
                  }
                }  
              }
            }
            return true;            
          }        
          return false;
        });
        
      
        if(!findDevice) {
          count=0;
          deviceList.add(BleDeviceItem(name, scanResult.rssi, scanResult.peripheral, scanResult.advertisementData));
        }
      
        setState((){
          r="";
        });
      });      
      
     // setState(() { _isScanning = true; });
    //}
    // else {      
    //   print("stop");
    //   _bleManager.stopPeripheralScan();      
    //   setState(() { _isScanning = false; });
    // }
  }
  
  
  list() {
    return ListView.builder(
         
      itemCount: deviceList.length, 
      itemBuilder: (context, index) { 
        return ListTile( 
         contentPadding: EdgeInsets.fromLTRB(0.0, 0.0, 20.0, 0.0),
        leading:  Text("--->$r",
        style: TextStyle(
          fontSize: 20,
        ),
        ),
          title: Text(deviceList[index].deviceName,
          style: TextStyle(
            fontSize: 18,
          ),), 
          subtitle: Text(deviceList[index].peripheral.identifier),
          trailing: Text("${deviceList[index].rssi}",
          style: TextStyle(
            fontSize: 18,
          ),),          
        ); 
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("WalkSafe ",
        style: TextStyle(
               color: Colors.white,
             ),),
        backgroundColor: Colors.orangeAccent[700],
        actions: <Widget>[
           FlatButton.icon(
             onPressed: (){
               Navigator.push(context, MaterialPageRoute(
                 builder:(BuildContext context)=>Addition())
                 );
             },
             label: Text("Instructions to follow",
             style: TextStyle(
               color: Colors.white,
               fontSize: 16
             ),),
             icon:Icon( Icons.info,
             color: Colors.white,
             ),
             ),
        ],
      ),
    
      body: deviceList.isEmpty ? Center(child: CircularProgressIndicator()): SafeArea(
              child:Container(
                
                child: list(),
              ),
              
      ),


       floatingActionButton: Container(
        height: 50,
        width: 100,
        
      child:FloatingActionButton.extended(
         backgroundColor:Colors.orangeAccent[700],
         label: Text("Refresh"),
         icon:Icon(Icons.refresh) ,
        onPressed: () async{
          setState(() {
           r="Refreshing..";
          });
          await Future.delayed(Duration(seconds:3));
           scan();
        },

        ),
        
    ),
    );
  }


   Future showNotification() async {
  var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      'your channel id', 'your channel name', 'your channel description',
      sound: RawResourceAndroidNotificationSound('alert'),
      importance: Importance.Max,
      priority: Priority.High);
  var iOSPlatformChannelSpecifics =
      new IOSNotificationDetails(sound: "alert.aiff");
  var platformChannelSpecifics = new NotificationDetails(
      androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    0,
    'WalkSafe app',
    'Requesting to maintain social distance',
    platformChannelSpecifics,
    payload: 'Please maintain the social distance',
  );
    print("result:Notification came ");
}

}


class BleDeviceItem {
    String deviceName;
    Peripheral peripheral;
    int rssi;
    AdvertisementData advertisementData;   
    BleDeviceItem(this.deviceName, this.rssi, this.peripheral, this.advertisementData);


}
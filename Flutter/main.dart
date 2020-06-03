import 'dart:io';
import 'package:aws_iot_device/aws_iot_device.dart';
import 'AWS_details.dart';
import 'package:flutter/material.dart';
import 'dart:async';

main() async {

  AWS_Details aws = new AWS_Details();

  var region = aws.region;

  //These you will get from Cognito
  var accessKey = aws.accessKey;
  var secretAccessKey = aws.secretAccessKey;
  var sessionToken = aws.sessionToken;

  //This is your host. It's probably something like 'abcde191919-ats'
  var host = aws.host;

  //This is the ID of the AWS IoT device
  var deviceId = aws.deviceId;


  var device = AWSIoTDevice(region, accessKey, secretAccessKey, sessionToken, host);

  try {
    await device.connect(deviceId);
  } on Exception catch (e) {
    print('Failed to connect, status is ${device.connectionStatus}');
    exit(-1);
  }

  device.messages.listen((message) {
    print('Received message on topic "${message.item1}", message is "${message.item2}"');
  });

  //The MQTT topic you want to subscribe to
  var topic = aws.topic;

    device.subscribe(topic);
    device.publishMessage(topic, '{"Pump A": "ON"}');

//  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'thingsCortex'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isSwitched = false;
  double temperature = 0.0;
  double flowRate = 0.0;
  double tankLevel = 0.0;
  int _counter = 0;

  onSwitchValueChanged(bool newVal){
    setState(() {
      isSwitched = newVal;
    });
  }

  int ChangePumpStatusColor(){ //Temporary modification. Argument has to be from MQTT
    if(isSwitched == false) {
      temperature = 0.0;
      flowRate = 0.0;
      tankLevel = 0.0;
      return 0xFFF44336;
    }
    else {
      temperature = 42.4;
      flowRate = 10.5;
      tankLevel = 10.0;
      return 0xFF8BC34A;
    }
  }

  String ChangePumpStatusText(){
    if(isSwitched == false) return "Pump OFF";
    else return "Pump ON";
  }

  String getTemperature(){
      return temperature.toString();
  }

  String getFlowRate(){
    return flowRate.toString();
  }

  String getTankLevel(){
    return tankLevel.toString();
  }

//  void publish2AWS_IoT()

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return MaterialApp(
        title: 'Flutter layout demo',
        home: Scaffold( //https://api.flutter.dev/flutter/material/Scaffold-class.html
            appBar: AppBar(
              title: Text('client1',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

            backgroundColor: Colors.blue,

            ),

            body: Container(
              color: Colors.white,
              margin: EdgeInsets.only(top: 20.0),
              child: Column(
                  children: [

                    //Row 01
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            height: 35.0,
                            width: 150.0,
                            color: Colors.blue,
                            margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            alignment: Alignment.center,

                            child: Text('Pump A',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25),
                            )
                        ),

                      ],
                    ),

                    //Row 02
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 10.0, left: 20.0),
                          alignment: Alignment.center,

                          //Row 03
                          child: Row(
                            children: <Widget>[
                              Switch(value: isSwitched, onChanged:(newVal) {
                                onSwitchValueChanged(newVal);//
                              }),

                              Text('Start Pump',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0),
                              ),

                            ],
                          ),

                        ),

                      ],
                    ),

                    //Row 04
                    Row(
                      children: <Widget>[
                         Container(
                          margin: EdgeInsets.only(top: 20.0, left: 20.0),

                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(ChangePumpStatusColor()), //Temporary modification. Argument has to be from MQTT
                              width: 25,
                            ),
                            borderRadius: BorderRadius.circular(25),//
                          ),

                        ),

                        Container(
                          margin: EdgeInsets.only(top: 20.0, left: 10),

                          //Row 05
                          child: Row(
                            children: <Widget>[

                              Text(ChangePumpStatusText(),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),

                    //Row06
                    Row(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 40.0, left: 20.0),

                          //Row 07
                          child: Row(
                            children: <Widget>[
                              Text(
                                  'Motor Temperature (°C)',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold
                                    ),
                              ),

                              Container(
                                margin: EdgeInsets.only(left: 20.0),
                                height: 30.0,
                                width: 80.0,
                                alignment: Alignment.center,

                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                ),

                                child: Text(getTemperature(),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold
                                ),
                                ),

                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    //Row 08
                    Row(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 20.0, left: 20.0),

                          //Row09
                          child: Row(
                            children: <Widget>[
                              Text(
                                'Flow Rate (L/min)',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold
                                ),
                              ),

                              Container(
                                margin: EdgeInsets.only(left: 73.0),
                                height: 30.0,
                                width: 80.0,
                                alignment: Alignment.center,

                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                ),

                                child: Text(getFlowRate(),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),

                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    //Row 10
                    Row(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 20.0, left: 20.0),

                          //Row 11
                          child: Row(
                            children: <Widget>[
                              Text(
                                'Tank Level (%)',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold
                                ),
                              ),

                              Container(
                                margin: EdgeInsets.only(left: 105.0),
                                height: 30.0,
                                width: 80.0,
                                alignment: Alignment.center,

                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                ),

                                child: Text(getTankLevel(),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),

                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    //Row 12
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(top: 40.0),
                          child: Image.asset('assets/images/logo.JPG')
                        ),

                      ],
                    ),

                  ] //children
              ),


            )

        )
    );
  }/*Widget build(BuildContext context)*/
} //class _MyHomePageState extends State<MyHomePage>



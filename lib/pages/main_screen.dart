import 'dart:async';
import 'package:errand_app/global/global.dart';
import 'package:errand_app/infoHandler/app_info.dart';
import 'package:errand_app/pages/search_places_screen.dart';
import 'package:errand_app/pages/search_places_screen2.dart';
import 'package:errand_app/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geocoding/geocoding.dart';
import 'package:errand_app/assistants/assistant_methods.dart';
import 'package:errand_app/global/global_var.dart';
import 'package:flutter/material.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';

import '../authentication/login_screen.dart';
import '../global/map_key.dart';
import '../methods/common_methods.dart';
import '../models/directions.dart';
//import '../models/geo.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}


class _MainScreenState extends State<MainScreen> {

  LatLng? pickLocation;
  loc.Location location = loc.Location();
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState> ();
  String? _address;
  GoogleMapController? controllerGoogleMap;
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomMapPadding = 0;
  

  final Completer<GoogleMapController> _controllerGoogleMaps = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight = 220;
  double waitingResponsefromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;

  //Position? userCurrentPostion;
  //var geolocation = Geolocator();

  //LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;
  List<LatLng> pLineCoordinatedList = [];
  Set<Polyline> polylineset = {};

  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};

  //String userName = "";
  //String userEmail = "";

  bool openNavigationDrawer = true;

  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  bool get darkTheme {
    return true;
  }

  //locateUserPosition() async {
    //Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    //userCurrentPostion = cPosition;

    //LatLng latlngPosition = LatLng(userCurrentPostion!.latitude, userCurrentPostion!.longitude);
    //CameraPosition cameraPosition = CameraPosition(target: latlngPosition, zoom: 15);

    //newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    //String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoOrdinates(userCurrentPostion!, context);
    //print("Address:" + humanReadableAddress);


  //}
  
  

  Future<void> drawPolyLineFromOriginToDestination(bool darkTheme) async {
    var originPosition = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(originPosition!.locationLatitude!, originPosition!.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!, destinationPosition!.locationLongitude!);
    
    showDialog(context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Please wait...",),
    );

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResultList = pPoints.decodePolyline(directionDetailsInfo.e_points!);
    
    pLineCoordinatedList.clear();
    
    if(decodePolyLinePointsResultList.isNotEmpty) {
      decodePolyLinePointsResultList.forEach((PointLatLng pointLatLng){
        pLineCoordinatedList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineset.clear();
    
    setState(() {
      Polyline polyline = Polyline(
        color:  Colors.amber,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinatedList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );

      polylineset.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude > destinationLatLng.longitude){
      boundsLatLng = LatLngBounds(
          southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    }
    else if(originLatLng.latitude > originLatLng.latitude){
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    }
    else {
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }
    
    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));
  }

  //tryna change this
  getAddressFromLatlng() async {
    try {
      GeoData data = await Geocoder2.getDataFromCoordinates(
        latitude: pickLocation!.latitude,
        longitude: pickLocation!.longitude,
        googleMapApiKey: mapKey,
      );
      setState(() {
        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = pickLocation!.latitude;
        userPickUpAddress.locationLongitude = pickLocation!.longitude;
        userPickUpAddress.locationName = data.address;
        //_address = data.address;
        Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
      });
    } catch (e){
      print(e);
    }
  }

  //checkIfLocationPermissionAllowed() async {
    //_locationPermission = await Geolocator.requestPermission();

   // if(_locationPermission == LocationPermission.denied) {
    //  _locationPermission = await Geolocator.requestPermission();
   // }
  //}

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //checkIfLocationPermissionAllowed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        //side drawer
        key: sKey,
        drawer: Container(
          width: 255,
          color: Colors.black87,
          child: Drawer(
            backgroundColor: Colors.white10,
            child: ListView(
              children: [

                //header
                Container(
                  color: Colors.black,
                  height: 160,
                  child: DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    child: Row(
                      children: [

                        const Icon(
                          Icons.person,
                          size: 60,
                        ),


                        const SizedBox(width: 16,),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [


                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10,),

                            const Text(
                              "Profile",
                              style: TextStyle(
                                color: Colors.white24,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(
                  height: 1,
                  color: Colors.white,
                  thickness: 1,
                ),

                const SizedBox(height: 10,),

                //body
                ListTile(
                  leading: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.info, color: Colors.grey,),
                  ),
                  title: const Text("About", style: TextStyle(color: Colors.grey),),
                ),

                GestureDetector(
                  onTap: ()
                  {
                    FirebaseAuth.instance.signOut();
                    Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                  },
                  child: ListTile(
                    leading: IconButton(
                      onPressed: ()
                      {
                        FirebaseAuth.instance.signOut();
                        Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                      },
                      icon: const Icon(Icons.logout, color: Colors.grey,),
                    ),
                    title: const Text("Logout", style: TextStyle(color: Colors.grey),),
                  ),
                ),

              ],
            ),
          ),
        ),


        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              initialCameraPosition: _kGooglePlex,
              markers: markerSet,
              circles: circleSet,
              onMapCreated: (GoogleMapController controller){
                _controllerGoogleMaps.complete(controller);
                newGoogleMapController = controller;

                setState(() {

                });

               // locateUserPosition();
              },
              onCameraMove: (CameraPosition? position){
                if(pickLocation != position!.target){
                  setState(() {
                    pickLocation = position.target;
                  });
                }
              },
              onCameraIdle: (){
                //getAddressFromLatLng();
              },
            ),

            //drawer button
            Positioned(
              top: 50,
              left: 19,
              child: GestureDetector(
                onTap: ()
                {
                  sKey.currentState!.openDrawer();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const
                    [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 20,
                    child: Icon(
                      Icons.menu,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),

            //Align(
              //alignment: Alignment.center,
              //child: Padding(
                //  padding: const EdgeInsets.only(bottom: 35.0),
                  //child: Image.asset("assets/images/ulogo2.png",height: 45,width: 45,),
              //),
            //),

            //UI FOR SEARCHING LOCATION
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color:  Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Padding(padding: EdgeInsets.all(5),
                child: GestureDetector(
                  onTap: () async {
                    //go to search screen
                    var responseFromSearchScreen = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SearchPlacesScreen2()));

                    if(responseFromSearchScreen =="obtainedPickUp"){
                      setState(() {
                        openNavigationDrawer = false;
                      });
                    }

                    //await drawPolyLineFromOriginToDestination(darkTheme);

                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, color: Colors.green,),
                                      SizedBox(width: 10,),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("From",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,

                                          ),
                                          ),
                                          Text(Provider.of<AppInfo>(context).userPickUpLocation != null
                                              ? Provider.of<AppInfo>(context).userPickUpLocation!.locationName!
                                              : "Start Location",
                                            style: TextStyle(color: Colors.grey,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                ),
              ),

                                  SizedBox(height: 5,),
                                  Divider(
                                    height: 1,
                                    thickness: 2,
                                    color: Colors.amber.shade400,
                                  ),

                                  SizedBox(height: 5,),

                                  Padding(
                                    padding: EdgeInsets.all(5),
                                    child: GestureDetector(
                                      onTap: () async {
                                        //go to search screen
                                        var responseFromSearchScreen = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SearchPlacesScreen()));

                                        if(responseFromSearchScreen =="obtainedDropOff"){
                                          setState(() {
                                            openNavigationDrawer = false;
                                          });
                                        }

                                        await drawPolyLineFromOriginToDestination(darkTheme);

                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, color: Colors.red,),
                                          SizedBox(width: 10,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("To",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,

                                                ),
                                              ),
                                              Text(Provider.of<AppInfo>(context).userDropOffLocation != null
                                                  ? Provider.of<AppInfo>(context).userDropOffLocation!.locationName!
                                                  : "Where to?",
                                                style: TextStyle(color: Colors.grey,
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
              ]
                                  ),
                            ),
                          ]
                              ),
                            ),
                          ],
                        ),
                      ),
            ),



            //Positioned(
             // top: 40,
              //right: 20,
              //left: 20,
              //child: Container(
                //decoration: BoxDecoration(
                  //border: Border.all(color: Colors.black),
                  //color: Colors.white,
                //),
                //padding: EdgeInsets.all(20),
                //child: TextField(
                  //decoration: InputDecoration(
                    //hintText: 'Enter Start Location',
                  //),
                  //onChanged: (text) {
                    // Handle the user input here
                    // You can update the userPickUpLocation in AppInfo with the entered location
                  //},
                //),
              //),
            //),
        ]
      ),
    ),

    );
  }
}

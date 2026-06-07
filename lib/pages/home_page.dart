import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:errand_app/authentication/login_screen.dart';
import 'package:errand_app/global/global_var.dart';
import 'package:errand_app/methods/common_methods.dart';
import 'package:errand_app/pages/communications_page.dart';
import 'package:errand_app/pages/profile_page.dart';
import 'package:errand_app/pages/search_destination_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomMapPadding = 0;
  String? profilePicture;
  String userName = ""; // Initialize userName
  XFile? imageFile;
  String urlOfUploadedImage = "";

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/night_style.json").then((value) => setGoogleMapStyle(value, controller));
  }

  Future<void> setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) async {
    if (controller != null) {
      try {
        await controller.setMapStyle(googleMapStyle);
      } catch (e) {
        print("Error setting map style: $e");
      }
    }
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  getUserInfoAndCheckBlockStatus() async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(FirebaseAuth.instance.currentUser!.uid);

    usersRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
          setState(() {
            userName = (snap.snapshot.value as Map)["name"];
            profilePicture = (snap.snapshot.value as Map)['photo'];
          });
        } else {
          signOutUser("Account blocked. Contact admin: davidsithole2023@gmail.com");
        }
      } else {
        signOutUser("User not found.");
      }
    });
  }

  void signOutUser(String message) {
    FirebaseAuth.instance.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (c) => LoginScreen()));
    cMethods.displaySnackBar(message, context);
  }

  Future<void> uploadImageToStorage() async {
    if (imageFile == null) return;

    String imageIDName = DateTime.now().microsecondsSinceEpoch.toString();
    Reference referenceImage = FirebaseStorage.instance.ref().child("images").child(imageIDName);

    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance.ref().child('users/$userId').update({'photo': urlOfUploadedImage});

    setState(() {
      profilePicture = urlOfUploadedImage;
    });
  }

  @override
  void initState() {
    super.initState();
    getUserInfoAndCheckBlockStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.black87,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [
              // Header
              Container(
                color: Colors.black,
                height: 160,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: profilePicture != null
                            ? NetworkImage(profilePicture!)
                            : const AssetImage("assets/images/profile_avatar.png") as ImageProvider,
                      ),
                      const SizedBox(width: 16),
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
                          const SizedBox(height: 10),
                          const Text(
                            "Profile",
                            style: TextStyle(color: Colors.white24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white, thickness: 1),
              const SizedBox(height: 10),
              // Body
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: const Text("Report workers to :errandbuddy@gmail.com", style: TextStyle(color: Colors.grey)),
              ),
              GestureDetector(
                onTap: () {
                  signOutUser("");
                },
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.grey),
                  title: const Text("Logout", style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map on homepage
          GoogleMap(
            padding: const EdgeInsets.only(top: 30, bottom: 120),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);
              setState(() {
                bottomMapPadding = 271;
              });
            },
          ),
          // Drawer button
          Positioned(
            top: 50,
            left: 19,
            child: GestureDetector(
              onTap: () {
                sKey.currentState!.openDrawer();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
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
          // Search location icon button
          Positioned(
            left: 0,
            right: 0,
            bottom: -80,
            child: Container(
              height: searchContainerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => CommunicationsPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(24),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => ProfilePage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(24),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      signOutUser("");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(24),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
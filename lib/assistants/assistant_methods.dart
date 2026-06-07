import 'package:errand_app/assistants/request_assistant.dart';
import 'package:errand_app/models/direction_details_info.dart';
import 'package:errand_app/widgets/place_prediction_tile2.dart';
import 'package:firebase_database/firebase_database.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../global/global.dart';
import '../global/map_key.dart';
import '../infoHandler/app_info.dart';
//import 'pacakage:http/http.dart' as http;
//import 'package:errand_app/global/';

class AssistantMethods {

  static void readCurrentOnlineUserInfo() async {
    currentUser = firebaseAuth.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance.ref()
        .child("users")
        .child(currentUser!.uid);
  }

  //static Future<String> searchAddressForGeographicCoOrdinates(Position position, context) async {

  // String apiUrl = "http://maps.googleapis.com/maps/apis/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
  String apiUrl = "http://maps.googleapis.com/maps/apis/geocode/json?latlng=\${position.latitude},\${position.longitude}&key=\$mapKey";
  String humanReadableAddress = "";

  //var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

  //if(requestResponse != "Error occured. Failed . No Response") {
  // humanReadableAddress = requestResponse["results"][0]["formatted_address"];

  //Directions userPickUpAddress = Directions();
  //userPickUpAddress.locationLatitude = position.latitude;
  //userPickUpAddress.locationLongitude = position.longitude;
  //userPickUpAddress.locationName = humanReadableAddress;

  //Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);


  // }

  //return humanReadableAddress;
  //}

  static Future<DirectionDetailsInfo> obtainOriginToDestinationDirectionDetails(
      LatLng originPosition, LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails = "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition
        .latitude},${originPosition.longitude}&destination=${destinationPosition
        .latitude},${destinationPosition.longitude}&key=$mapKey";
    var responseDirectionApi = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionDetails);

    if (responseDirectionApi == "Error occured. Failed . No Response") {
      //return "";
    }

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.e_points =
    responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    directionDetailsInfo.distance_text =
    responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distance_value =
    responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];

    directionDetailsInfo.duration_text =
    responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.duration_text =
    responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetailsInfo;
  }

  static sendNotificationToWorkerNow(String deviceRegistrationToken,
      String userErrandRequestId, context) async {
    String destinationAddress = userPickUpAddress;

    Map<String, String> headerNotification = {
      'Content-Type': 'application/json',
      'Authorization': cloudMessagingServerToken,
    };

    Map bodyNotification = {
      "body": "Destination Address: \n$destinationAddress.",
      "title": "New Trip Request"
    };

    //Map dataMap = {
    // "click_action":"FLUTTER_NOTIFICATION_CLICK",
    // "id":"1",
    // "status": "done",
    //"rideRequestId":userRideRequestId

    // };
    //Map officialNotificationFormat = {
    //"notofication": bodyNotification,
    //"data": dataMap,
    //"priority": "high",
    //"to": deviceRegistrationToken,
    //}
    //var responseNotification=http.post(

    //Uri.parse("https://fcm.googleleapis.com/fcm/send"),
    //hearders:  headerNotification,
    //  body: jsonEncode(official)

    //);
    //}
  }
  }
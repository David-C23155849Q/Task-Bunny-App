import 'package:errand_app/assistants/request_assistant.dart';
import 'package:errand_app/global/map_key.dart';
import 'package:errand_app/models/directions.dart';
import 'package:errand_app/models/predicted_places.dart';
import 'package:errand_app/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../global/global.dart';
import '../infoHandler/app_info.dart';

class PlacePredictionTileDesign2 extends StatefulWidget {


  final PredictedPlaces? predictedPlaces;


  PlacePredictionTileDesign2({this.predictedPlaces});

  @override
  State<PlacePredictionTileDesign2> createState() => _PlacePredictionTileDesign2State();
}

String userPickUpAddress ="";
class _PlacePredictionTileDesign2State extends State<PlacePredictionTileDesign2> {

  getPlaceDirectionDetails(String? placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
          message: "Setting PickUp",
        )
    );

    String placeDirectionDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var responseApi = await RequestAssistant.receiveRequest(placeDirectionDetailsUrl);

    Navigator.pop(context);

    if(responseApi == "Error occured. Failed . No Response"){
      return;
    }
    if(responseApi["status"] == "OK"){
      Directions directions = Directions();
      directions.locationName = responseApi["result"]["name"];
      directions.locationId = placeId;
      directions.locationLatitude = responseApi["result"]["geometry"]["location"]["lat"];
      directions.locationLongitude = responseApi["result"]["geometry"]["location"]["lat"];

      Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(directions);

      setState(() {
        userPickUpAddress = directions.locationName!;
      });

      Navigator.pop(context, "obtainedPickUp");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: ()
      {
        getPlaceDirectionDetails(widget.predictedPlaces!.place_id, context);
      },
      // style: ElevatedButton.styleFrom(
      //   primary: Colors.black,
      // ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.add_location,
              color: Colors.red,
            ),

            SizedBox(width: 10,),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.predictedPlaces!.main_text!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    widget.predictedPlaces!.secondary_text!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

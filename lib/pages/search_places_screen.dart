import 'package:errand_app/assistants/request_assistant.dart';
import 'package:errand_app/global/map_key.dart';
import 'package:errand_app/models/predicted_places.dart';
import 'package:errand_app/widgets/place_prediction_tile.dart';
import 'package:flutter/material.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {

  List<PredictedPlaces> placesPredictedList = [];
  findPlaceAutoCompleteSearch(String inputText) async {
    if(inputText.length > 1){
      //String urlAutoCompleteSearch = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$inputText&key=$mapKey&components=country:BD";
      String urlAutoCompleteSearch = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$inputText&key=$mapKey";

      var responseAutoCompleteSearch = await RequestAssistant.receiveRequest(urlAutoCompleteSearch);

      if(responseAutoCompleteSearch == "Error occured. Failed . No Response"){
        return;
      }

      if(responseAutoCompleteSearch["status"] == "OK"){
        var placePredictions = responseAutoCompleteSearch["predictions"];

        var placePredictionsList = (placePredictions as List).map((jsonData) => PredictedPlaces.fromJson(jsonData)).toList();

        setState(() {
          placesPredictedList = placePredictionsList;
        });
      }
    }

  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.grey,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade800,
          leading: GestureDetector(
            onTap: (){
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back,
              color: Colors.black,),
          ),
          title: Text("Search and set drop location",
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Colors.grey,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 8,
                      spreadRadius: 0.5,
                      offset: Offset(
                        0.7,
                        0.7,
                      ),
                    ),
                  ]
              ),

              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                    children: [
                      Row(
                          children: [
                            Icon(Icons.adjust_sharp,
                              color: Colors.black ,),

                            SizedBox(height: 18,),

                            Expanded(
                              child:
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: TextField(
                                  onChanged: (value)
                                  {
                                    findPlaceAutoCompleteSearch(value);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Search location here",
                                    fillColor: Colors.black,
                                    filled: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.only(
                                      left: 11,
                                      top: 8,
                                      bottom: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ]
                      ),
                    ]
                ),
              ),
            ),

            //display place predictionsresult
            (placesPredictedList.length > 0)
                ? Expanded(
              child: ListView.separated(
                  itemCount: placesPredictedList.length,
                  physics: ClampingScrollPhysics(),
                  itemBuilder: (context, index){
                    return PlacePredictionTileDesign(
                      predictedPlaces: placesPredictedList[index],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider(
                      height: 0,
                      color: Colors.green,
                      thickness: 0,
                    );
                  }
              ),
            ) : Container(),

          ],
        ),
      ),
    );

  }
}
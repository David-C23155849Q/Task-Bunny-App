import 'dart:convert';

import 'package:http/http.dart' as http;

class RequestAssistant{

  static Future<dynamic> receiveRequest(String url) async {
    http.Response httpResponse = await http.get(Uri.parse(url));

    try {
      if (httpResponse.statusCode == 200) //successful
          {
        String responseDate = httpResponse.body; //json
        var decodeResponseData = jsonDecode(responseDate);

        return decodeResponseData;
      }
      else {
        return "Error occured. Failed . No Response";
      }
    }catch(exp){
      return "Error occured. Failed . No Response";
    }
    }
  }
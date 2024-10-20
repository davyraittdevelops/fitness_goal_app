import 'package:http/http.dart' as http;
import 'dart:convert';

class GarminDataService {
  Future<double> fetchKmForMonth(String monthYear) async {
    var url = Uri.parse(
        'https://pcfimc69k0.execute-api.eu-central-1.amazonaws.com/prod/personalgarmindata?range=$monthYear');
    var response = await http.get(url, headers: {
      'x-api-key': '7usUQOdL8u5FmrSJmmRG64hPqduldre64mmhXWEx',
    });

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['totalKm'];
    } else {
      throw Exception('Failed to load data for $monthYear');
    }
  }
}

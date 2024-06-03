public class SolarForecastService {
    private static final String ENDPOINT = 'https://api.solar-forecast.org/forecast';

    public static HttpResponse getForecast(String latitude, String longitude, String installedPower) {
        // Create the request body as JSON
        Map<String, Object> location = new Map<String, Object>();
        location.put('latitude', latitude);
        location.put('longitude', longitude);

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('location', location);
        requestBody.put('installedPower', installedPower);
        
        // Convert the request body to JSON string
        String body = JSON.serialize(requestBody);
        
        // Create a new HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);

        System.debug('Request Body: ' + body);

        // Send the request
        Http http = new Http();
        HttpResponse res = null;
        try {
            res = http.send(req);
            System.debug('Response Status: ' + res.getStatus());
            System.debug('Response Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
        } catch (System.CalloutException e) {
            System.debug('Error: ' + e.getMessage());
        }

        // Return the response
        return res;
    }

    // Method to filter data for the current date and calculate averages
    public static Map<String, String> calculateCurrentDateAverages(HttpResponse res) {
        if (res == null || res.getStatusCode() != 200) {
            System.debug('Invalid response or no data received.');
            return null;
        }

        // Parse the response body
        List<Object> responseBody = (List<Object>) JSON.deserializeUntyped(res.getBody());
        System.debug('Response Body Parsed: ' + responseBody);

        // Get the current date in UTC
        Date currentDate = Date.today();
        System.debug('Current Date: ' + currentDate);
        
        // Filter the data for the current date
        List<Map<String, Object>> filteredData = new List<Map<String, Object>>();
        for (Object entryObj : responseBody) {
            Map<String, Object> entry = (Map<String, Object>) entryObj;
            Long timestamp = Long.valueOf(entry.get('dt').toString());
            Date entryDate = DateTime.newInstance(timestamp * 1000).date();
            if (entryDate == currentDate) {
                filteredData.add(entry);
            }
        }

        System.debug('Filtered Data: ' + filteredData);

        // Calculate averages
        if (filteredData.isEmpty()) {
            System.debug('No data available for the current date.');
            return null;
        }

        Double totalTemp = 0.0;
        Double totalClearSky = 0.0;
        Double totalPPredicted = 0.0;
        Double totalPressure = 0.0;
        Double totalHumidity = 0.0;
        Double totalWindSpeed = 0.0;
        Double totalCloudsAll = 0.0;
        
        for (Map<String, Object> entry : filteredData) {
            totalTemp += Double.valueOf(entry.get('temp').toString());
            totalClearSky += Double.valueOf(entry.get('clear_sky').toString());
            totalPPredicted += Double.valueOf(entry.get('P_predicted').toString());
            totalPressure += Double.valueOf(entry.get('pressure').toString());
            totalHumidity += Double.valueOf(entry.get('humidity').toString());
            totalWindSpeed += Double.valueOf(entry.get('wind_speed').toString());
            totalCloudsAll += Double.valueOf(entry.get('clouds_all').toString());
        }

        Integer dataSize = filteredData.size();
        Map<String, String> averages = new Map<String, String>();
        averages.put('avg_temp', String.valueOf(totalTemp / dataSize));
        averages.put('avg_clear_sky', String.valueOf(totalClearSky / dataSize));
        averages.put('avg_p_predicted', String.valueOf(totalPPredicted / dataSize));
        averages.put('avg_pressure', String.valueOf(totalPressure / dataSize));
        averages.put('avg_humidity', String.valueOf(totalHumidity / dataSize));
        averages.put('avg_wind_speed', String.valueOf(totalWindSpeed / dataSize));
        averages.put('avg_clouds_all', String.valueOf(totalCloudsAll / dataSize));
        System.debug('Averages: ' + averages);

        return averages;
    }
}

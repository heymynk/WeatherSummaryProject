public with sharing class WeatherSummaryHandler {

    @AuraEnabled(cacheable=true)
    public static String placesAndWeatherSummary(Id leadId) {
        // Call fetchLeadAddressByCoordinates to get the coordinates
        CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);

        // Check if coordinates are available
        if (coordinates != null) {
            String latitude = coordinates.latitude;
            String longitude = coordinates.longitude;

            System.debug('latitude' + latitude);
            System.debug('longitude' + longitude);

            // Call fetchNearByPlaces to get nearby places
            List<String> nearbyPlaces = fetchNearByPlaces(
                '5000',
                new List<String>{ 'commercial' },
                longitude,
                latitude
            );

            // Call fetchWeatherData to get weather data
            OpenMeteoWrapper weatherData = fetchWeatherData(longitude, latitude);

            // // Call getCompanyData to get company information
            // CompanyInfoWrapper companyData = getCompanyData(leadId);
            // String companyInfoString = companyData != null
            //     ? companyData.summary
            //     : 'No company information available';

            // System.debug('companyInfoString' + companyInfoString);

            // Call SolarForecastService to get forecast data and calculate averages
            HttpResponse forecastResponse = SolarForecastService.getForecast(
                latitude,
                longitude,
                '10'
            ); // assuming installedPower as 10
            Map<String, String> weatherAverages = SolarForecastService.calculateCurrentDateAverages(
                forecastResponse
            );

            // Process the weather data response
            if (weatherData != null) {
                String processedResponse = processResponse(weatherData);

                // Construct the prompt
                String prompt =
                    'Nearby Places: ' +
                    String.join(nearbyPlaces, ', ') +
                    '.\n\nWeather Summary:\n' +
                    processedResponse +
                    // '\n\nCompany Information:\n' +
                    // companyInfoString +
                    '\n\nWeather Averages:\n' +
                    formatAverages(weatherAverages) +
                    '\n\nGiven the current weather conditions, nearby venues, and company information, ' +
                    'please suggest the ideal place and time to meet the Lead customer. ' +
                    'Considering the company profile, industry, specialty, revenue, and related figures, ' +
                    'recommend the most suitable product for the location, including specific facts, figures, and numbers from the data provided. ' +
                    'If the given product is not suitable, provide alternate product options with justifications, also incorporating specific facts and figures from the provided data.';

                System.debug('prompt' + prompt);

                // Get OpenAI response
                String openAiResponse = getOpenAiResponse(prompt);
                if (openAiResponse != null) {
                    // Store the response summary
                    storeResponseSummary(leadId, openAiResponse);
                    // Return the response summary
                    return openAiResponse;
                } else {
                    return 'Failed to retrieve OpenAI response.';
                }
            } else {
                return 'Failed to retrieve weather data or company information.';
            }
        } else {
            return 'Failed to retrieve coordinates for Lead with Id: ' + leadId;
        }
    }

    // Method to format averages into a string
    private static String formatAverages(Map<String, String> averages) {
        return 'Average Temperature: ' +
            averages.get('avg_temp') +
            ' °C\n' +
            'Average Clear Sky: ' +
            averages.get('avg_clear_sky') +
            ' %\n' +
            'Average Predicted Power: ' +
            averages.get('avg_p_predicted') +
            ' kW\n' +
            'Average Pressure: ' +
            averages.get('avg_pressure') +
            ' hPa\n' +
            'Average Humidity: ' +
            averages.get('avg_humidity') +
            ' %\n' +
            'Average Wind Speed: ' +
            averages.get('avg_wind_speed') +
            ' m/s\n' +
            'Average Cloud Cover: ' +
            averages.get('avg_clouds_all') +
            ' %';
    }

    @AuraEnabled(cacheable=true)
    public static CompanyInfoWrapper getCompanyData(Id leadId) {
        String companyInfoApiKey = getcompanyInfoAPIKey();

        Lead lead = [SELECT Company FROM Lead WHERE Id = :leadId LIMIT 1];
        String companyName = lead.Company;

        if (companyName == null) {
            System.debug('No company name found for the given Lead Id: ' + leadId);
            return null;
        }

        CompanyInfoWrapper companyData = null;

        String endpoint =
            'https://api.peopledatalabs.com/v5/company/enrich?name=' +
            EncodingUtil.urlEncode(companyName, 'UTF-8') +
            '&pretty=false';
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('accept', 'application/json');
        request.setHeader('X-API-Key', companyInfoApiKey);

        try {
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                String responseBody = response.getBody();
                System.debug('Response: ' + responseBody);

                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
                    responseBody
                );
                String displayName = (String) responseMap.get('display_name');
                String summary = (String) responseMap.get('summary');

                companyData = new CompanyInfoWrapper(displayName, summary);

                return companyData;
            } else {
                System.debug('Failed with status code: ' + response.getStatusCode());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return null;
        }
    }

    private static String getcompanyInfoAPIKey() {
        ApiKeys__c companyInfoKeySettings = ApiKeys__c.getInstance('companyInfo');
        return companyInfoKeySettings != null
            ? companyInfoKeySettings.Value__c
            : null;
    }

    @RemoteAction
    public static String getWeatherDataJSON(Id leadId) {
        // Call methods to fetch and process weather data
        CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
        System.debug('coordinates' + coordinates);
        // Check if coordinates are available
        if (coordinates != null) {
            String latitude = coordinates.latitude;
            String longitude = coordinates.longitude;

            // Call method to fetch weather data
            OpenMeteoWrapper weatherData = fetchWeatherData(longitude, latitude);
            System.debug('weatherData' + weatherData);

            // Process the response and convert to JSON
            if (weatherData != null) {
                String processedResponse = processResponse(weatherData);
                System.debug('processedResponse' + processedResponse);

                return processedResponse;
            } else {
                return 'Failed to retrieve weather data.';
            }
        } else {
            return 'Failed to retrieve coordinates for Lead with Id: ' + leadId;
        }
    }

    private static CoordinatesWrapper fetchLeadAddressByCoordinates(Id leadId) {
        CoordinatesWrapper coordinates = null;
        String errorMessage = '';

        Lead lead = [
            SELECT Street, City, State, PostalCode, Country
            FROM Lead
            WHERE Id = :leadId
            WITH SECURITY_ENFORCED
        ];

        if (lead != null) {
            // Construct the address string
            String address = '';
            address += lead.Street != null ? lead.Street + ',' : '';
            address += lead.City != null ? lead.City + ',' : '';
            address += lead.State != null ? lead.State + ',' : '';
            address += lead.PostalCode != null ? lead.PostalCode + ',' : '';
            address += lead.Country != null ? lead.Country : '';

            // Remove the trailing comma if present
            address = address.endsWith(',') ? address.removeEnd(',') : address;

            // Construct the API endpoint with the address
            String geoapifyAPIKey = getGeoapifyAPIKey();
            String endPoint =
                'https://api.geoapify.com/v1/geocode/search?text=' +
                EncodingUtil.urlEncode(address, 'UTF-8') +
                '&apiKey=' +
                geoapifyAPIKey;

            try {
                HttpResponse response = HttpHelper.sendGetRequest(endPoint);

                if (response != null && response.getStatusCode() == 200) {
                    // Parse JSON response
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(
                        response.getBody()
                    );
                    List<Object> features = (List<Object>) parsedResponse.get('features');

                    if (!features.isEmpty()) {
                        Map<String, Object> firstFeature = (Map<String, Object>) features[0];
                        Map<String, Object> geometry = (Map<String, Object>) firstFeature.get(
                            'geometry'
                        );

                        if (geometry != null) {
                            List<Object> coordinatesList = (List<Object>) geometry.get(
                                'coordinates'
                            );

                            if (coordinatesList != null && coordinatesList.size() >= 2) {
                                String latitude = String.valueOf(coordinatesList[1]);
                                String longitude = String.valueOf(coordinatesList[0]);
                                coordinates = new CoordinatesWrapper(latitude, longitude);
                            }
                        }
                    }
                } else {
                    errorMessage =
                        'Error while communicating with Geoapify Data API. Status: ' +
                        response.getStatus() +
                        ' Status code: ' +
                        response.getStatusCode();
                }
            } catch (System.CalloutException e) {
                errorMessage =
                    'Error while communicating with Geoapify Data API: ' + e.getMessage();
            }
        } else {
            System.debug('No lead record found with the provided Id: ' + leadId);
        }

        if (!String.isEmpty(errorMessage)) {
            System.debug(errorMessage);
        }

        return coordinates;
    }

    private static List<String> fetchNearByPlaces(
        String radius,
        List<String> categories,
        String longitude,
        String latitude
    ) {
        List<String> nearbyPlaces = new List<String>();
        String errorMessage = '';
        String geoapifyAPIKey = getGeoapifyAPIKey();
        // Construct the API endpoint for nearby places
        String endPoint =
            'https://api.geoapify.com/v2/places?categories=' +
            String.join(categories, ',') +
            '&limit=10&filter=circle:' +
            longitude +
            ',' +
            latitude +
            ',' +
            radius +
            '&apiKey=' +
            geoapifyAPIKey;

        try {
            HttpResponse response = HttpHelper.sendGetRequest(endPoint);

            if (response != null && response.getStatusCode() == 200) {
                String responseBody = response.getBody();

                // Parse JSON response to extract nearby places
                Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(
                    responseBody
                );
                List<Object> places = (List<Object>) parsedResponse.get('features');

                // Extract place names
                for (Object place : places) {
                    Map<String, Object> placeMap = (Map<String, Object>) place;
                    Map<String, Object> properties = (Map<String, Object>) placeMap.get(
                        'properties'
                    );
                    String placeName = (String) properties.get('name');
                    nearbyPlaces.add(placeName);
                }
            } else {
                errorMessage =
                    'Error while communicating with Geoapify Data API. Status: ' +
                    response.getStatus() +
                    ' Status code: ' +
                    response.getStatusCode();
                System.debug('Error: ' + errorMessage);
            }
        } catch (System.Exception e) {
            if (String.valueOf(e.getMessage()).startsWith('Unauthorized endpoint')) {
                errorMessage =
                    'Unauthorized endpoint: An administrator must go to Setup -> Administrator -> Security Control -> Remote Site Settings and add ' +
                    endPoint +
                    ' as an endpoint';
            } else {
                errorMessage =
                    'Error while communicating with Geoapify Data API: ' + e.getMessage();
            }
            System.debug('Exception Executed: ' + errorMessage);
        }

        if (!String.isEmpty(errorMessage)) {
            System.debug(errorMessage);
        }

        return nearbyPlaces;
    }

    private static OpenMeteoWrapper fetchWeatherData(
        String longitude,
        String latitude
    ) {
        String endPoint = System.Label.OpenMeteo;
        String errorMessage = '';
        OpenMeteoWrapper obj = new OpenMeteoWrapper();

        // Parameters for the API request
        Map<String, String> params = new Map<String, String>{
            'longitude' => longitude,
            'latitude' => latitude,
            'hourly' => 'temperature_2m,relative_humidity_2m,dew_point_2m,precipitation_probability,rain,showers,snowfall,wind_speed_10m,wind_direction_10m',
            'forecast_days' => '16'
        };

        // Build the query string
        String queryString = '';
        for (String key : params.keySet()) {
            queryString +=
                key +
                '=' +
                EncodingUtil.urlEncode(params.get(key), 'UTF-8') +
                '&';
        }
        queryString = queryString.subString(0, queryString.length() - 1);

        String finalEndPoint = endPoint + '?' + queryString;

        try {
            HttpResponse response = HttpHelper.sendGetRequest(finalEndPoint);

            if (response != null && response.getStatusCode() == 200) {
                String body = response.getBody();
                // Deserialize the JSON response into OpenMeteoWrapper object
                obj = (OpenMeteoWrapper) JSON.deserialize(
                    body.replace('"time":', '"timestamps":'),
                    OpenMeteoWrapper.class
                );
                return obj;
            } else {
                errorMessage =
                    'Error while communicating with OpenMeteo API. Status: ' +
                    response.getStatus() +
                    ' Status code: ' +
                    response.getStatusCode();
                System.debug(errorMessage);
            }
        } catch (System.Exception e) {
            errorMessage = 'Exception occurred: ' + e.getMessage();
            System.debug('Exception Executed: ' + errorMessage);
        }

        return null;
    }

    private static String processResponse(OpenMeteoWrapper wrapper) {
        OpenMeteoWrapper.Hourly hourlyData = wrapper.hourly;
        if (hourlyData != null) {
            List<String> lines = new List<String>();
            lines.add(
                'Time, Temperature (°C), Relative Humidity (%), Rain (mm), Showers (mm), Snowfall (cm)'
            );

            Date currentDate = Date.today();

            if (
                hourlyData.timestamps != null &&
                hourlyData.temperature_2m != null &&
                hourlyData.relative_humidity_2m != null &&
                hourlyData.rain != null &&
                hourlyData.showers != null &&
                hourlyData.snowfall != null
            ) {
                for (Integer i = 0; i < hourlyData.timestamps.size(); i++) {
                    String timestampStr = hourlyData.timestamps[i];
                    List<String> timestampComponents = timestampStr.split('T');
                    if (timestampComponents.size() != 2) {
                        continue;
                    }

                    DateTime timestamp;
                    try {
                        String dateStr = timestampComponents[0];
                        String timeStr = timestampComponents[1];
                        Integer year = Integer.valueOf(dateStr.substring(0, 4));
                        Integer month = Integer.valueOf(dateStr.substring(5, 7));
                        Integer day = Integer.valueOf(dateStr.substring(8, 10));
                        Integer hour = Integer.valueOf(timeStr.substring(0, 2));
                        Integer minute = Integer.valueOf(timeStr.substring(3, 5));
                        timestamp = DateTime.newInstance(year, month, day, hour, minute, 0);
                    } catch (Exception e) {
                        continue;
                    }

                    if (timestamp.date() == currentDate) {
                        if (
                            i < hourlyData.temperature_2m.size() &&
                            i < hourlyData.relative_humidity_2m.size() &&
                            i < hourlyData.rain.size() &&
                            i < hourlyData.showers.size() &&
                            i < hourlyData.snowfall.size()
                        ) {
                            String line =
                                timestampStr +
                                ',' +
                                hourlyData.temperature_2m[i] +
                                ',' +
                                hourlyData.relative_humidity_2m[i] +
                                ',' +
                                hourlyData.rain[i] +
                                ',' +
                                hourlyData.showers[i] +
                                ',' +
                                hourlyData.snowfall[i];
                            lines.add(line);
                        }
                    }
                }
            }

            String csvContent = String.join(lines, '\n');
            return csvContent;
        } else {
            return null;
        }
    }

    //private static final String OPENAI_API_KEY = getOpenAIKey();
    private static String getOpenAiResponse(String prompt) {
        String openAiKey = getOpenAIKey();

        String endPoint = 'https://api.openai.com/v1/chat/completions';
        Map<String, Object> requestMap = new Map<String, Object>{
            'messages' => new List<Object>{
                new Map<String, String>{ 'content' => prompt, 'role' => 'user' }
            },
            'model' => 'gpt-3.5-turbo'
        };
        String requestJson = JSON.serialize(requestMap);

        HttpResponse res = HttpHelper.sendPostRequest(
            endPoint,
            requestJson,
            openAiKey
        );

        if (res != null && res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
                res.getBody()
            );
            List<Object> choices = (List<Object>) responseMap.get('choices');
            Map<String, Object> choice = (Map<String, Object>) choices[0];
            Map<String, Object> message = (Map<String, Object>) choice.get('message');
            String summary = (String) message.get('content');
            return summary;
        } else {
            System.debug('Error response: ' + JSON.deserializeUntyped(res.getBody()));
            return null;
        }
    }

    @future
    private static void storeResponseSummary(Id leadId, String summaryText) {
        // Create a new ResponseSummary__c record
        ResponseSummary__c summary = new ResponseSummary__c();
        summary.Lead__c = leadId;
        summary.Summary__c = summaryText;

        try {
            // Insert the new record using Database.insert
            Database.SaveResult[] srList = Database.insert(
                new List<ResponseSummary__c>{ summary },
                false
            );
            if (srList[0].isSuccess()) {
                System.debug('Summary record inserted successfully.');
            } else {
                for (Database.Error err : srList[0].getErrors()) {
                    System.debug('Error message: ' + err.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Error while storing response summary: ' + e.getMessage());
        }
    }

    private static String getGeoapifyAPIKey() {
        ApiKeys__c geoKeySettings = ApiKeys__c.getInstance('Geoapify');
        return geoKeySettings != null ? geoKeySettings.Value__c : null;
    }

    private static String getOpenAIKey() {
        ApiKeys__c openKeySettings = ApiKeys__c.getInstance('OpenAi');
        return openKeySettings != null ? openKeySettings.Value__c : null;
    }
}

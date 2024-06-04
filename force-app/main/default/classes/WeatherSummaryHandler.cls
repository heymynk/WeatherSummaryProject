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

            // Call getCompanyData to get company information
            CompanyInfoWrapper companyData = getCompanyData(leadId);
            String companyInfoString = companyData != null
                ? companyData.summary
                : 'No company information available';

            System.debug('companyInfoString' + companyInfoString);

            // Call SolarForecastService to get forecast data and calculate averages
            HttpResponse forecastResponse = SolarForecastService.getForecast(
                latitude,
                longitude,
                '10'
            ); // assuming installedPower as 10
            Map<String, String> weatherAverages = SolarForecastService.calculateCurrentDateAverages(
                forecastResponse
            );

            List<Solar_Panel__c> solarPanelData = getSolarPanelData();
            String solarPanelDataString = '';
            for (Solar_Panel__c panel : solarPanelData) {
                solarPanelDataString += 'Panel Name: ' + panel.Name + ', Description: ' + panel.Description__c + '\n';
            }

            // Process the weather data response
            if (weatherAverages != null && companyData != null && solarPanelDataString != null) {
                // Construct the prompt
                String prompt =

                '.\n\nWeather Data:\n' +
                formatAverages(weatherAverages) +
                '\n\nSolar Panel Data:\n' +
                solarPanelDataString +
                '\n\nCompany Information:\n' +
                companyInfoString +
                '\n\nGiven the current weather conditions, nearby venues, and company information, ' +
                'please suggest the ideal place and time to meet the Lead customer. ' +
                'Considering the company profile, industry, specialty, revenue, and related figures, ' +
                'recommend the most suitable product for the location and also compare the given products and tell which will be the best, including specific facts, figures, and numbers from the data provided. ' +
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

    // Function to fetch the data from Solar_Panel__c object
    public static List<Solar_Panel__c> getSolarPanelData() {
        List<Solar_Panel__c> solarPanelData = [SELECT Id, Name, Description__c FROM Solar_Panel__c LIMIT 2];
        System.debug('solarPanelData' + solarPanelData);
        return solarPanelData;
    }

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

    //Create the function to fetch the leadds from the Lead object
    @AuraEnabled(cacheable=true)
    public static List<Lead> fetchLeads() {
        List<Lead> leads = [SELECT Id, Name, Company FROM Lead];
        return leads;
    }

    @AuraEnabled(cacheable=true)
    public static Lead fetchLeadById(Id leadId) {
        return [SELECT Id, Name, Company, Email, Phone FROM Lead WHERE Id = :leadId LIMIT 1];
    }

    @AuraEnabled
    public static void sendEmail(Id leadId, String formUrl) {
        // Lead lead = [SELECT Name, Email FROM Lead WHERE Id = :leadId LIMIT 1];
        // if (lead != null) {
        //     Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        //     email.setToAddresses(new String[] { lead.Email });
        //     email.setSubject('Harness the Power of the Sun with ESolarCorp Pvt Ltd');
        //     email.setPlainTextBody('Dear ' + lead.Name + ',\n\n' +
        //         'We hope this email finds you well. At ESolarCorp Pvt Ltd, we specialize in providing high-quality solar power solutions to help homeowners like you save on energy costs and contribute to a greener planet.\n\n' +
        //         'To get started, we would love to gather some basic information about your property. Please take a moment to fill out the short form linked below:\n\n' +
        //         formUrl + '\n\n' +
        //         'Thank you for your interest in solar power. We look forward to helping you make the switch!\n\n' +
        //         'Best regards,\n' +
        //         'Mayank Singh\n' +
        //         'Sales And MA Head\n' +
        //         '[Your Company Name]\n' +
        //         '[Contact Information]');
        //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        // }
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

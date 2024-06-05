public with sharing class LeadInteractionHandler {

    @AuraEnabled(cacheable=true)
    public static String getLeadAddress(Id leadId) {
        Lead lead = [SELECT Name, Street, City, State, PostalCode, Country FROM Lead WHERE Id = :leadId LIMIT 1];
        if (lead != null) {
            return lead.Street + ', ' + lead.City + ', ' + lead.State + ', ' + lead.PostalCode + ', ' + lead.Country+ ', ' + lead.Name;
        } else {
            return 'Address not available';
        }
    }


    @AuraEnabled(cacheable=true)
    public static String generateEmailContent(Id leadId, String customPromptByUser) {
        // Basic email structure with placeholders for dynamic content
        List<String> emailPromptParts = new List<String>{
            'Note- Purpose of email is to grab the attention of lead to grow our business by giving our services to lead',
            'Using the provided company information of lead, weather data of lead, and Lead\'s address (city only) and Name, write a personalized, formatted email for the lead\'s first interaction. Grab the attention of the lead using the lead\'s company information.',
            'The email should be engaging, give a short introduction of ESolarCorp, our company, and include only the necessary information.',
            'Ensure the Email is clear, professional, and includes necessary information to make a strong case for choosing ESolarCorp.',
            'The goal is to make a great first impression and clearly convey our value proposition. Ensure the email is neat, clean, and professionally formatted.',
            'There is also a prompt which is given by the user from the UI, Consider that prompt as well.'
        };

        // Include custom prompt provided by the user if it's not empty
        if (!String.isBlank(customPromptByUser)) {
            emailPromptParts.add(customPromptByUser);  // Add custom user input to the email content
        }

        String leadAddress = getLeadAddress(leadId);
        CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
        if (coordinates != null) {
            String latitude = coordinates.latitude;
            String longitude = coordinates.longitude;

            CompanyInfoWrapper companyData = getCompanyData(leadId);
            String companyInfoString = companyData != null ? companyData.summary : 'No company information available';
            System.debug('Company Info: ' + companyInfoString);

            HttpResponse forecastResponse = SolarForecastService.getForecast(latitude, longitude, '10');
            Map<String, String> weatherAverages = SolarForecastService.calculateCurrentDateAverages(forecastResponse);

            if (weatherAverages != null && companyData != null) {
                // Append additional contextual data to the prompt
                emailPromptParts.add('Lead\'s Address: ' + leadAddress);
                String customPrompt = String.join(emailPromptParts, '\n');
                String prompt = customPrompt + '\n\nWeather Data:\n' + formatAverages(weatherAverages) +
                                '\n\nCompany Information:\n' + companyInfoString;

                String role = 'assistant';  // Define the role for OpenAI response generation
                String openAiResponse = getOpenAiResponse(prompt, role);
                if (openAiResponse != null) {
                    storeResponseSummary(leadId, openAiResponse);
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


    @AuraEnabled(cacheable=true)
    public static String generateCallScript(Id leadId, String customPromptByUser) {
        List<String> callPromptParts = new List<String>{
            'Using the provided company information of lead, weather data of lead\'s address, and solar panel product details our company offers, generate a scripted first phone call for the lead (Do not include lead response).',
            'The script should be engaging, starting with an introduction of ESolarCorp, our company, followed by a discussion on how our solar panel products can benefit the lead considering the current weather conditions.',
            'Include key points about the advantages of our products and tailor the conversation to address the lead\'s specific needs.',
            'Ensure the script is clear, professional, and includes necessary information to make a strong case for choosing ESolarCorp.',
            'There is also a prompt which is given by the user from the UI, Consider that prompt as well.'

        };

                // Include custom prompt provided by the user if it's not empty
                if (!String.isBlank(customPromptByUser)) {
                    callPromptParts.add(customPromptByUser);  // Add custom user input to the email content
                }


        String leadAddress = getLeadAddress(leadId);
        CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
        if (coordinates != null) {
            String latitude = coordinates.latitude;
            String longitude = coordinates.longitude;

            CompanyInfoWrapper companyData = getCompanyData(leadId);
            String companyInfoString = companyData != null ? companyData.summary : 'No company information available';

            HttpResponse forecastResponse = SolarForecastService.getForecast(latitude, longitude, '10');
            Map<String, String> weatherAverages = SolarForecastService.calculateCurrentDateAverages(forecastResponse);

            List<Solar_Panel__c> solarPanelData = getSolarPanelData();
            String solarPanelDataString = '';
            for (Solar_Panel__c panel : solarPanelData) {
                solarPanelDataString += 'Panel Name: ' + panel.Name + ', Description: ' + panel.Description__c + '\n';
            }

            if (weatherAverages != null && companyData != null && solarPanelDataString != null) {
                // Add the lead's address to the custom prompt parts
                callPromptParts.add('Lead\'s Address: ' + leadAddress);
                // Join the custom prompt parts into a single string
                String customPrompt = String.join(callPromptParts, '\n');

                String prompt = customPrompt + '\n\nWeather Data:\n' + formatAverages(weatherAverages) +
                    '\n\nSolar Panel Data:\n' + solarPanelDataString + '\n\nCompany Information:\n' + companyInfoString;
                

                String role = 'assistant';  // Define the role for OpenAI response generation
                String openAiResponse = getOpenAiResponse(prompt, role);
                if (openAiResponse != null) {
                    storeResponseSummary(leadId, openAiResponse);
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
        return 'Average Temperature: ' + averages.get('avg_temp') + ' °C\n' +
            'Average Clear Sky: ' + averages.get('avg_clear_sky') + ' %\n' +
            'Average Predicted Power: ' + averages.get('avg_p_predicted') + ' kW\n' +
            'Average Pressure: ' + averages.get('avg_pressure') + ' hPa\n' +
            'Average Humidity: ' + averages.get('avg_humidity') + ' %\n' +
            'Average Wind Speed: ' + averages.get('avg_wind_speed') + ' m/s\n' +
            'Average Cloud Cover: ' + averages.get('avg_clouds_all') + ' %';
    }

    @AuraEnabled(cacheable=true)
    public static CompanyInfoWrapper getCompanyData(Id leadId) {
        String companyInfoApiKey = getCompanyInfoAPIKey();

        Lead lead = [SELECT Company FROM Lead WHERE Id = :leadId LIMIT 1];
        String companyName = lead.Company;

        if (companyName == null) {
            System.debug('No company name found for the given Lead Id: ' + leadId);
            return null;
        }

        String endpoint = 'https://api.peopledatalabs.com/v5/company/enrich?name=' +
            EncodingUtil.urlEncode(companyName, 'UTF-8') + '&pretty=false';

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

                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                String displayName = (String) responseMap.get('display_name');
                String summary = (String) responseMap.get('summary');

                return new CompanyInfoWrapper(displayName, summary);
            } else {
                System.debug('Failed with status code: ' + response.getStatusCode());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return null;
        }
    }

    // Helper method to construct the request map
    private static Map<String, Object> constructRequestMap(String content, String model, String role) {
        return new Map<String, Object>{
            'messages' => new List<Object>{
                new Map<String, String>{
                    'content' => content,
                    'role' => role
                }
            },
            'model' => 'gpt-3.5-turbo'
        };
    }

    // Method to get OpenAI response with flexible prompt and role
    private static String getOpenAiResponse(String prompt, String role) {
        String openAiKey = getOpenAIKey();
        String endPoint = 'https://api.openai.com/v1/chat/completions';
        Map<String, Object> requestMap = constructRequestMap(prompt, 'gpt-3.5-turbo', role);
        String requestJson = JSON.serialize(requestMap);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + openAiKey);
        req.setBody(requestJson);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res != null && res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> choices = (List<Object>) responseMap.get('choices');
            if (!choices.isEmpty()) {
                Map<String, Object> choice = (Map<String, Object>) choices[0];
                Map<String, Object> message = (Map<String, Object>) choice.get('message');
                return (String) message.get('content');
            } else {
                return 'No choices found in response.';
            }
        } else {
            System.debug('Error response: ' + JSON.deserializeUntyped(res.getBody()));
            return null;
        }
    }

    private static String getOpenAIKey() {
        ApiKeys__c openKeySettings = ApiKeys__c.getInstance('OpenAi');
        return openKeySettings != null ? openKeySettings.Value__c : null;
    }

    private static String getCompanyInfoAPIKey() {
        ApiKeys__c companyInfoKeySettings = ApiKeys__c.getInstance('companyInfo');
        return companyInfoKeySettings != null ? companyInfoKeySettings.Value__c : null;
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
            String endPoint = 'https://api.geoapify.com/v1/geocode/search?text=' +
                EncodingUtil.urlEncode(address, 'UTF-8') + '&apiKey=' + geoapifyAPIKey;

            try {
                HttpResponse response = HttpHelper.sendGetRequest(endPoint);

                if (response != null && response.getStatusCode() == 200) {
                    // Parse JSON response
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    List<Object> features = (List<Object>) parsedResponse.get('features');

                    if (!features.isEmpty()) {
                        Map<String, Object> firstFeature = (Map<String, Object>) features[0];
                        Map<String, Object> geometry = (Map<String, Object>) firstFeature.get('geometry');

                        if (geometry != null) {
                            List<Object> coordinatesList = (List<Object>) geometry.get('coordinates');

                            if (coordinatesList != null && coordinatesList.size() >= 2) {
                                String latitude = String.valueOf(coordinatesList[1]);
                                String longitude = String.valueOf(coordinatesList[0]);
                                coordinates = new CoordinatesWrapper(latitude, longitude);
                            }
                        }
                    }
                } else {
                    errorMessage = 'Error while communicating with Geoapify Data API. Status: ' +
                        response.getStatus() + ' Status code: ' + response.getStatusCode();
                }
            } catch (System.CalloutException e) {
                errorMessage = 'Error while communicating with Geoapify Data API: ' + e.getMessage();
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

    @future
    private static void storeResponseSummary(Id leadId, String summaryText) {
        ResponseSummary__c summary = new ResponseSummary__c();
        summary.Lead__c = leadId;
        summary.Summary__c = summaryText;

        try {
            Database.SaveResult[] srList = Database.insert(new List<ResponseSummary__c>{ summary }, false);
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
}

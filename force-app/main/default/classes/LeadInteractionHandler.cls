public with sharing class LeadInteractionHandler {

    // Get Lead Address
    @AuraEnabled(cacheable=true)
    public static String getLeadAddress(Id leadId) {
        Lead lead = [SELECT Name, Street, City, State, PostalCode, Country FROM Lead WHERE Id = :leadId LIMIT 1];
        if (lead != null) {
            return lead.Street + ', ' + lead.City + ', ' + lead.State + ', ' + lead.PostalCode + ', ' + lead.Country + ', ' + lead.Name;
        } else {
            return 'Address not available';
        }
    }

    //Generate Email Content
    @AuraEnabled(cacheable=true)
    public static String generateEmailContent(Id leadId, String customPromptByUser) {
        List<String> emailPromptParts = new List<String>{
            'Note- Purpose of email is to grab the attention of lead to grow our business by giving our services to lead',
            'Using the provided company information of lead, Solar Data of lead, and Lead\'s address (city only) and Name, write (n if applicable in user prompt) personalized, formatted email for the lead\'s first interaction. Grab the attention of the lead using the lead\'s company information.',
            'The email should be engaging, give a short introduction of ESolarCorp, our company, and include only the necessary information.',
            'Ensure the Email is clear, professional, and includes necessary information to make a strong case for choosing ESolarCorp.',
            'The goal is to make a great first impression and clearly convey our value proposition. Ensure the email is neat, clean, and professionally formatted.',
            'There is also a prompt which is given by the user from the UI, Consider that prompt as well.'
        };

        // Include custom prompt provided by the user if it's not empty
        if (!String.isBlank(customPromptByUser)) {
            System.debug('customPromptByUser: ' + customPromptByUser);
            emailPromptParts.add(customPromptByUser);  // Add custom user input to the email content
        }

        String leadAddress = getLeadAddress(leadId);
        CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
        if (coordinates != null) {
            String latitude = coordinates.latitude;
            String longitude = coordinates.longitude;

            String companyData = 'we are salesforce certified pdo & isv partner, doing amazing things with cloud computing and the salesforce 360 platform  concretio is founded by abhinav - 8 times salesforce mvp (most valuable professional) with over a decade of it experience, was first from india to get rewarded by the mvp title from salesforce.com.highlights:following latest and best practices using sfdx, git, scratch orgs, with ci/cd (via jenkins, circleci, bitbucket pipelines, github actions etc).complex integrations using rest/soap + json/xml + oauth/jwtlwc, aura components with amazing ux. - lightning components and apps. we were among 1st few partners to list an aura component in 2015 in the appexchange component marketplace.appexchange: helped 15+ isv partners take their ideas to a listing on appexchange.salesforce commerce cloud(sfcc) - helping largest e-commerce portals to succeed with demandware, we are quite proud of the javascript skills we bring on to the table.';

            // CompanyInfoWrapper companyData = getCompanyData(leadId);
            // String companyInfoString = companyData != null ? companyData.summary : 'No company information available';
            // System.debug('Company Info: ' + companyInfoString);

            // HttpResponse forecastResponse = SolarForecastService.getForecast(latitude, longitude, '10');
            // Map<String, String> weatherAverages = SolarForecastService.calculateCurrentDateAverages(forecastResponse);

            SolarEnergyDataWrapper forecastResponse = getSolarEnergyData(latitude, longitude);
            System.debug('forecastResponse: ' + forecastResponse);


            if (forecastResponse != null && companyData != null) {
                // Append additional contextual data to the prompt
                emailPromptParts.add('Lead\'s Address: ' + leadAddress);                
                String customPrompt = String.join(emailPromptParts, '\n');
                String prompt = customPrompt + '\n\n Solar Data:\n' + forecastResponse;
                // +'\n\nCompany Information:\n' + companyInfoString;

                String role = 'assistant';  // Define the role for OpenAI response generation
                String openAiResponse = getOpenAiResponse(prompt, role);
                if (openAiResponse != null) {
                    // storeResponseSummary(leadId, openAiResponse);
                    return formatContent(openAiResponse);
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


    // Format content for display
    public static String formatContent(String rawText) {
        String formattedText = '<p>' + rawText.replace('\n', '</p>\n<p>') + '</p>';
        return formattedText;
    }

    // Generate Call Script
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
            callPromptParts.add(customPromptByUser); 
        }

        String leadAddress = getLeadAddress(leadId);
        CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
        if (coordinates != null) {
            String latitude = coordinates.latitude;
            String longitude = coordinates.longitude;

            CompanyInfoWrapper companyData = getCompanyData(leadId);
            String companyInfoString = companyData != null ? companyData.summary : 'No company information available';

            SolarEnergyDataWrapper forecastResponse = getSolarEnergyData(latitude, longitude);


            List<Solar_Panel__c> solarPanelData = getSolarPanelData();
            String solarPanelDataString = '';
            for (Solar_Panel__c panel : solarPanelData) {
                solarPanelDataString += 'Panel Name: ' + panel.Name + ', Description: ' + panel.Description__c + '\n';
            }

            if (forecastResponse != null && companyData != null && solarPanelDataString != null) {
                // Add the lead's address to the custom prompt parts
                callPromptParts.add('Lead\'s Address: ' + leadAddress);
                // Join the custom prompt parts into a single string
                String customPrompt = String.join(callPromptParts, '\n');

                String prompt = customPrompt + '\n\nWeather Data:\n' + forecastResponse +
                    '\n\nSolar Panel Data:\n' + solarPanelDataString + '\n\nCompany Information:\n' + companyInfoString;

                String role = 'assistant';  // Define the role for OpenAI response generation
                String openAiResponse = getOpenAiResponse(prompt, role);
                if (openAiResponse != null) {
                    // storeResponseSummary(leadId, openAiResponse);
                    return formatContent(openAiResponse);
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

    // Fetch Company Data
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

    // Fetch OpenAI API Key
    private static String getOpenAIKey() {
        ApiKeys__c openKeySettings = ApiKeys__c.getInstance('OpenAi');
        return openKeySettings != null ? openKeySettings.Value__c : null;
    }

    // Fetch Company Info API Key
    private static String getCompanyInfoAPIKey() {
        ApiKeys__c companyInfoKeySettings = ApiKeys__c.getInstance('companyInfo');
        return companyInfoKeySettings != null ? companyInfoKeySettings.Value__c : null;
    }

    //weather data for graph
    @RemoteAction
    public static String getSolarDataJSON(Id leadId) {
        // Call methods to fetch and process weather data
        CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
        System.debug('coordinates getWeatherDataJSON'+coordinates);
        // Check if coordinates are available
        if (coordinates != null) {
            String latitude = coordinates.latitude;
            String longitude = coordinates.longitude;
    
            // Call method to fetch weather data
            SolarEnergyDataWrapper forecastSolarData = getSolarEnergyData(latitude, longitude);
            
            System.debug('forecastSolarData: ' + forecastSolarData);
    
            // Process the response and convert to JSON
            if (forecastSolarData != null) {
                System.debug('forecastSolarData: ' + forecastSolarData);
    
                // Serialize the SolarEnergyDataWrapper object to JSON
                String jsonForecastSolarData = JSON.serialize(forecastSolarData);
                return jsonForecastSolarData;
            } else {
                return 'Failed to retrieve weather data.';
            }
        } else {
            return 'Failed to retrieve coordinates for Lead with Id: ' + leadId;
        }
    }
    
    // Fetch Geoapify API Key
    private static String getGeoapifyAPIKey() {
        ApiKeys__c geoKeySettings = ApiKeys__c.getInstance('Geoapify');
        return geoKeySettings != null ? geoKeySettings.Value__c : null;
    }

    // Fetch Lead Address Coordinates
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

    // Fetch Solar Panel Data
    public static List<Solar_Panel__c> getSolarPanelData() {
        List<Solar_Panel__c> solarPanelData = [SELECT Id, Name, Description__c FROM Solar_Panel__c LIMIT 2];
        System.debug('solarPanelData: ' + solarPanelData);
        return solarPanelData;
    }

    // Store Response Summary
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
                // Log detailed error messages from the save operation
                for (Database.Error err : srList[0].getErrors()) {
                    System.debug('Error during insert: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Exception in storeResponseSummary: ' + e.getMessage());
        }
    }

    // Fetch Org-wide Email Address
    @AuraEnabled(cacheable=true)
    public static OrgwideEmailAddress getOrgwideEmailAddress() {
        System.debug('getOrgwideEmailAddress called');
        OrgwideEmailAddress orgwideEmail = [
            SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1
        ];
        System.debug('getOrgwideEmailAddress returning: ' + orgwideEmail);
        return orgwideEmail;
    }

    // Get Lead Email Address
    @AuraEnabled(cacheable=true)
    public static String getLeadEmailAddress(String leadRecordId) {
        System.debug('getLeadEmailAddress called with leadRecordId: ' + leadRecordId);
        Lead lead = [SELECT Id, Email FROM Lead WHERE Id = :leadRecordId LIMIT 1];
        return lead.Email;
    }

    // Send Email
    @AuraEnabled(cacheable=true)
    public static void sendEmailToController(String[] toAddressEmail, Id orgwideEmailAddress, String subjectEmail, String emailHtmlValue, List<Id> uploadedFiles) {
        System.debug('sendEmailToController called');
   
        if (toAddressEmail.isEmpty()) {
            // Handle case where no to addresses are provided
            System.debug('No "to" addresses provided');
            return;
        }
   
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddressEmail);
        System.debug('toAddressEmail: ' + toAddressEmail);
        email.setOrgWideEmailAddressId(orgwideEmailAddress);
        System.debug('orgwideEmailAddress: ' + orgwideEmailAddress);
        email.setSubject(subjectEmail);
        System.debug('subjectEmail: ' + subjectEmail);
        email.setHtmlBody(emailHtmlValue);
        System.debug('emailHtmlValue: ' + emailHtmlValue);
        email.setReplyTo('email@c-d9gats9sb508kdd07nyv4dbsg0cdvcbxbgh4vo0tvfw7nwlpx.bi-lqwdmay.ind14s.apex.sandbox.salesforce.com');
   
        if (uploadedFiles != null && !uploadedFiles.isEmpty()) {
            List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>();
            for (Id contentDocumentId : uploadedFiles) {
                ContentVersion contentVersion = getContentVersion(contentDocumentId);
                if (contentVersion != null) {
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(contentVersion.Title + '.' + contentVersion.FileType);
                    efa.setBody(contentVersion.VersionData);
                    emailFileAttachments.add(efa);
                } else {
                    System.debug('ContentVersion not found for Id: ' + contentDocumentId);
                }
            }
            email.setFileAttachments(emailFileAttachments);
        }
   
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            System.debug('Email sent successfully');
        } catch (Exception ex) {
            System.debug('Error sending email: ' + ex.getMessage());
            // Handle email sending errors (e.g., logging, notifications)
        }
    }

    // Fetch File Attachments
    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> fileAttachment(String leadRecordId) {
        System.debug('leadRecordId: ' + leadRecordId);
        System.debug('fileAttachment=======');
        List<ContentVersion> conVer = new List<ContentVersion>();
        try {
            // First, get the ContentDocumentIds related to the Lead record
            List<ContentDocumentLink> contentDocumentLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :leadRecordId
            ];
            // Collect all ContentDocumentIds into a set
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink cdl : contentDocumentLinks) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
            // Query ContentVersion using the set of ContentDocumentIds
            if (!contentDocumentIds.isEmpty()) {
                conVer = [
                    SELECT Id, ContentDocumentId, Title
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocumentIds
                ];
            }
        } catch (Exception ex) {
            System.debug('Error retrieving attachments for lead ' + leadRecordId + ': ' + ex.getMessage());
        }
        return conVer;
    }

    // Get Content Version
    private static ContentVersion getContentVersion(Id contentDocumentId) {
        return [
            SELECT Id, Title, FileType, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];
    }

    
        // Method to retrieve the API key from the custom setting
    private static String getSolarEnergyAPIKey() {
            ApiKeys__c solarEnergyKeySettings = ApiKeys__c.getInstance('solarEnergy');
            return solarEnergyKeySettings != null ? solarEnergyKeySettings.Value__c : null;
    }



    // Method to get Solar Energy Data with static values for parameters
    @AuraEnabled(cacheable=true)
    public static SolarEnergyDataWrapper getSolarEnergyData(String latitude, String longitude) {
        // Static values for the parameters
        Decimal azimuth = 180;
        Decimal systemCapacity = 4;
        Decimal losses = 14;
        Integer arrayType = 1;
        Integer moduleType = 0;
        Decimal tilt = 10;

        // Retrieve the API key
        String apiKey = getSolarEnergyAPIKey();
        if (apiKey == null) {
            System.debug('API Key not found.');
            return null;
        }

        SolarEnergyDataWrapper solarEnergyData = null;

        // Construct the endpoint URL
        String endpoint = 'https://developer.nrel.gov/api/pvwatts/v8.json?api_key=' + apiKey +
                        '&azimuth=' + azimuth +
                        '&system_capacity=' + systemCapacity +
                        '&losses=' + losses +
                        '&array_type=' + arrayType +
                        '&module_type=' + moduleType +
                        '&tilt=' + tilt +
                        '&lat=' + latitude +
                        '&lon=' + longitude;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('accept', 'application/json');
        
        try {
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200) {
                String responseBody = response.getBody();
                System.debug('Response: ' + responseBody);
                
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                Map<String, Object> outputs = (Map<String, Object>) jsonResponse.get('outputs');
                System.debug('outputs'+outputs);
                List<Object> poaMonthly = (List<Object>) outputs.get('poa_monthly');
                List<Object> acMonthly = (List<Object>) outputs.get('ac_monthly');
                List<Object> solradMonthly = (List<Object>) outputs.get('solrad_monthly');
                List<Object> dcMonthly = (List<Object>) outputs.get('dc_monthly');
        
            
                System.debug('POA Monthly Values: ' + poaMonthly);

                solarEnergyData = new SolarEnergyDataWrapper(poaMonthly,acMonthly,solradMonthly,dcMonthly);
                System.debug('solarEnergyData ' + solarEnergyData);
                
                return solarEnergyData;
            } else {
                System.debug('Failed with status code: ' + response.getStatusCode());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return null;
        }
    }

}


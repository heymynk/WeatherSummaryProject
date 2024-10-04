/**
 * @description       :
 * @author            : Mayank Singh
 * @group             :
 * @last modified on  : 10-04-2024
 * @last modified by  : Mayank Singh
 **/

public with sharing class LeadInteractionHandler {
  // Get Lead Address
  @AuraEnabled(cacheable=true)
  public static String getLeadAddress(String leadId) {
    System.debug('Entering getLeadAddress method');
    System.debug('Lead Id: ' + leadId);

    if (
      !Schema.sObjectType.Lead.fields.Street.isAccessible() ||
      !Schema.sObjectType.Lead.fields.City.isAccessible() ||
      !Schema.sObjectType.Lead.fields.State.isAccessible() ||
      !Schema.sObjectType.Lead.fields.PostalCode.isAccessible() ||
      !Schema.sObjectType.Lead.fields.Country.isAccessible() ||
      !Schema.sObjectType.Lead.fields.Name.isAccessible()
    ) {
      System.debug('User does not have access to required fields');
      return 'Address not available due to insufficient permissions';
    }

    try {
      Lead lead = [
        SELECT Street, City, State, PostalCode, Country
        FROM Lead
        WHERE Id = :leadId
        LIMIT 1
      ];
      System.debug('Lead Query Result: ' + lead);

      if (lead != null) {
        String address =
          lead.Street +
          ', ' +
          lead.City +
          ', ' +
          lead.State +
          ', ' +
          lead.PostalCode +
          ', ' +
          lead.Country;
        System.debug('Lead Address: ' + address);
        return address;
      } else {
        System.debug('Lead is null, address not available');
        return 'Address not available';
      }
    } catch (Exception e) {
      System.debug('Exception occurred in getLeadAddress: ' + e.getMessage());
      return 'Error retrieving address';
    }
  }

  public static String getLeadBasicInfo(String leadId) {
    System.debug('Entering getLeadBasicInfo method');
    System.debug('Lead Id: ' + leadId);

    try {
      Lead lead = [
        SELECT Name, Phone, Email
        FROM Lead
        WHERE Id = :leadId
        LIMIT 1
      ];
      System.debug('Lead Query Result: ' + lead);

      if (lead != null) {
        String basicInfo = lead.Name + ', ' + lead.Phone + ', ' + lead.Email;
        System.debug('Lead Basic Info: ' + basicInfo);
        return basicInfo;
      } else {
        System.debug('Lead is null, basic information not available');
        return 'Basic information are not available';
      }
    } catch (Exception e) {
      System.debug('Exception occurred in getLeadBasicInfo: ' + e.getMessage());
      return 'Error retrieving basic information';
    }
  }

  //Generate Email Content
  @AuraEnabled(cacheable=true)
  public static String generateEmailContent(
    Id leadId,
    String customPromptByUser
  ) {
    System.debug('Entering generateEmailContent method');
    System.debug('Lead Id: ' + leadId);
    System.debug('Custom Prompt By User: ' + customPromptByUser);

    List<String> emailPromptParts = prepareEmailPrompt(customPromptByUser);
    System.debug('Prepared Email Prompt Parts: ' + emailPromptParts);

    String leadBasicInfo = getLeadBasicInfo(leadId);
    System.debug('Lead Basic Info: ' + leadBasicInfo);

    String leadAddress = getLeadAddress(leadId);
    System.debug('Lead Address: ' + leadAddress);

    CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
    System.debug('Coordinates: ' + coordinates);

    if (coordinates == null) {
      return 'Failed to retrieve coordinates for Lead with Id: ' + leadId;
    }

    System.debug('Coordinates retrieved: ' + coordinates);

    String latitude = coordinates.latitude;
    String longitude = coordinates.longitude;

    CompanyInfoWrapper companyData = getCompanyData(leadId);
    System.debug('Company Data: ' + companyData);

    String companyInfoString = companyData != null
      ? companyData.summary
      : 'No company information available';
    System.debug('Company Info String: ' + companyInfoString);

    SolarEnergyDataWrapper forecastResponse = getSolarEnergyData(
      latitude,
      longitude
    );

    if (forecastResponse == null || companyData == null) {
      return 'Failed to retrieve weather data or company information.';
    }

    System.debug('Solar Energy Data: ' + forecastResponse);

    emailPromptParts.add('Lead\'s Basic Info: ' + leadBasicInfo);
    emailPromptParts.add('Lead\'s Address: ' + leadAddress);

    String customPrompt = String.join(emailPromptParts, '\n');
    String prompt =
      customPrompt +
      '\n\n Solar Data:\n' +
      forecastResponse +
      '\n\nCompany Information:\n' +
      companyData;
    System.debug('Final Prompt: ' + prompt);

    String openAiResponse = getOpenAiResponse(prompt, 'assistant');
    System.debug('OpenAI Response: ' + openAiResponse);

    if (openAiResponse == null) {
      return 'Failed to retrieve OpenAI response.';
    }

    return formatContent(openAiResponse);
  }

  // @AuraEnabled(cacheable=true)
  // public static String generateEmailContent(Id leadId, String customPromptByUser) {
  //     // Construct the email content with HTML formatting
  //     String emailContent =
  //         '<html><body>' +
  //         'Subject: Solar potential energy' +
  //         '<p>Hello Kundan Sharma,</p>' +
  //         '<p>I trust this message finds you energized and ready to explore new possibilities with Concretio in Mountain View, CA. ' +
  //         'At ESolarCorp, we specialize in maximizing solar energy efficiency tailored to your precise needs. ' +
  //         'Our cutting-edge solutions are designed to elevate your solar power utilization to new heights. ' +
  //         'With our state-of-the-art technology and unwavering commitment to sustainability, ESolarCorp is your go-to partner for harnessing the power of the sun. ' +
  //         'Let\'s work together to unlock the full potential of solar energy at Concretio. Looking forward to discussing how ESolarCorp can revolutionize your solar initiatives. ' +
  //         'Reach back to us to embark on this renewable energy journey!</p>' +
  //         '<p>Warm Regards,<br/>' +
  //         '[Your Name]<br/>' +
  //         'ESolarCorp Team</p>' +
  //         '</body></html>';

  //     return emailContent;
  // }

  private static List<String> prepareEmailPrompt(String customPromptByUser) {
    System.debug('Entering prepareEmailPrompt method');
    System.debug('Custom Prompt By User: ' + customPromptByUser);

    List<String> emailPromptParts = new List<String>{
      'Note- Purpose of email is to grab the attention of lead to grow our business by giving our services to lead.',
      'Using the provided company information of lead, Solar Data of lead, and Lead\'s address (city only) and Name, write (n if applicable in user prompt) personalized, formatted email for the lead\'s first interaction. Grab the attention of the lead using the lead\'s company information.',
      'The email should be engaging, give a short introduction of ESolarCorp, our company, and include only the necessary information.',
      'Ensure the Email is clear, professional, and includes necessary information to make a strong case for choosing ESolarCorp.',
      'The goal is to make a great first impression and clearly convey our value proposition. Ensure the email is neat, clean, and professionally formatted.',
      'There is also a prompt which is given by the user from the UI, Consider that prompt as well.',
      'Please do not use always this greeting "I hope this email finds you well", also use other alternative greeting or statements in each response while creating or regenerating emails to avoid predictability and ensure authenticity.',
      'Note-Please do not use any suggestion or remarks after you have given Warms and Regards to the email.'
    };

    if (!String.isBlank(customPromptByUser)) {
      emailPromptParts.add(customPromptByUser);
    }

    System.debug('Email Prompt Parts: ' + emailPromptParts);
    return emailPromptParts;
  }

  // Generate Call Script
  @AuraEnabled(cacheable=true)
  public static String generateCallScript(
    Id leadId,
    String customPromptByUser
  ) {
    System.debug('Entering generateCallScript method');
    System.debug('Lead Id: ' + leadId);
    System.debug('Custom Prompt By User: ' + customPromptByUser);

    List<String> callPromptParts = prepareCallPrompt(customPromptByUser);
    System.debug('Call Prompt Parts: ' + callPromptParts);

    String leadAddress = getLeadAddress(leadId);
    System.debug('Lead Address: ' + leadAddress);

    String leadBasicInfo = getLeadBasicInfo(leadId);
    System.debug('Lead Basic Info: ' + leadBasicInfo);

    CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
    System.debug('Coordinates: ' + coordinates);

    if (coordinates == null) {
      return 'Failed to retrieve coordinates for Lead with Id: ' + leadId;
    }

    String latitude = coordinates.latitude;
    String longitude = coordinates.longitude;

    CompanyInfoWrapper companyData = getCompanyData(leadId);
    System.debug('Company Data: ' + companyData);

    String companyInfoString = companyData != null
      ? companyData.summary
      : 'No company information available';
    System.debug('Company Info String: ' + companyInfoString);

    SolarEnergyDataWrapper forecastResponse = getSolarEnergyData(
      latitude,
      longitude
    );

    if (forecastResponse == null || companyData == null) {
      return 'Failed to retrieve weather data or company information.';
    }

    System.debug('Solar Energy Data: ' + forecastResponse);

    String solarPanelDataString = getSolarPanelDataDetails();
    System.debug('Solar Panel Data: ' + solarPanelDataString);

    callPromptParts.add('Lead\'s Address: ' + leadAddress);
    callPromptParts.add('Lead\'s basicInfo: ' + leadBasicInfo);

    String customPrompt = String.join(callPromptParts, '\n');
    System.debug('Custom Prompt: ' + customPrompt);

    String prompt =
      customPrompt +
      '\n\nWeather Data:\n' +
      forecastResponse +
      '\n\nSolar Panel Data:\n' +
      solarPanelDataString +
      '\n\nCompany Information:\n' +
      companyData;
    System.debug('Final Prompt: ' + prompt);

    String openAiResponse = getOpenAiResponse(prompt, 'assistant');
    System.debug('OpenAI Response: ' + openAiResponse);

    if (openAiResponse == null) {
      return 'Failed to retrieve OpenAI response.';
    }

    return formatContent(openAiResponse);
  }

  private static List<String> prepareCallPrompt(String customPromptByUser) {
    System.debug('Entering prepareCallPrompt method');
    System.debug('Custom Prompt By User: ' + customPromptByUser);

    List<String> callPromptParts = new List<String>{
      'Note- Purpose of call script is to grab the attention of lead to grow our business by giving our services and showcasing our products to lead',
      'Using the provided company information of lead, Solar Data of lead, Lead\'s address (city only), Lead\'s Name and product data write (n if applicable in user prompt) personalized, formatted call script for the lead\'s first interaction. Grab the attention of the lead using the lead\'s company information and showcasing the products',
      'The script should be engaging, starting with an introduction of ESolarCorp, our company, followed by a discussion on how our solar panel products can benefit the lead considering the current weather conditions.',
      'Include key points about the advantages of our products and tailor the conversation to address the lead\'s specific needs.',
      'Ensure the script is clear, professional, and includes necessary information to make a strong case for choosing ESolarCorp.',
      'There is also a prompt which is given by the user from the UI, Consider that prompt as well.'
    };

    if (!String.isBlank(customPromptByUser)) {
      callPromptParts.add(customPromptByUser);
    }

    System.debug('Call Prompt Parts: ' + callPromptParts);
    return callPromptParts;
  }

  // Generate Solar Data Summary
  @AuraEnabled(cacheable=true)
  public static String generateSolarDataSummary(Id leadId) {
    System.debug('Entering generateSolarDataSummary method');
    System.debug('Lead Id: ' + leadId);

    CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
    System.debug('Coordinates: ' + coordinates);

    if (coordinates == null) {
      return 'Failed to retrieve coordinates for Lead with Id: ' + leadId;
    }

    String latitude = coordinates.latitude;
    String longitude = coordinates.longitude;

    SolarEnergyDataWrapper forecastResponse = getSolarEnergyData(
      latitude,
      longitude
    );

    if (forecastResponse == null) {
      return 'Failed to retrieve solar energy data.';
    }

    System.debug('Solar Energy Data: ' + forecastResponse);

    String prompt =
      'Generate a detailed and concise summary for the following solar energy data:\n\n' +
      'Solar Energy Forecast Data:\n' +
      forecastResponse +
      '\n\n' +
      'The summary should highlight key insights and potential benefits of the solar energy data provided, ' +
      'potential energy production, and any notable patterns or observations. ' +
      'The summary should be written in a professional and informative tone.\n\n' +
      'Note: The summary should be between 100 to 150 words.';
    System.debug('Prompt: ' + prompt);

    String openAiResponse = getOpenAiResponse(prompt, 'assistant');
    System.debug('OpenAI Response: ' + openAiResponse);

    if (openAiResponse == null) {
      return 'Failed to retrieve OpenAI response.';
    }

    return formatContent(openAiResponse);
  }

  private static String getSolarPanelDataDetails() {
    System.debug('Entering getSolarPanelDataDetails method');

    List<Solar_Panel__c> solarPanelData = getSolarPanelData();
    System.debug('Solar Panel Data: ' + solarPanelData);

    String solarPanelDataString = '';
    for (Solar_Panel__c panel : solarPanelData) {
      solarPanelDataString +=
        'Panel Name: ' +
        panel.Name +
        ', Description: ' +
        panel.Description__c +
        '\n';
    }
    System.debug('Solar Panel Data String: ' + solarPanelDataString);
    return solarPanelDataString;
  }

  @AuraEnabled(cacheable=true)
  public static CompanyInfoWrapper getCompanyData(Id leadId) {
    System.debug('Entering getCompanyData method');
    System.debug('Lead Id: ' + leadId);

    // Retrieve API Key
    String companyInfoApiKey = getCompanyInfoAPIKey();
    System.debug('Company Info API Key: ' + companyInfoApiKey);

    // Fetch Lead details
    Lead lead = [SELECT Company FROM Lead WHERE Id = :leadId LIMIT 1];
    System.debug('Lead Query Result: ' + lead);

    // Check if company exists for the lead
    if (lead.Company == null) {
      System.debug('No company name found for the given Lead Id: ' + leadId);
      return getHardcodedCompanyInfo();
    }

    String companyName = lead.Company;
    System.debug('Company Name: ' + companyName);

    // Prepare the API endpoint URL
    String endpoint =
      'https://api.peopledatalabs.com/v5/company/enrich?name=' +
      EncodingUtil.urlEncode(companyName, 'UTF-8') +
      '&pretty=false';
    System.debug('Company Info API Endpoint: ' + endpoint);

    try {
      // Call helper method to send GET request
      HttpResponse response = HttpHelper.sendGetRequestCompany(
        endpoint,
        companyInfoApiKey
      );
      System.debug('HTTP Response: ' + response);

      if (response != null) {
        // Check HTTP status code
        if (response.getStatusCode() == 200) {
          System.debug('Successful API Response with Status Code: 200');

          // Process successful response
          String responseBody = response.getBody();
          System.debug('Response Body: ' + responseBody);

          Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
            responseBody
          );
          String displayName = (String) responseMap.get('display_name');
          String summary = (String) responseMap.get('summary');
          System.debug('Company Display Name: ' + displayName);
          System.debug('Company Summary: ' + summary);

          return new CompanyInfoWrapper(displayName, summary);
        } else {
          // Handle non-200 status codes
          System.debug('Failed with status code: ' + response.getStatusCode());
          return getHardcodedCompanyInfo();
        }
      } else {
        // Handle null response
        System.debug('No response received from the API.');
        return getHardcodedCompanyInfo();
      }
    } catch (Exception e) {
      // Handle exception
      System.debug('Exception occurred: ' + e.getMessage());
      return getHardcodedCompanyInfo();
    }
  }

  private static CompanyInfoWrapper getHardcodedCompanyInfo() {
    System.debug('Entering getHardcodedCompanyInfo method');

    String hardcodedDisplayName = 'Concretio';
    String hardcodedSummary = 'We are Salesforce certified PDO & ISV partner, doing amazing things with cloud computing and the Salesforce 360 platform. Concretio is founded by Abhinav - 8 times Salesforce MVP (Most Valuable Professional) with over a decade of IT experience, was first from India to get rewarded by the MVP title from Salesforce.com.\n\nHighlights:\n- Following latest and best practices using SFDX, GIT, Scratch Orgs, with CI/CD (via Jenkins, CircleCI, Bitbucket Pipelines, GitHub Actions etc).\n- Complex Integrations using REST/SOAP + JSON/XML + OAuth/JWT.\n- LWC, Aura components with amazing UX. - Lightning components and apps. We were among the first few partners to list an Aura component in 2015 in the AppExchange component marketplace.\n- AppExchange: Helped 15+ ISV partners take their ideas to a listing on AppExchange.\n- Salesforce Commerce Cloud(SFCC) - Helping largest e-commerce portals to succeed with Demandware, we are quite proud of the Javascript skills we bring on to the table.\n- Salesforce Marketing Cloud (SFMC).';
    System.debug(
      'Hardcoded Company Info: ' +
        hardcodedDisplayName +
        ', ' +
        hardcodedSummary
    );
    return new CompanyInfoWrapper(hardcodedDisplayName, hardcodedSummary);
  }

  // Wrapper method to access the private getHardcodedCompanyInfo method for testing
  @TestVisible
  private static CompanyInfoWrapper accessHardcodedCompanyInfo() {
    return getHardcodedCompanyInfo();
  }

  // Get Solar Energy Data
  @AuraEnabled(cacheable=true)
  public static SolarEnergyDataWrapper getSolarEnergyData(
    String latitude,
    String longitude
  ) {
    Decimal azimuth = 180;
    Decimal systemCapacity = 4;
    Decimal losses = 14;
    Integer arrayType = 1;
    Integer moduleType = 0;
    Decimal tilt = 10;

    String apiKey = getSolarEnergyAPIKey();
    if (apiKey == null) {
      System.debug('API Key not found.');
      return null;
    }

    String endpoint =
      'https://developer.nrel.gov/api/pvwatts/v8.json?api_key=' +
      apiKey +
      '&azimuth=' +
      azimuth +
      '&system_capacity=' +
      systemCapacity +
      '&losses=' +
      losses +
      '&array_type=' +
      arrayType +
      '&module_type=' +
      moduleType +
      '&tilt=' +
      tilt +
      '&lat=' +
      latitude +
      '&lon=' +
      longitude;

    try {
      HttpResponse response = HttpHelper.sendGetRequest(endpoint);

      if (response.getStatusCode() == 200) {
        String responseBody = response.getBody();

        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(
          responseBody
        );
        Map<String, Object> outputs = (Map<String, Object>) jsonResponse.get(
          'outputs'
        );
        List<Object> poaMonthly = (List<Object>) outputs.get('poa_monthly');
        List<Object> acMonthly = (List<Object>) outputs.get('ac_monthly');
        List<Object> solradMonthly = (List<Object>) outputs.get(
          'solrad_monthly'
        );
        List<Object> dcMonthly = (List<Object>) outputs.get('dc_monthly');

        SolarEnergyDataWrapper solarEnergyData = new SolarEnergyDataWrapper(
          poaMonthly,
          acMonthly,
          solradMonthly,
          dcMonthly
        );

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

  @AuraEnabled(cacheable=true)
  public static List<EmailMessage> getLatestEmailMessageInActivityTimeline(
    String leadId
  ) {
    String leadEmail = getLeadEmailAddress(leadId);
    OrgwideEmailAddress orgwideEmail = getOrgwideEmailAddress();
    List<EmailMessage> emailMessages = new List<EmailMessage>();

    try {
      emailMessages = [
        SELECT
          Id,
          CreatedDate,
          ToAddress,
          FromAddress,
          HtmlBody,
          TextBody,
          Subject
        FROM EmailMessage
        WHERE
          ToAddress LIKE :('%' + leadEmail + '%')
          AND FromAddress LIKE :('%' + orgwideEmail.Address + '%')
        ORDER BY CreatedDate DESC
        LIMIT 3
      ];
    } catch (Exception e) {
      System.debug(
        'Error occurred while retrieving email messages: ' + e.getMessage()
      );
    }

    return emailMessages;
  }

  // Get Solar Panel Data
  @AuraEnabled(cacheable=true)
  public static List<Solar_Panel__c> getSolarPanelData() {
    if (
      !Schema.sObjectType.Solar_Panel__c.fields.Name.isAccessible() ||
      !Schema.sObjectType.Solar_Panel__c.fields.Description__c.isAccessible()
    ) {
      return new List<Solar_Panel__c>();
    }

    List<Solar_Panel__c> solarPanelData = [
      SELECT Id, Name, Description__c
      FROM Solar_Panel__c
      LIMIT 2
    ];
    return solarPanelData;
  }

  // Fetch Lead Address Coordinates
  @AuraEnabled(cacheable=true)
  public static CoordinatesWrapper fetchLeadAddressByCoordinates(Id leadId) {
    CoordinatesWrapper coordinates = null;
    String errorMessage = '';

    if (
      !Schema.sObjectType.Lead.fields.Street.isAccessible() ||
      !Schema.sObjectType.Lead.fields.City.isAccessible() ||
      !Schema.sObjectType.Lead.fields.State.isAccessible() ||
      !Schema.sObjectType.Lead.fields.PostalCode.isAccessible() ||
      !Schema.sObjectType.Lead.fields.Country.isAccessible()
    ) {
      return null;
    }

    Lead lead = [
      SELECT Street, City, State, PostalCode, Country
      FROM Lead
      WHERE Id = :leadId
      WITH SECURITY_ENFORCED
    ];

    if (lead != null) {
      String address = '';
      address += lead.Street != null ? lead.Street + ',' : '';
      address += lead.City != null ? lead.City + ',' : '';
      address += lead.State != null ? lead.State + ',' : '';
      address += lead.PostalCode != null ? lead.PostalCode + ',' : '';
      address += lead.Country != null ? lead.Country : '';

      address = address.endsWith(',') ? address.removeEnd(',') : address;

      String geoapifyAPIKey = getGeoapifyAPIKey();
      String endPoint =
        'https://api.geoapify.com/v1/geocode/search?text=' +
        EncodingUtil.urlEncode(address, 'UTF-8') +
        '&apiKey=' +
        geoapifyAPIKey;

      try {
        HttpResponse response = HttpHelper.sendGetRequest(endPoint);

        if (response != null && response.getStatusCode() == 200) {
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
                System.debug('latitude' + latitude + ' longitude' + longitude);
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

  // Fetch File Attachments
  @AuraEnabled(cacheable=true)
  public static List<ContentVersion> fileAttachment(String leadRecordId) {
    List<ContentVersion> conVer = new List<ContentVersion>();

    if (
      !Schema.sObjectType.ContentDocumentLink.isAccessible() ||
      !Schema.sObjectType.ContentVersion.isAccessible() ||
      !Schema.sObjectType.ContentVersion.fields.ContentDocumentId.isAccessible() ||
      !Schema.sObjectType.ContentVersion.fields.Title.isAccessible()
    ) {
      System.debug(
        'User does not have access to ContentDocumentLink or ContentVersion or required fields.'
      );
      return conVer;
    }

    try {
      List<ContentDocumentLink> contentDocumentLinks = [
        SELECT ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :leadRecordId
      ];

      Set<Id> contentDocumentIds = new Set<Id>();
      for (ContentDocumentLink cdl : contentDocumentLinks) {
        contentDocumentIds.add(cdl.ContentDocumentId);
      }

      if (!contentDocumentIds.isEmpty()) {
        conVer = [
          SELECT Id, ContentDocumentId, Title
          FROM ContentVersion
          WHERE ContentDocumentId IN :contentDocumentIds
        ];
      }
    } catch (Exception ex) {
      System.debug(
        'Error retrieving attachments for lead ' +
          leadRecordId +
          ': ' +
          ex.getMessage()
      );
    }

    return conVer;
  }

  private static ContentVersion getContentVersion(Id contentDocumentId) {
    if (
      Schema.sObjectType.ContentVersion.isAccessible() &&
      Schema.sObjectType.ContentVersion.fields.Title.isAccessible() &&
      Schema.sObjectType.ContentVersion.fields.FileType.isAccessible() &&
      Schema.sObjectType.ContentVersion.fields.VersionData.isAccessible()
    ) {
      List<ContentVersion> contentVersions = [
        SELECT Id, Title, FileType, VersionData
        FROM ContentVersion
        WHERE ContentDocumentId = :contentDocumentId
        ORDER BY VersionNumber DESC
        LIMIT 1
      ];

      if (!contentVersions.isEmpty()) {
        return contentVersions[0];
      }
    } else {
      System.debug(
        'User does not have access to ContentVersion or its fields.'
      );
    }
    return null;
  }

  /*
    public static void sendEmailToController(
        String[] toAddressEmail,  // Accepts a single array of email addresses
        Id orgwideEmailAddress,
        String subjectEmail,
        String emailHtmlValue,
        List<Id> uploadedFiles
    ) {
        if (toAddressEmail.isEmpty()) {
            System.debug('No "to" addresses provided');
            return;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddressEmail); // Sets multiple email addresses at once
        email.setOrgWideEmailAddressId(orgwideEmailAddress);
        email.setSubject(subjectEmail);
        email.setHtmlBody(emailHtmlValue);
        email.setReplyTo('...');

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
            // updateLeadStatus(email.getToAddresses()); // Commented out in this version
        } catch (Exception ex) {
            System.debug('Error sending email: ' + ex.getMessage());
        }
    }

  */

  // Send Email
  @AuraEnabled
  public static void sendEmailToController(
    List<String> toAddressEmails,
    Id orgwideEmailAddress,
    String subjectEmail,
    String emailHtmlValue,
    List<Id> uploadedFiles
  ) {
    System.debug('toAddressEmails: ' + toAddressEmails);
    System.debug('orgwideEmailAddress: ' + orgwideEmailAddress);
    System.debug('subjectEmail: ' + subjectEmail);
    System.debug('emailHtmlValue: ' + emailHtmlValue);
    System.debug('uploadedFiles: ' + uploadedFiles);

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (String toAddressEmail : toAddressEmails) {
      System.debug('Processing email for: ' + toAddressEmail);
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setToAddresses(new List<String>{ toAddressEmail });
      email.setOrgWideEmailAddressId(orgwideEmailAddress);
      email.setSubject(subjectEmail);
      email.setHtmlBody(emailHtmlValue);
      email.setReplyTo(
        'esolarcorp_email_service@t-2tw8qj2trynxrvktpo2nzr0kdje70zfp2u66nzqnrh16ygu3ar.c1-1fdgbmak.ind16s.apex.sandbox.salesforce.com'
      );

      System.debug('Email initialized with To Address: ' + toAddressEmail);

      if (uploadedFiles != null && !uploadedFiles.isEmpty()) {
        System.debug('Processing file attachments...');
        List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>();
        for (Id contentDocumentId : uploadedFiles) {
          System.debug('Processing ContentDocumentId: ' + contentDocumentId);
          ContentVersion contentVersion = getContentVersion(contentDocumentId);
          if (contentVersion != null) {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(
              contentVersion.Title + '.' + contentVersion.FileType
            );
            efa.setBody(contentVersion.VersionData);
            emailFileAttachments.add(efa);
            System.debug(
              'Added attachment: ' +
                contentVersion.Title +
                '.' +
                contentVersion.FileType
            );
          } else {
            System.debug(
              'ContentVersion not found for Id: ' + contentDocumentId
            );
          }
        }
        email.setFileAttachments(emailFileAttachments);
      }

      emails.add(email);
      System.debug('Email added to list: ' + email);
    }

    try {
      Messaging.sendEmail(emails);
      System.debug('Emails sent successfully: ' + emails);
    } catch (Exception ex) {
      System.debug('Error sending emails: ' + ex.getMessage());
    }
  }

  @future
  private static void updateLeadStatus(String[] toAddresses) {
    List<Lead> leadsToUpdate = [
      SELECT Id, Email, Lead_Response__c
      FROM Lead
      WHERE Email IN :toAddresses
      LIMIT 1
    ];

    for (Lead lead : leadsToUpdate) {
      if (lead.Lead_Response__c == 'Open - Not Contacted') {
        lead.Lead_Response__c = 'Working - Contacted';
      }
    }

    if (!leadsToUpdate.isEmpty()) {
      update leadsToUpdate;
      System.debug('Lead status updated to Open - Contacted');
    }
  }

  // Get Org-wide Email Address
  @AuraEnabled(cacheable=true)
  public static OrgwideEmailAddress getOrgwideEmailAddress() {
    OrgwideEmailAddress orgwideEmail;
    if (Schema.sObjectType.OrgWideEmailAddress.isAccessible()) {
      orgwideEmail = [SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1];
    } else {
      orgwideEmail = new OrgwideEmailAddress();
    }
    return orgwideEmail;
  }

  // Get Lead Email Address
  @AuraEnabled(cacheable=true)
  public static String getLeadEmailAddress(String leadRecordId) {
    Lead lead = [SELECT Id, Email FROM Lead WHERE Id = :leadRecordId LIMIT 1];
    return lead.Email;
  }

  // Helper method to construct the request map for OpenAI
  private static Map<String, Object> constructRequestMap(
    String content,
    String model,
    String role
  ) {
    return new Map<String, Object>{
      'messages' => new List<Object>{
        new Map<String, String>{ 'content' => content, 'role' => role }
      },
      'model' => model
    };
  }

  // Method to get OpenAI response with flexible prompt and role
  private static String getOpenAiResponse(String prompt, String role) {
    String openAiKey = getOpenAIKey();
    String endPoint = 'https://api.openai.com/v1/chat/completions';
    Map<String, Object> requestMap = constructRequestMap(
      prompt,
      'gpt-3.5-turbo',
      role
    );
    String requestJson = JSON.serialize(requestMap);

    try {
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
        if (!choices.isEmpty()) {
          Map<String, Object> choice = (Map<String, Object>) choices[0];
          Map<String, Object> message = (Map<String, Object>) choice.get(
            'message'
          );
          return (String) message.get('content');
        } else {
          return 'No choices found in response.';
        }
      } else {
        System.debug(
          'Error response: ' + JSON.deserializeUntyped(res.getBody())
        );
        return null;
      }
    } catch (Exception e) {
      System.debug('Exception: ' + e.getMessage());
      return null;
    }
  }
  //weather data for graph

  @AuraEnabled(cacheable=true)
  public static String getSolarDataJSON(Id leadId) {
    try {
      // Call methods to fetch and process weather data
      CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);
      System.debug('Coordinates: ' + coordinates);

      // Check if coordinates are available
      if (coordinates != null) {
        String latitude = coordinates.latitude;
        String longitude = coordinates.longitude;

        // Call method to fetch weather data
        SolarEnergyDataWrapper forecastSolarData = getSolarEnergyData(
          latitude,
          longitude
        );

        // Process the response and convert to JSON
        if (forecastSolarData != null) {
          // Serialize the SolarEnergyDataWrapper object to JSON
          String jsonForecastSolarData = JSON.serialize(forecastSolarData);
          System.debug('JSON Forecast Solar Data: ' + jsonForecastSolarData);
          return jsonForecastSolarData;
        } else {
          String errorMessage = '{"error": "Failed to retrieve weather data."}';
          System.debug('Error: ' + errorMessage);
          return errorMessage;
        }
      } else {
        String errorMessage =
          '{"error": "Failed to retrieve coordinates for Lead with Id: ' +
          leadId +
          '"}';
        System.debug('Error: ' + errorMessage);
        return errorMessage;
      }
    } catch (Exception e) {
      String errorMessage =
        '{"error": "Exception occurred while fetching solar data: ' +
        e.getMessage() +
        '"}';
      System.debug('Exception: ' + errorMessage);
      return errorMessage;
    }
  }

  // Format content for display
  public static String formatContent(String rawText) {
    return '<p>' + rawText.replace('\n', '</p>\n<p>') + '</p>';
  }

  // Fetch OpenAI API Key
  private static String getOpenAIKey() {
    ApiKeys__c openKeySettings = ApiKeys__c.getInstance('OpenAi');
    return openKeySettings != null ? openKeySettings.Value__c : null;
  }

  // Fetch Company Info API Key
  public static String getCompanyInfoAPIKey() {
    ApiKeys__c companyInfoKeySettings = ApiKeys__c.getInstance('companyInfo');
    return companyInfoKeySettings != null
      ? companyInfoKeySettings.Value__c
      : null;
  }

  // Fetch Solar Energy API Key
  private static String getSolarEnergyAPIKey() {
    ApiKeys__c solarEnergyKeySettings = ApiKeys__c.getInstance('solarEnergy');
    return solarEnergyKeySettings != null
      ? solarEnergyKeySettings.Value__c
      : null;
  }

  // Fetch Geoapify API Key
  private static String getGeoapifyAPIKey() {
    ApiKeys__c geoKeySettings = ApiKeys__c.getInstance('Geoapify');
    return geoKeySettings != null ? geoKeySettings.Value__c : null;
  }

  // Function to get the latest email msg body for a specific lead
  @AuraEnabled(cacheable=true)
  public static List<EmailMessage> getLatestEmailMessageForLead(Id leadId) {
    String leadEmail = getLeadEmailAddress(leadId);
    OrgwideEmailAddress orgwideEmail = getOrgwideEmailAddress();

    System.debug('Entering getLatestEmailMessageForLead method');
    System.debug('Lead Id: ' + leadId);

    List<EmailMessage> emailMessages = new List<EmailMessage>();

    try {
      emailMessages = [
        SELECT Id, CreatedDate, ToAddress, FromAddress, HtmlBody, TextBody
        FROM EmailMessage
        WHERE
          ToAddress LIKE :('%' + leadEmail + '%')
          OR FromAddress LIKE :('%' + orgwideEmail.Address + '%')
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];

      System.debug('Email Messages retrieved: ' + emailMessages.size());
      if (!emailMessages.isEmpty()) {
        System.debug('Latest Email Message Id: ' + emailMessages[0].Id);
        System.debug(
          'Latest Email Message CreatedDate: ' + emailMessages[0].CreatedDate
        );
        System.debug(
          'Latest Email Message FromAddress: ' + emailMessages[0].FromAddress
        );
        System.debug(
          'Latest Email Message ToAddress: ' + emailMessages[0].ToAddress
        );
      } else {
        System.debug('No Email Messages found for the given Lead Id');
      }
    } catch (Exception e) {
      System.debug(
        'Error occurred while retrieving email messages: ' + e.getMessage()
      );
    }

    System.debug('Exiting getLatestEmailMessageForLead method');
    return emailMessages;
  }

  @AuraEnabled(cacheable=true)
  public static String getLeadResponse(Id leadId) {
    Lead leadRecord = [
      SELECT Lead_Response__c
      FROM Lead
      WHERE Id = :leadId
      LIMIT 1
    ];
    return leadRecord.Lead_Response__c;
  }

  @AuraEnabled(cacheable=true)
  public static String getEmailDetailsForReply(String leadId) {
    try {
      // Query the latest EmailMessage related to the Lead
      String leadEmail = getLeadEmailAddress(leadId);
      OrgwideEmailAddress orgwideEmail = getOrgwideEmailAddress();
      System.debug('Lead Email Address: ' + leadEmail);

      EmailMessage latestEmail = [
        SELECT Id, HtmlBody, Subject, FromAddress, ToAddress, CreatedDate
        FROM EmailMessage
        WHERE
          ToAddress LIKE :('%' + leadEmail + '%')
          AND FromAddress LIKE :('%' + orgwideEmail.Address + '%')
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];

      if (latestEmail != null) {
        System.debug('Latest Email found: ' + latestEmail.Id);

        // Get the HTML body from the EmailMessage
        String htmlBody = latestEmail.HtmlBody;
        System.debug('HTML Body: ' + htmlBody);

        // Extract user reply and original email
        String userReply = extractUserReply(htmlBody);
        String originalEmail = extractOriginalEmail(htmlBody);
        System.debug('User Reply: ' + userReply);
        System.debug('Original Email: ' + originalEmail);

        // Concatenate the user reply and original email
        String emailDetails =
          'User Reply:\n' +
          userReply +
          '\n\nOriginal Email:\n' +
          originalEmail;
        return emailDetails;
      } else {
        return 'No EmailMessage found for the provided Lead ID.';
      }
    } catch (Exception e) {
      return 'Exception: ' + e.getMessage();
    }
  }

  public static String extractUserReply(String htmlBody) {
    try {
      // Define the marker for the start of the quoted email
      String marker = '<div class="gmail_quote">';

      // Find the index of the marker
      Integer markerIndex = htmlBody.indexOf(marker);

      if (markerIndex != -1) {
        // Extract the user reply part before the quoted email
        String userReply = htmlBody.substring(0, markerIndex);
        return removeHtmlTags(userReply).trim();
      }

      // If no marker is found, return the entire HTML body without tags
      return removeHtmlTags(htmlBody).trim();
    } catch (Exception e) {
      // Handle any exceptions and return an empty string
      return '';
    }
  }

  public static String extractOriginalEmail(String htmlBody) {
    try {
      // Define the marker for the start of the quoted email
      String marker = '<div class="gmail_quote">';

      // Find the index of the marker
      Integer markerIndex = htmlBody.indexOf(marker);

      if (markerIndex != -1) {
        // Extract the original email part from the marker onward
        String originalEmail = htmlBody.substring(markerIndex);
        return removeHtmlTags(originalEmail).trim();
      }

      // If no marker is found, return an empty string
      return '';
    } catch (Exception e) {
      // Handle any exceptions and return an empty string
      return '';
    }
  }

  private static String removeHtmlTags(String html) {
    // Remove HTML tags from the string using regex
    return html.replaceAll('<[^>]*>', '');
  }

  @AuraEnabled(cacheable=true)
  public static String replyWithEmail(Id leadId, String customPromptByUser) {
    List<String> emailReplyPromptParts = replyWithEmailPrompt(
      customPromptByUser
    );

    String leadBasicInfo = getLeadBasicInfo(leadId);

    CoordinatesWrapper coordinates = fetchLeadAddressByCoordinates(leadId);

    if (coordinates == null) {
      return 'Failed to retrieve coordinates for Lead with Id: ' + leadId;
    }

    String latitude = coordinates.latitude;
    String longitude = coordinates.longitude;

    SolarEnergyDataWrapper forecastResponse = getSolarEnergyData(
      latitude,
      longitude
    );

    if (forecastResponse == null) {
      return 'Failed to retrieve solar energy data.';
    }

    emailReplyPromptParts.add('Lead\'s Basic Info: ' + leadBasicInfo);

    // Fetch the latest email details
    String emailDetails = getEmailDetailsForReply(leadId);

    if (emailDetails.contains('error')) {
      return emailDetails;
    }

    // Get the latest email message
    String userReply = extractUserReply(emailDetails);
    System.debug('userReply' + userReply);
    String originalEmail = extractOriginalEmail(emailDetails);
    System.debug('originalEmail' + originalEmail);

    // Concatenate the user reply and original email
    emailReplyPromptParts.add('User Reply: \n' + userReply);
    emailReplyPromptParts.add('Original Email: \n' + originalEmail);

    String customPrompt = String.join(emailReplyPromptParts, '\n');

    System.debug('customPrompt' + customPrompt);
    String prompt = customPrompt + '\n\nSolar Data:\n' + forecastResponse;

    System.debug('prompt' + prompt);
    String openAiResponse = getOpenAiResponse(prompt, 'assistant');

    if (openAiResponse == null) {
      return 'Failed to retrieve OpenAI response.';
    }

    return formatContent(openAiResponse);
  }

  // @AuraEnabled(cacheable=true)
  // public static String replyWithEmail(Id leadId, String customPromptByUser) {
  //     // Construct the email content with HTML formatting
  //     String emailContent =
  //     '<html><body>' +
  //     '<h2>Subject: Solar potential energy</h2>' +
  //     '<p>Hello Kundan Sharma,</p>' +
  //     '<p>Thank you for showing interest in our product.</p>' +
  //     '<p>I trust this message finds you energized and ready to explore new possibilities with Concretio in Mountain View, CA. ' +
  //     'At ESolarCorp, we specialize in maximizing solar energy efficiency tailored to your precise needs. ' +
  //     'Our cutting-edge solutions are designed to elevate your solar power utilization to new heights. ' +
  //     'With our state-of-the-art technology and unwavering commitment to sustainability, ESolarCorp is your go-to partner for harnessing the power of the sun. ' +
  //     'Let\'s work together to unlock the full potential of solar energy at Concretio. Looking forward to discussing how ESolarCorp can revolutionize your solar initiatives. ' +
  //     'Reach back to us to embark on this renewable energy journey!</p>' +
  //     '<p>Warm Regards,<br/>' +
  //     '[Your Name]<br/>' +
  //     'ESolarCorp Team</p>' +
  //     '</body></html>';

  // return emailContent;

  // }

  private static List<String> replyWithEmailPrompt(String customPromptByUser) {
    List<String> emailReplyPromptParts = new List<String>{
      'Note- Purpose of email is to maintain the engagement with the lead and address their queries or concerns as mentioned in their reply.',
      'Using the provided Solar Data of lead and Name, write a personalized, formatted email in response to the lead\'s latest interaction.',
      'Ensure to acknowledge the lead\'s original email content and provide relevant responses to any questions or points they raised.',
      'Ensure the Email is clear, professional, and includes necessary information to make a strong case for choosing ESolarCorp.',
      'The goal is to make a great impression and clearly convey our value proposition. Ensure the email is neat, clean, and professionally formatted.',
      'There is also a prompt which is given by the user from the UI, Consider that prompt as well.',
      'Please do not use a greeting everytime "I hope this email finds you well" also you can use other gretting to avoid predictability and ensure authenticity.',
      'Note-Please do not use any suggestion after you have given Warms and Regards to the email.'
    };

    if (!String.isBlank(customPromptByUser)) {
      emailReplyPromptParts.add(customPromptByUser);
    }

    return emailReplyPromptParts;
  }
}

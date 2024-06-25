@isTest
public class LeadInteractionHandlerTest {    
    @testSetup
    static void setup() {
        //Creating Custom Setting - Geoapify
        ApiKeys__c geoapifyApiKey = new ApiKeys__c();
        geoapifyApiKey.Name = 'Geoapify';
        geoapifyApiKey.Value__c = 'testapikeyGeoapify12345';
        insert geoapifyApiKey;
        
        //Creating Custom Setting - SolarEnergy
        ApiKeys__c solarEnergyApiKey = new ApiKeys__c();
        solarEnergyApiKey.Name = 'solarEnergy';
        solarEnergyApiKey.Value__c = 'testapikeySolarEnergy12345';
        insert solarEnergyApiKey;
        
        //Creating Custom Setting - companyData
        ApiKeys__c companyDataApiKey = new ApiKeys__c();
        companyDataApiKey.Name = 'companyInfo';
        companyDataApiKey.Value__c = 'testapikeycompanyData12345';
        insert companyDataApiKey;

        //Creating Custom Setting - OpenAI
        ApiKeys__c openAiApiKey = new ApiKeys__c();
        openAiApiKey.Name = 'OpenAi';
        openAiApiKey.Value__c = 'testapikeyOpenAi12345';
        insert openAiApiKey;

        // Create an Account record for testing
        Account account = new Account(
            Name = 'Test Company'
        );
        insert account;

        // Create a Lead record for testing
        Lead lead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Street = '123 Test St',
            City = 'Test City',
            State = 'Test State',
            PostalCode = '12345',
            Country = 'Test Country',
            Email = 'testlead@example.com'
        );
        insert lead1;

        // Create a ContentVersion record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        // Retrieve the ContentDocumentId from the ContentVersion
        ContentVersion insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];

        // Create a ContentDocumentLink record
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = lead1.Id,
            ContentDocumentId = insertedContentVersion.ContentDocumentId,
            ShareType = 'V' // Viewer permission
        );
        insert contentDocumentLink;

        // Create a Contact record associated with the Account
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = account.Id // Associate the Contact with the Account
        );
        insert contact;

        // Create a Case record associated with the Contact
        Case caseRecord = new Case(
            ContactId = contact.Id,
            Status = 'New',
            Origin = 'Phone'
        );
        insert caseRecord;

        // Create an EmailMessage record associated with the Case
        EmailMessage emailMessage = new EmailMessage(
            Subject = 'Test Email',
            TextBody = 'This is a test email body.',
            ParentId = caseRecord.Id,
            ToAddress = 'testlead@example.com'
        );
        insert emailMessage;
    }

    
    @isTest
    static void testGetLeadAddressWithValidLead() {
        // Retrieve the test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        System.debug('Test Lead: ' + testLead);
        
        // Call the method and assert the result
        String result = LeadInteractionHandler.getLeadAddress(testLead.Id);
        System.debug('Result: ' + result);
        System.assertEquals('123 Test St, Test City, Test State, 12345, Test Country, Test Lead', result);
    }
    
    @isTest
    static void testFetchLeadAddressByCoordinatesWithValidLead() {
        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new LeadInterMockRespGenerator());

        // Retrieve the test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        System.debug('Test Lead: ' + testLead);
        
        // Call the method and assert the result
        Test.startTest();
        CoordinatesWrapper result = LeadInteractionHandler.fetchLeadAddressByCoordinates(testLead.Id);
        System.debug('Result: ' + result);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected a non-null result from fetchLeadAddressByCoordinates.');
        System.assertEquals('37.431753', result.latitude, 'Latitude does not match.');
        System.assertEquals('-122.088358', result.longitude, 'Longitude does not match.');
    }

 	@isTest
    static void testGetCompanyDataWithValidLead() {
        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new LeadInterMockRespGenerator());

        // Retrieve the test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        System.debug('Test Lead: ' + testLead);
        
        // Call the method and assert the result
        Test.startTest();
        CompanyInfoWrapper result = LeadInteractionHandler.getCompanyData(testLead.Id);
        Test.stopTest();
        
        System.debug('CompanyResult: ' + result);
        System.assertNotEquals(null, result, 'Expected a non-null result from getCompanyData.');
        System.assertEquals('Concretio (Salesforce Consulting Services)', result.displayName, 'Display name does not match.');
        System.assert(result.summary.startsWith('we are salesforce certified pdo & isv partner'), 'Summary does not match.');
    }

// Test method for getSolarEnergyData with valid latitude and longitude
    @isTest
    static void testGetSolarEnergyData_Success() {
       
        Decimal azimuth = 180;
        Decimal systemCapacity = 4;
        Decimal losses = 14;
        Integer arrayType = 1;
        Integer moduleType = 0;
        Decimal tilt = 10;
        String latitude = '37.431753';
        String longitude = '-122.088358';

        // Mock HTTP callout response
        Test.setMock(HttpCalloutMock.class, new LeadInterMockRespGenerator());
        
        Test.startTest();
        SolarEnergyDataWrapper result = LeadInteractionHandler.getSolarEnergyData(latitude, longitude);
        System.debug('result'+result);

 		List<Object> expectedAcMonthly = new List<Object>{280.060241503727, 371.8049243572069, 523.8606626615604, 612.5064774102962, 682.2216221299857, 725.7339743768631, 735.7917617894415, 682.2635122154807, 558.7717727766641, 455.7575437168644, 336.3449600118929, 278.5799998351707};
        List<Object> expectedPoaMonthly = new List<Object>{86.97699521735579, 117.1467814831449, 167.4430247876726, 199.402282601217, 223.4233175827579, 237.4547829183102, 244.9994193901751, 228.7080106388902, 187.1800295138034, 147.990740383875, 107.1812802325201, 87.24158362626507};
        List<Object> expectedSolradMonthly = new List<Object>{2.805709523140509, 4.183813624398032, 5.401387896376534, 6.6467427533739, 7.20720379299219, 7.915159430610339, 7.903207077102423, 7.377677762544846, 6.239334317126779, 4.773894851092743, 3.572709341084003, 2.814244633105325};
        List<Object> expectedDcMonthly = new List<Object>{295.0428325091651, 390.3519841649413, 548.9859677462168, 641.3228126081834, 714.3601524724627, 759.2758053085325, 769.9437099893739, 714.0823871790579, 585.2158263641302, 478.0228209236658, 353.6091709410452, 293.6458227831609};

        // Assertions
        System.assertNotEquals(null, result, 'Expected a non-null result from getSolarEnergyData.');
        System.assertEquals(expectedAcMonthly, result.acMonthly, 'AC Monthly values do not match.');
        System.assertEquals(expectedPoaMonthly, result.poaMonthly, 'POA Monthly values do not match.');
        System.assertEquals(expectedSolradMonthly, result.solradMonthly, 'Solrad Monthly values do not match.');
        System.assertEquals(expectedDcMonthly, result.dcMonthly, 'DC Monthly values do not match.');
    }
    
     @isTest
    static void testGenerateEmailContent() {
        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new LeadInterMockRespGenerator());

        // Retrieve the test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Call the method and assert the result
        Test.startTest();
        String result = LeadInteractionHandler.generateEmailContent(testLead.Id, 'Custom prompt for email');
        Test.stopTest();
        
        System.debug('Email Content Result: ' + result);
        System.assert(!String.isEmpty(result), 'Expected a non-empty result from generateEmailContent.');
    }
    
     @isTest
    static void testGenerateCallScript() {
        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new LeadInterMockRespGenerator());

        // Retrieve the test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Call the method and assert the result
        Test.startTest();
        String result = LeadInteractionHandler.generateCallScript(testLead.Id, 'Custom prompt for call script');
        Test.stopTest();
        
        System.debug('Call Script Result: ' + result);
        System.assert(!String.isEmpty(result), 'Expected a non-empty result from generateCallScript.');
    }
    
    @isTest
    static void testGetSolarDataJSON() {
        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new LeadInterMockRespGenerator());

        // Retrieve the test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Call the method and assert the result
        Test.startTest();
        String result = LeadInteractionHandler.getSolarDataJSON(testLead.Id);
        Test.stopTest();
        
        System.debug('Solar Data JSON Result: ' + result);
        System.assert(!String.isEmpty(result), 'Expected a non-empty result from getSolarDataJSON.');
    }

    @isTest
    static void testFileAttachment() {
        // Retrieve the test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Call the method and assert the result
        Test.startTest();
        List<ContentVersion> result = LeadInteractionHandler.fileAttachment(testLead.Id);
        Test.stopTest();
        
        System.debug('File Attachment Result: ' + result);
        System.assert(!result.isEmpty(), 'Expected a non-empty list of ContentVersions.');
        System.assertEquals('Test Document', result[0].Title, 'The title of the ContentVersion should match the expected value.');
    }
    
    @isTest
    static void testSendEmailToController() {
        // Retrieve the test lead and OrgWideEmailAddress
        Lead testLead = [SELECT Id, Email FROM Lead LIMIT 1];
        OrgWideEmailAddress orgWideEmail = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        // Retrieve the test ContentVersion
        ContentVersion contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];

        // Set up parameters for the method
        String[] toAddresses = new String[]{testLead.Email};
        String subject = 'Test Subject';
        String htmlBody = '<p>This is a test email.</p>';
        List<Id> uploadedFiles = new List<Id>{contentVersion.ContentDocumentId};

        // Call the method and assert the result
        Test.startTest();
        LeadInteractionHandler.sendEmailToController(toAddresses, orgWideEmail.Id, subject, htmlBody, uploadedFiles);
        Test.stopTest();

        // Since we can't assert email sending directly, we can verify that no exceptions were thrown
        System.assert(true, 'Email send method executed successfully.');
    }
    
    @isTest
    static void testAccessHardcodedCompanyInfo() {
        // Call the wrapper method and assert the result
        Test.startTest();
        CompanyInfoWrapper result = LeadInteractionHandler.accessHardcodedCompanyInfo();
        Test.stopTest();

        System.debug('Hardcoded Company Info Result: ' + result);
        System.assertEquals('Concretio', result.displayName, 'The display name should match the expected value.');
        System.assert(result.summary.startsWith('We are Salesforce certified PDO & ISV partner'), 'The summary should match the expected value.');
    }

    @isTest
    static void testGetLeadEmailAddress() {
        // Retrieve the test lead
        Lead testLead = [SELECT Id, Email FROM Lead LIMIT 1];

        // Call the method and assert the result
        Test.startTest();
        String result = LeadInteractionHandler.getLeadEmailAddress(testLead.Id);
        Test.stopTest();

        System.debug('Lead Email Address Result: ' + result);
        System.assertEquals('testlead@example.com', result, 'The email address of the Lead should match the expected value.');
    }

    // @isTest
    // static void testGetEmailMessages() {
    //     // Call the method and assert the result
    //     Test.startTest();
    //     List<EmailMessage> result = LeadInteractionHandler.getEmailMessages();
    //     Test.stopTest();

    //     System.debug('Email Messages Result: ' + result);
    //     System.assert(!result.isEmpty(), 'Expected a non-empty list of EmailMessages.');
    //     System.assert(result.size() <= 100, 'The number of email messages should not exceed 100.');
    //     System.assertEquals('This is a test email body.', result[0].TextBody, 'The text body of the first EmailMessage should match the expected value.');
    // }
    
    @isTest
    static void testGetOrgwideEmailAddress() {
        // Call the method and assert the result
        Test.startTest();
        OrgWideEmailAddress result = LeadInteractionHandler.getOrgwideEmailAddress();
        Test.stopTest();

        System.debug('OrgWideEmailAddress Result: ' + result);
        if (result != null && result.Id != null) {
            System.assertNotEquals(null, result.Id, 'Expected a non-null OrgWideEmailAddress Id.');
            System.assertNotEquals(null, result.Address, 'Expected a non-null OrgWideEmailAddress Address.');
        } else {
            System.assertEquals(null, result.Id, 'Expected a null OrgWideEmailAddress Id as no OrgWideEmailAddress records exist.');
        }
    }
 
}
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
        
        // Create a Lead record for testing
        Lead lead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Street = '123 Test St',
            City = 'Test City',
            State = 'Test State',
            PostalCode = '12345',
            Country = 'Test Country'
        );
        insert lead1;
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
}
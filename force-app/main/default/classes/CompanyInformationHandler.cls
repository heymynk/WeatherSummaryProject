public class CompanyInformationHandler {

    @AuraEnabled(cacheable=true)
    public static CompanyInfoWrapper getCompanyData(Id leadId) {

        String companyInfoApiKey = getcompanyInfoAPIKey();
        System.debug('companyInfoApiKey' +companyInfoApiKey);

        Lead lead = [SELECT Company FROM Lead WHERE Id = :leadId LIMIT 1];
        String companyName = lead.Company;

        if (companyName == null) {
            System.debug('No company name found for the given Lead Id: ' + leadId);
            return null;
        }

        CompanyInfoWrapper companyData = null;

        String endpoint = 'https://api.peopledatalabs.com/v5/company/enrich?name=' + EncodingUtil.urlEncode(companyName, 'UTF-8') + '&pretty=false';
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
                // Process the response body as needed
                //System.debug('Response: ' + responseBody);

                // Parse the JSON response to extract display_name and summary
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                String displayName = (String) responseMap.get('display_name');
                String summary = (String) responseMap.get('summary');

                //System.debug('Display Name: ' + displayName);
                System.debug('Summary: ' + summary);

                companyData = new CompanyInfoWrapper(displayName, summary);
                //System.debug('companyData'+companyData);
            return companyData;

            } else {
                //System.debug('Failed with status code: ' + response.getStatusCode());
                //System.debug('Response: ' + response.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return null;
        }
    }

    private static String getcompanyInfoAPIKey() {
        ApiKeys__c companyInfoKeySettings = ApiKeys__c.getInstance('companyInfo'); 
        return companyInfoKeySettings != null ? companyInfoKeySettings.Value__c : null;
    }
}
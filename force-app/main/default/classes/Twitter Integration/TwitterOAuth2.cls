public class TwitterOAuth2 {

    // Method to retrieve access token
    public static String retrieveAccessToken() {
        // Fetch the custom metadata records
        List<Twitter_API_Setting__mdt> apiKeySettings = [SELECT API_Key__c FROM Twitter_API_Setting__mdt WHERE DeveloperName = 'API_Key' LIMIT 1];
        List<Twitter_API_Setting__mdt> apiSecretKeySettings = [SELECT Key_Secret__c FROM Twitter_API_Setting__mdt WHERE DeveloperName = 'Key_Secret' LIMIT 1];
        
        // Check if the settings are not null
        if (apiKeySettings.isEmpty() || apiSecretKeySettings.isEmpty()) {
            throw new OAuthException('API Key or Secret Key setting not found.');
        }
        
        // Fetch and encode API Key and Secret Key from custom metadata
        String API_Key = EncodingUtil.urlEncode(apiKeySettings[0].API_Key__c, 'UTF-8');
        String API_Secret_Key = EncodingUtil.urlEncode(apiSecretKeySettings[0].Key_Secret__c, 'UTF-8');      

        // Create the Consumer API key
        String Consumer_API_key = API_Key + ':' + API_Secret_Key;

        // Convert the Consumer API key to Blob
        Blob httpRequestHeader = Blob.valueOf(Consumer_API_key);
        System.debug('Twitter HeaderBlob ' + httpRequestHeader);        

        // Initialize HttpRequest
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.twitter.com/oauth2/token');
        req.setMethod('POST');        

        // Set the Authorization header
        String basicAuthorizationHeader = 'Basic ' + EncodingUtil.base64Encode(httpRequestHeader);
        req.setHeader('Authorization', basicAuthorizationHeader);
        req.setBody('grant_type=client_credentials');        
        System.debug('Twitter Http request ' + req);        

        // Send the request and get the response
        Http http = new Http();        
        HttpResponse res = http.send(req);
        String accessToken;        
        if(res.getStatusCode() == 200) {
            JSONParser parser = JSON.createParser(res.getBody());
            System.debug('Twitter JSON response ' + parser);
            while(parser.nextToken() != null) {
                if(parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'access_token') {
                    parser.nextToken();
                    accessToken = parser.getText();
                }
            }
        } else {
            System.debug('Failed to get access token. Status: ' + res.getStatus());
            System.debug('Response: ' + res.getBody());
            throw new OAuthException('Failed to retrieve access token. Status: ' + res.getStatus());
        }
        return accessToken;
    }

    // Custom exception class for OAuth related errors
    public class OAuthException extends Exception {}
}

public class TwitterOAuth {
    private static final String TOKEN_URL = 'https://api.twitter.com/oauth2/token';

    public static String getAccessToken() {
        System.debug('Starting process to get Twitter access token');
        try {
            Twitter_API_Setting__mdt settings = TwitterAuth.getTwitterSettings();
            System.debug('Twitter settings retrieved: ' + settings);
            
            String consumerKey = settings.Consumer_Key__c;
            String consumerSecret = settings.Consumer_Secret__c;
            System.debug('Consumer Key: ' + consumerKey);
            System.debug('Consumer Secret: ' + consumerSecret);

            String credentials = consumerKey + ':' + consumerSecret;
            String encodedCredentials = EncodingUtil.base64Encode(Blob.valueOf(credentials));
            System.debug('Encoded Credentials: ' + encodedCredentials);

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(TOKEN_URL);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Basic ' + encodedCredentials);
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded;charset=UTF-8');
            request.setBody('grant_type=client_credentials');

            System.debug('Sending HTTP request to Twitter');
            HttpResponse response = http.send(request);
            System.debug('HTTP response received: ' + response.getBody());

            if (response.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String accessToken = (String) result.get('access_token');
                System.debug('Access token retrieved: ' + accessToken);
                return accessToken;
            } else {
                System.debug('Error: HTTP response status code is not 200. Response: ' + response.getBody());
                throw new AuraHandledException('Error authenticating with Twitter: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while retrieving the access token: ' + e.getMessage());
        }
    }
}
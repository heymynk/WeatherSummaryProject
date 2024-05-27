public with sharing class TwitterServicesDirect {
    private static final String ACCESS_TOKEN = 'blRpeWpTZ2tHN1FTQ2hzWFdOWVlyZXVROTMzd0hHbFFkZlRmcVJLaE1FQldFOjE3MTY4MTQ3NzI4OTU6MTowOmF0OjE';
    private static final String REFRESH_TOKEN = 'X29ta01ZMTFqMkxJdk50RjVHeVBxTnNZWVlUVVc2Q1I1dVJEZ2RvRmxUTWo4OjE3MTY4MTQ3NzI4OTU6MToxOnJ0OjE';
    private static final String CLIENT_ID = 'WkE8tCi8jhOWMkSPnme3X7pz7';
    private static final String CLIENT_SECRET = 'jclvxMqSQqBFVRud3NMw79y1ntFKQQ1TySE2rfXOQPhtnIMmLM';
    private static final String TOKEN_URL = 'https://api.twitter.com/oauth2/token';
    private static final String TWEET_ENDPOINT = 'https://api.twitter.com/2/tweets';

    public static void postTweet(String tweet) {
        String accessToken = getAccessToken();
        if (accessToken == null) {
            throw new AuraHandledException('Error obtaining access token.');
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(TWEET_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setHeader('Content-Type', 'application/json');

        String body = JSON.serialize(new Map<String, String>{'text' => tweet});
        request.setBody(body);

        System.debug('Sending HTTP request to Twitter via Named Credential');
        System.debug('Request Endpoint: ' + request.getEndpoint());
        System.debug('Request Method: ' + request.getMethod());
        System.debug('Request Headers: ' + request.getHeader('Content-Type'));
        System.debug('Request Body: ' + request.getBody());

        try {
            HttpResponse response = http.send(request);
            System.debug('HTTP response received: ' + response.getBody());
            System.debug('HTTP response status: ' + response.getStatus());

            if (response.getStatusCode() == 201) {  // Twitter API v2 returns 201 on successful tweet creation
                System.debug('Tweet posted successfully');
            } else {
                System.debug('Error: HTTP response status code is not 201');
                System.debug('Error response: ' + response.getBody());
                throw new AuraHandledException('Error posting tweet: ' + response.getBody());
            }
        } catch (System.CalloutException e) {
            System.debug('CalloutException: ' + e.getMessage());
            throw new AuraHandledException('CalloutException: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException('Exception: ' + e.getMessage());
        }
    }

    private static String getAccessToken() {
        // Ideally, check if the current access token is expired before making a call to refresh it

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(TOKEN_URL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String body = 'grant_type=refresh_token&refresh_token=' + REFRESH_TOKEN +
                      '&client_id=' + CLIENT_ID + '&client_secret=' + CLIENT_SECRET;
        request.setBody(body);

        System.debug('Sending token refresh request');
        System.debug('Token refresh request body: ' + body);
        HttpResponse response = http.send(request);
        System.debug('Token refresh response received: ' + response.getBody());

        if (response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String newAccessToken = (String) result.get('access_token');
            System.debug('New access token: ' + newAccessToken);
            // Optionally, store the new access token back to Custom Metadata or Custom Setting
            return newAccessToken;
        } else {
            System.debug('Error refreshing token: ' + response.getBody());
            return null;
        }
    }
}

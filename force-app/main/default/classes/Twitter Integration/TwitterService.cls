public class TwitterService {
    private static final String NAMED_CREDENTIAL = 'Twitter_API';
    private static final String TWEET_ENDPOINT = '/2/tweets';

    public static void postTweet(String tweet) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + NAMED_CREDENTIAL + TWEET_ENDPOINT);
        request.setMethod('POST');
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

            if (response.getStatusCode() == 201) {
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
}

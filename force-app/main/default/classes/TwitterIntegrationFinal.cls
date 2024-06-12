public with sharing class TwitterIntegrationFinal {
    private static final String CONSUMER_KEY = 'Mj7qMsZa1LGmEnsbSLb9FNUEx';
    private static final String CONSUMER_SECRET = '405NgD3XsMa7JwOqviWISzsAjilIf3W1hFtzDUCFOGzNzcOd94';
    private static final String ACCESS_TOKEN = '1793159002483765248-SL6NqQElgLur46fWL4DjC7foCYJEmn';
    private static final String ACCESS_SECRET = '4SlytPlBUCwLwGSaXPl7QqGmHdLQ0FtCORY9gT7L6OHFc';
    private static final String TWITTER_API_URL = 'https://api.twitter.com/1.1/statuses/update.json';

    public static void postTweet(String status) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(TWITTER_API_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('status=' + EncodingUtil.urlEncode(status, 'UTF-8'));
        
        // Sign the request using OAuth
        req = OAuthTwitterFinal.signRequest(req, CONSUMER_KEY, ACCESS_TOKEN, CONSUMER_SECRET);
        
        // Send the request
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                System.debug('Tweet posted successfully: ' + res.getBody());
            } else {
                System.debug('Failed to post tweet. Status: ' + res.getStatus() + ', Response: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error while posting tweet: ' + e.getMessage());
        }
    }
}
public class Twitter {
    private String clientId = 'U2dGWmZZTnV2dzdlWUQ3QnVpdFQ6MTpjaQ';
    private String clientSecret = 'EzxJ5ukZNt0OaqtUNQi4xjqo0OhuG-NWrrut32cLMFz1fEI1DW';
    private String redirectUri = 'https://login.salesforce.com/';
    private String bearerToken;
    private String refreshToken;
    
    public Twitter(String bearerToken, String refreshToken) {
        this.bearerToken = bearerToken;
        this.refreshToken = refreshToken;
    }

    // Function to get user profile information 
    public Map<String, Object> getUserProfile() {
        String endpoint = 'https://api.twitter.com/2/users/me';
        HttpResponse response = sendGetRequest(endpoint);
        return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    }

     // Function to get recent tweets
    // public List<Object> getRecentTweets() {
    //     String endpoint = 'https://api.twitter.com/2/tweets';
    //     HttpResponse response = sendGetRequest(endpoint);
    //     Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    //     return (List<Object>) responseBody.get('data');
    // }

    // Function to post a tweet
    public Map<String, Object> postTweet(String tweetText) {
        String endpoint = 'https://api.twitter.com/2/tweets';
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('text', tweetText);
        HttpResponse response = sendPostRequest(endpoint, requestBody);
        return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    }

    // Function to refresh the bearer token
    public void refreshBearerToken() {
        String endpoint = 'https://api.twitter.com/oauth2/token';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String body = 'grant_type=refresh_token' +
                      '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
                      '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8') +
                      '&refresh_token=' + EncodingUtil.urlEncode(refreshToken, 'UTF-8') +
                      '&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8');
                      
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            this.bearerToken = (String) responseBody.get('access_token');
            this.refreshToken = (String) responseBody.get('refresh_token');
        } else {
            throw new CalloutException('Failed to refresh bearer token: ' + res.getStatus());
        }
    }

    // Helper function to send GET requests
    private HttpResponse sendGetRequest(String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + bearerToken);
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException('Failed to send GET request: ' + res.getStatus());
        }
        return res;
    }

    // Helper function to send POST requests
    private HttpResponse sendPostRequest(String endpoint, Map<String, Object> requestBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + bearerToken);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(requestBody));
        
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 201) {
            throw new CalloutException('Failed to send POST request: ' + res.getStatus());
        }
        return res;
    }
}

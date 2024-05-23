public class TwitterUtils {
    private String clientId = 'U2dGWmZZTnV2dzdlWUQ3QnVpdFQ6MTpjaQ';
    private String redirectUri = 'https://login.salesforce.com/';
    private String bearerToken;
    
    public TwitterUtils(String bearerToken) {
        this.bearerToken = bearerToken;
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
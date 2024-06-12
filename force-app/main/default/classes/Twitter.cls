public class Twitter {
    private String clientId = 'U2dGWmZZTnV2dzdlWUQ3QnVpdFQ6MTpjaQ';
    private String clientSecret = 'EzxJ5ukZNt0OaqtUNQi4xjqo0OhuG-NWrrut32cLMFz1fEI1DW';
    private String redirectUri = 'https://login.salesforce.com/';
    private String bearerToken;
    private String refreshToken;

    private String codeChallenge = generateRandomString();

    private String generateRandomString() {
        String allowedCharacters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
        Integer length = 64;
        String randomString = '';

        for (Integer i = 0; i < length; i++) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), allowedCharacters.length());
            randomString += allowedCharacters.charAt(randomIndex);
        }

        return randomString;
    }

    public Twitter(String bearerToken, String refreshToken) {
        this.bearerToken = bearerToken;
        this.refreshToken = refreshToken;
    }

    // Step 1: Construct an Authorize URL
    public String getAuthorizationUrl() {
        String scope = 'tweet.read users.read follows.read follows.write offline.access';
        String state = 'your_state_value';
        
        String authorizationUrl = 'https://twitter.com/i/oauth2/authorize?response_type=code'
            + '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8')
            + '&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8')
            + '&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8')
            + '&state=' + EncodingUtil.urlEncode(state, 'UTF-8')
            + '&code_challenge=' + EncodingUtil.urlEncode(codeChallenge, 'UTF-8')
            + '&code_challenge_method=plain';

        return authorizationUrl;
    }

    // Step 3: POST oauth2/token - Access Token
    public void getAccessToken(String authorizationCode) {
        String endpoint = 'https://api.twitter.com/2/oauth2/token';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String body = 'code=' + EncodingUtil.urlEncode(authorizationCode, 'UTF-8') +
                      '&grant_type=authorization_code' +
                      '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
                      '&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8') +
                      '&code_verifier=' + EncodingUtil.urlEncode(codeChallenge, 'UTF-8');

        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res;
        
        try {
            res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                this.bearerToken = (String) responseBody.get('access_token');
                this.refreshToken = (String) responseBody.get('refresh_token');
            } else {
                System.debug('Failed to get access token: ' + res.getStatus());
                System.debug('Response body: ' + res.getBody());
                throw new CalloutException('Failed to get access token: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Exception when getting access token: ' + e.getMessage());
            throw new CalloutException('Exception when getting access token: ' + e.getMessage());
        }
    }
    

    // // Step 4: Connect to the APIs
    // public Map<String, Object> getUserProfile() {
    //     String endpoint = 'https://api.twitter.com/2/users/me';
    //     HttpResponse response = sendGetRequest(endpoint);
    //     return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    // }

    // public List<Object> getRecentTweets() {
    //     String endpoint = 'https://api.twitter.com/2/tweets';
    //     HttpResponse response = sendGetRequest(endpoint);
    //     Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    //     return (List<Object>) responseBody.get('data');
    // }

    // public Map<String, Object> postTweet(String tweetText) {
    //     String endpoint = 'https://api.twitter.com/2/tweets';
    //     Map<String, Object> requestBody = new Map<String, Object>();
    //     requestBody.put('text', tweetText);
    //     HttpResponse response = sendPostRequest(endpoint, requestBody);
    //     return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    // }

    // // Step 5: POST oauth2/token - Refresh Token
    // public void refreshBearerToken() {
    //     String endpoint = 'https://api.twitter.com/2/oauth2/token';
    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint(endpoint);
    //     req.setMethod('POST');
    //     req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    //     req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(clientId + ':' + clientSecret)));
        
    //     String body = 'grant_type=refresh_token' +
    //                   '&refresh_token=' + EncodingUtil.urlEncode(refreshToken, 'UTF-8');
                      
    //     req.setBody(body);
        
    //     Http http = new Http();
    //     HttpResponse res;
        
    //     try {
    //         res = http.send(req);
            
    //         if (res.getStatusCode() == 200) {
    //             Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    //             this.bearerToken = (String) responseBody.get('access_token');
    //             this.refreshToken = (String) responseBody.get('refresh_token');
    //         } else {
    //             System.debug('Failed to refresh bearer token: ' + res.getStatus());
    //             System.debug('Response body: ' + res.getBody());
    //             throw new CalloutException('Failed to refresh bearer token: ' + res.getStatus());
    //         }
    //     } catch (Exception e) {
    //         System.debug('Exception when refreshing bearer token: ' + e.getMessage());
    //         throw new CalloutException('Exception when refreshing bearer token: ' + e.getMessage());
    //     }
    // }

    // // Step 6: POST oauth2/revoke - Revoke Token
    // public void revokeToken(String token) {
    //     String endpoint = 'https://api.twitter.com/2/oauth2/revoke';
    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint(endpoint);
    //     req.setMethod('POST');
    //     req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    //     req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(clientId + ':' + clientSecret)));
        
    //     String body = 'token=' + EncodingUtil.urlEncode(token, 'UTF-8');
        
    //     req.setBody(body);
        
    //     Http http = new Http();
    //     HttpResponse res;
        
    //     try {
    //         res = http.send(req);
            
    //         if (res.getStatusCode() != 200) {
    //             System.debug('Failed to revoke token: ' + res.getStatus());
    //             System.debug('Response body: ' + res.getBody());
    //             throw new CalloutException('Failed to revoke token: ' + res.getStatus());
    //         }
    //     } catch (Exception e) {
    //         System.debug('Exception when revoking token: ' + e.getMessage());
    //         throw new CalloutException('Exception when revoking token: ' + e.getMessage());
    //     }
    // }

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
global with sharing class GithubRegistrationHandler extends Auth.AuthProviderPluginClass {

    private String customMetadataTypeApiName = 'Github_Provider__mdt';
    public String redirectUrl; 
    private String key;
    private String secret;
    private String authUrl;  
    private String accessTokenUrl; 
    private String userInfoUrl; 
    private String scope;

    global String getCustomMetadataType() {
        return customMetadataTypeApiName;
    }

    /* Step 1 */
    global PageReference initiate(Map<string, string> authProviderConfiguration, String stateToPropagate) { 
        key = authProviderConfiguration.get('Consumer_Key__c');
        authUrl = authProviderConfiguration.get('Auth_Url__c');
        scope = authProviderConfiguration.get('Scope__c');
        redirectUrl = authProviderConfiguration.get('Callback_Url__c');
        String urlToRedirect = authUrl + '?client_id=' + key + '&redirect_uri=' + redirectUrl + '&scope=' + scope +
                               '&state=' + stateToPropagate + '&allow_signup=false';
                               
        PageReference pageRef = new PageReference(urlToRedirect);                    
        return pageRef; 
    } 

    /* Step 2 */
    global Auth.AuthProviderTokenResponse handleCallback(Map<string, string> authProviderConfiguration, Auth.AuthProviderCallbackState state) { 
        key = authProviderConfiguration.get('Consumer_Key__c'); 
        secret = authProviderConfiguration.get('Consumer_Secret__c'); 
        accessTokenUrl = authProviderConfiguration.get('Token_Url__c'); 
        redirectUrl = authProviderConfiguration.get('Callback_Url__c');
        
        Map<String, String> queryParams = state.queryParameters; 
        String code = queryParams.get('code'); 
        String sfdcState = queryParams.get('state'); 
        
        HttpRequest req = new HttpRequest(); 
        String requestBody = 'client_id=' + key + '&client_secret=' + secret + '&code=' + code
                             + '&redirect_uri=' + redirectUrl + '&state=' + sfdcState;
        req.setEndpoint(accessTokenUrl); 
        req.setHeader('Accept', 'application/json'); 
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setMethod('POST'); 
        req.setBody(requestBody);
        Http http = new Http(); 
        
        HTTPResponse res = http.send(req); 
        String responseBody = res.getBody(); 
        
        // Debug the raw response body
        System.debug('GitHub Token Response: ' + responseBody);
        
        GitHubWrapper wrapper;
        try {
            wrapper = (GitHubWrapper) System.JSON.deserialize(responseBody, GitHubWrapper.class);
        } catch (System.JSONException e) {
            System.debug('JSON Exception: ' + e.getMessage());
            throw new GithubException('Error deserializing GitHub token response: ' + e.getMessage());
        }
        
        return new Auth.AuthProviderTokenResponse('GithubRegistrationHandler', wrapper.access_token, 'refreshToken', sfdcState); 
    } 
   
    global Auth.UserData getUserInfo(Map<string, string> authProviderConfiguration, Auth.AuthProviderTokenResponse response) { 
        userInfoUrl = authProviderConfiguration.get('user_info_url__c');
        
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(userInfoUrl); // Use configured endpoint
        req.setHeader('Content-Type', 'application/json'); 
        req.setMethod('GET'); 
        req.setHeader('Authorization', 'Bearer ' + response.oauthToken);
        Http http = new Http(); 
        HTTPResponse res = http.send(req); 
        
        String responseBody = res.getBody();
        
        // Debug the raw response body
        System.debug('GitHub User Info Response: ' + responseBody);

        GithubUserWrapper userInfo;
        try {
            userInfo = (GithubUserWrapper) System.JSON.deserialize(responseBody, GithubUserWrapper.class);
        } catch (System.JSONException e) {
            System.debug('JSON Exception: ' + e.getMessage());
            throw new GithubException('Error deserializing GitHub user info response: ' + e.getMessage());
        }
        
        // Handling null values for fields
        String firstName = '';
        String lastName = '';
        if (userInfo.name != null) {
            List<String> nameInfo = userInfo.name.split(' ');
            if (nameInfo.size() > 0) firstName = nameInfo[0];
            if (nameInfo.size() > 1) lastName = nameInfo[1];
        }

        String email = userInfo.email != null ? userInfo.email : 'noemail@example.com'; // Default email if null

        Map<String, String> attributeMap = new Map<String, String>{'noauth' => 'NOUTHS'};
        Auth.UserData userdata = new Auth.UserData(userInfo.login, firstName, lastName, 
                 userInfo.name, email, userInfo.url, userInfo.login, 'en_US', 'Github', null, attributeMap );

        return userdata;
    } 

    global User createUser(Id portalId, Auth.UserData data) {
        User u = new User();
        Profile p = [SELECT Id FROM profile WHERE name='Standard User' LIMIT 1];
        // Ensure unique username
        u.username = data.username + '@momentumcustomization2515.com';
        u.email = data.email;
        u.lastName = data.lastName != null ? data.lastName : 'LastName';
        u.firstName = data.firstName != null ? data.firstName : 'FirstName';
        String alias = data.username;
        // Alias must be 8 characters or less
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.alias = alias;
        u.languagelocalekey = UserInfo.getLocale();
        u.localesidkey = UserInfo.getLocale();
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = 'America/Los_Angeles';
        u.profileId = p.Id;
        try {
            insert u;
            System.debug('User created: ' + u.Id);
        } catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage());
            throw new GithubException('Error creating user: ' + e.getMessage());
        }
        return u;
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        User u = new User(id=userId);
        u.email = data.email;
        u.lastName = data.lastName != null ? data.lastName : 'LastName';
        u.firstName = data.firstName != null ? data.firstName : 'FirstName';
        try {
            update u;
            System.debug('User updated: ' + u.Id);
        } catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage());
            throw new GithubException('Error updating user: ' + e.getMessage());
        }
    }
    
    public class GitHubWrapper {
        public String access_token; 
        public String scope;    
        public String token_type;
    }
    
    public class GithubUserWrapper {
        public String login;   
        public Integer id;  
        public String url;  
        public String html_url; 
        public String name; 
        public String company;  
        public String blog; 
        public String location;
        public String email;  
    }

    public class GithubException extends Exception {}
}
global class GithubSSOHandler implements Auth.RegistrationHandler {

    global User createUser(Id portalId, Auth.UserData data) {
        // Check if the user already exists
        User existingUser;
        try {
            existingUser = [SELECT Id FROM User WHERE Username = :data.username LIMIT 1];
        } catch (QueryException e) {
            // User does not exist, proceed to create a new user
        }

        if (existingUser != null) {
            // If user already exists, handle accordingly
            return existingUser;
        } else {
            // Create a new user
            User newUser = new User();
            newUser.Username = data.username + '@momentumcustomization2515.com';
            newUser.Email = data.email;
            newUser.FirstName = data.firstName != null ? data.firstName : 'DefaultFirstName';
            newUser.LastName = data.lastName != null ? data.lastName : 'DefaultLastName';
            newUser.CommunityNickname = data.username;
            newUser.Alias = data.username.substring(0, 5);
            newUser.TimeZoneSidKey = 'Asia/Kolkata';
            newUser.LocaleSidKey = 'en_IN';
            newUser.EmailEncodingKey = 'UTF-8';
            newUser.LanguageLocaleKey = 'en_US';

            // Set Profile ID to Standard Platform User
            try {
                newUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
            } catch (QueryException e) {
                throw new AuthException('Profile not found: Standard User');
            }

            // Ensure LastName is always populated
            if (newUser.LastName == null || newUser.LastName == '') {
                newUser.LastName = 'DefaultLastName';
            }

            try {
                insert newUser;
                System.debug('New user created: ' + newUser);
            } catch (DmlException e) {
                System.debug('DML Exception: ' + e.getMessage());
                throw new AuthException('User creation failed due to: ' + e.getMessage());
            }

            return newUser;
        }
    }

    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        // Update existing user details
        try {
            User existingUser = [SELECT Id, Email, FirstName, LastName FROM User WHERE Id = :userId];
            existingUser.Email = data.email;
            existingUser.FirstName = data.firstName != null ? data.firstName : existingUser.FirstName;
            existingUser.LastName = data.lastName != null ? data.lastName : existingUser.LastName;
            if (existingUser.LastName == null || existingUser.LastName == '') {
                existingUser.LastName = 'DefaultLastName';
            }
            update existingUser;
            System.debug('User updated: ' + existingUser);
        } catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage());
            throw new AuthException('User update failed due to: ' + e.getMessage());
        }
    }

    global Auth.UserData getUserInfo(Map<String, String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) { 
        String userInfoUrl = authProviderConfiguration.get('user_info_url__c');
        
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
            System.debug('JSON userInfo: ' + userInfo);

            throw new AuthException('Error deserializing GitHub user info response: ' + e.getMessage());
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

        System.debug('Auth.UserData created: ' + userdata);

        return userdata;
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

    public class AuthException extends Exception {}
}
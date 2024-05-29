public with sharing class LinkedinService {

    @AuraEnabled
    public static String getProfilePhoto() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Linkedin_Named_Cred/v2/me?projection=(id,profilePicture(displayImage~digitalmediaAsset:playableStreams))');
        request.setMethod('GET');

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                return response.getBody();
            } else {
                return 'Error: HTTP Status Code = ' + response.getStatusCode() + ', Response = ' + response.getBody();
            }
        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String postonLinkedIn(String author, String lifecycleState, String shareCommentary, String shareMediaCategory, String visibility) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Linkedin_Named_Cred/v2/ugcPosts');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        String requestBody = '{"author":"' + author + '","lifecycleState":"' + lifecycleState + '",' + 
                            '"specificContent":{"com.linkedin.ugc.ShareContent":{"shareCommentary":{"text":"' + shareCommentary + 
                            '"},"shareMediaCategory":"' + shareMediaCategory + '"}},"visibility":{"com.linkedin.ugc.MemberNetworkVisibility":"' + visibility + '"}}';
        request.setBody(requestBody);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 201) {
                return response.getBody();
            } else {
                return 'Error: HTTP Status Code = ' + response.getStatusCode() + ', Response = ' + response.getBody();
            }
        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String getUserInformation() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Linkedin_Named_Cred/v2/userinfo');
        request.setMethod('GET');

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                return response.getBody();
            } else {
                return 'Error: HTTP Status Code = ' + response.getStatusCode() + ', Response = ' + response.getBody();
            }
        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String uploadMedia() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Linkedin_Named_Cred/v2/assets?action=registerUpload');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        String requestBody = '{"registerUploadRequest":{"owner":"urn:li:person:oLL5giqIwt","recipes":["urn:li:digitalmediaRecipe:feedshare-image"],"serviceRelationships":[{"relationshipType":"OWNER","identifier":"urn:li:userGeneratedContent"}]}}';
        request.setBody(requestBody);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 201) {
                return response.getBody();
            } else {
                return 'Error: HTTP Status Code = ' + response.getStatusCode() + ', Response = ' + response.getBody();
            }
        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String shareMedia() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Linkedin_Named_Cred/v2/ugcPosts');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        String requestBody = '{"author":"urn:li:person:oLL5giqIwt","lifecycleState":"PUBLISHED","specificContent":{"com.linkedin.ugc.ShareContent":{"shareCommentary":{"text":"Hello, this is a test share."},"shareMediaCategory":"IMAGE","media":[{"status":"READY","description":{"text":"Check out the image"},"media":"urn:li:digitalmediaAsset:D5622AQEMMtBVQP_vKA"}]}},"visibility":{"com.linkedin.ugc.MemberNetworkVisibility":"PUBLIC"}}';
        request.setBody(requestBody);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 201) {
                return response.getBody();
            } else {
                return 'Error: HTTP Status Code = ' + response.getStatusCode() + ', Response = ' + response.getBody();
            }
        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
    }
}

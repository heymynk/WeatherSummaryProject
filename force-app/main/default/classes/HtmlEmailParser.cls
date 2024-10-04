/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 10-04-2024
 * @last modified by  : Mayank Singh
**/
public class HtmlEmailParser {

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLatestEmailDetails(String leadId) {
        Map<String, String> emailDetails = new Map<String, String>();
        try {
            // Query the latest EmailMessage related to the Lead
            String leadEmail = getLeadEmailAddress(leadId);
            System.debug('Lead Email Address: ' + leadEmail);
            
            EmailMessage latestEmail = [SELECT Id, HtmlBody, Subject, FromAddress, ToAddress, CreatedDate 
                                        FROM EmailMessage 
                                        WHERE ToAddress = :leadEmail OR FromAddress = :leadEmail 
                                        ORDER BY CreatedDate DESC 
                                        LIMIT 1];
            
            if (latestEmail != null) {
                System.debug('Latest Email found: ' + latestEmail.Id);
                
                // Get the HTML body from the EmailMessage
                String htmlBody = latestEmail.HtmlBody;
                System.debug('HTML Body: ' + htmlBody);
                
                // Extract user reply and original email
                String userReply = HtmlEmailParser.extractUserReply(htmlBody);
                String originalEmail = HtmlEmailParser.extractOriginalEmail(htmlBody);
                System.debug('User Reply: ' + userReply);
                System.debug('Original Email: ' + originalEmail);
                
                // Add details to the map
                emailDetails.put('userReply', userReply);
                emailDetails.put('originalEmail', originalEmail);
                emailDetails.put('subject', latestEmail.Subject);
                emailDetails.put('fromAddress', latestEmail.FromAddress);
                emailDetails.put('toAddress', latestEmail.ToAddress);
                emailDetails.put('createdDate', latestEmail.CreatedDate.format());
            } else {
                emailDetails.put('error', 'No EmailMessage found for the provided Lead ID.');
                System.debug('No EmailMessage found for the provided Lead ID.');
            }
        } catch (Exception e) {
            emailDetails.put('error', 'Exception: ' + e.getMessage());
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return emailDetails;
    }
    

    @AuraEnabled(cacheable=true)
    public static String getLeadEmailAddress(String leadRecordId) {
        Lead lead = [SELECT Id, Email FROM Lead WHERE Id = :leadRecordId LIMIT 1];
        return lead.Email;
    }

    public static String extractUserReply(String htmlBody) {
        try {
            // Define the marker for the start of the quoted email
            String marker = '<div class="gmail_quote">';
            
            // Find the index of the marker
            Integer markerIndex = htmlBody.indexOf(marker);
            
            if (markerIndex != -1) {
                // Extract the user reply part before the quoted email
                String userReply = htmlBody.substring(0, markerIndex);
                return removeHtmlTags(userReply).trim();
            }

            // If no marker is found, return the entire HTML body without tags
            return removeHtmlTags(htmlBody).trim();
        } catch (Exception e) {
            // Handle any exceptions and return an empty string
            return '';
        }
    }

    public static String extractOriginalEmail(String htmlBody) {
        try {
            // Define the marker for the start of the quoted email
            String marker = '<div class="gmail_quote">';
            
            // Find the index of the marker
            Integer markerIndex = htmlBody.indexOf(marker);
            
            if (markerIndex != -1) {
                // Extract the original email part from the marker onward
                String originalEmail = htmlBody.substring(markerIndex);
                return removeHtmlTags(originalEmail).trim();
            }

            // If no marker is found, return an empty string
            return '';
        } catch (Exception e) {
            // Handle any exceptions and return an empty string
            return '';
        }
    }

    private static String removeHtmlTags(String html) {
        // Remove HTML tags from the string using regex
        return html.replaceAll('<[^>]*>', '');
    }
}

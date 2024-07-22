public with sharing class HtmlEmailParser {
    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getLatestEmailMessageInActivityTimeline(String leadId) {
        String leadEmail = getLeadEmailAddress(leadId);
        OrgwideEmailAddress orgwideEmail = getOrgwideEmailAddress();
        List<EmailMessage> emailMessages = new List<EmailMessage>();
        
        try {
            emailMessages = [
                SELECT Id, CreatedDate, ToAddress, FromAddress, HtmlBody, TextBody,Subject
                FROM EmailMessage 
                WHERE (ToAddress LIKE :('%' + leadEmail + '%') AND FromAddress LIKE :('%' + orgwideEmail.Address + '%'))

                ORDER BY CreatedDate DESC LIMIT 3
            ];
        } catch (Exception e) {
            System.debug('Error occurred while retrieving email messages: ' + e.getMessage());
        }
        
        return emailMessages;
    }

    @AuraEnabled(cacheable=true)
    public static String getLeadEmailAddress(String leadRecordId) {
        Lead lead = [SELECT Id, Email FROM Lead WHERE Id = :leadRecordId LIMIT 1];
        return lead.Email;
    }

    @AuraEnabled(cacheable=true)
    public static OrgwideEmailAddress getOrgwideEmailAddress() {
        OrgwideEmailAddress orgwideEmail;
        if (Schema.sObjectType.OrgWideEmailAddress.isAccessible()) {
            orgwideEmail = [
                SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1
            ];
        } else {
            orgwideEmail = new OrgwideEmailAddress();
        }
        return orgwideEmail;
    }
}


public with sharing class EmailController {




    @AuraEnabled(cacheable = true)
    public static List<Folder> getEmailTemplateFolders() {
        System.debug('getEmailTemplateFolders called');
        List<Folder> emailTempFolderLists = [SELECT Id, Name, Type FROM Folder WHERE Name = 'ESolarCorp'];
        System.debug('Number of Email Template Folders found: ' + emailTempFolderLists.size());
        return emailTempFolderLists;
    }




    @AuraEnabled(cacheable = true)
    public static List<EmailTemplate> getEmailTemplates(String folderName) {
        System.debug('getEmailTemplates called with folderName: ' + folderName);
        List<EmailTemplate> emailTempLists = new List<EmailTemplate>();




        try {
            List<Folder> emailTempFolderList = [
                SELECT Id, Name, Type FROM Folder WHERE Name = :folderName = 'ESolarCorp'];




            if (!emailTempFolderList.isEmpty()) {
                emailTempLists = [
                    SELECT Id, Name, FolderId, HtmlValue, Subject FROM EmailTemplate WHERE FolderId = :emailTempFolderList[0].Id
                ];
                System.debug('HtmlValue: ' + emailTempLists[0].HtmlValue);
                System.debug('Number of Email Templates found: ' + emailTempLists.size());
            } else {
                System.debug('Folder not found: ' + folderName);
            }
        } catch (Exception ex) {
            System.debug('Error in getEmailTemplates: ' + ex.getMessage());
        }




        return emailTempLists;
    }




    @AuraEnabled(cacheable = true)
    public static String getLeadEmailAddress(String leadRecordId) {
        System.debug('getLeadEmailAddress called with leadRecordId: ' + leadRecordId);
        Lead lead = [SELECT Id, Email FROM Lead WHERE Id = :leadRecordId LIMIT 1];
        return lead.Email;
    }




    @AuraEnabled(cacheable = true)
    public static OrgwideEmailAddress getOrgwideEmailAddress() {
        System.debug('getOrgwideEmailAddress called');
        OrgwideEmailAddress orgwideEmail = [
            SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1
        ];
        System.debug('getOrgwideEmailAddress returning: ' + orgwideEmail);
        return orgwideEmail;
    }




    @AuraEnabled(cacheable = true)
    public static void sendEmailToController(String[] toAddressEmail, Id orgwideEmailAddress, String subjectEmail, String emailHtmlValue, List<Id> uploadedFiles) {
        System.debug('sendEmailToController called');
   
        if (toAddressEmail.isEmpty()) {
            // Handle case where no to addresses are provided
            System.debug('No "to" addresses provided');
            return;
        }
   
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddressEmail);
        System.debug('toAddressEmail: ' + toAddressEmail);
        email.setOrgWideEmailAddressId(orgwideEmailAddress);
        System.debug('orgwideEmailAddress: ' + orgwideEmailAddress);
        email.setSubject(subjectEmail);
        System.debug('subjectEmail: ' + subjectEmail);
        email.setHtmlBody(emailHtmlValue);
        System.debug('emailHtmlValue: ' + emailHtmlValue);
   
        if (uploadedFiles != null && !uploadedFiles.isEmpty()) {
            List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>();
            for (Id contentDocumentId : uploadedFiles) {
                ContentVersion contentVersion = getContentVersion(contentDocumentId);
                if (contentVersion != null) {
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(contentVersion.Title + '.' + contentVersion.FileType);
                    efa.setBody(contentVersion.VersionData);
                    emailFileAttachments.add(efa);
                } else {
                    System.debug('ContentVersion not found for Id: ' + contentDocumentId);
                }
            }
            email.setFileAttachments(emailFileAttachments);
        }
   
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            System.debug('Email sent successfully');
        } catch (Exception ex) {
            System.debug('Error sending email: ' + ex.getMessage());
            // Handle email sending errors (e.g., logging, notifications)
        }
    }
   




    @AuraEnabled(cacheable = true)
    public static List<ContentVersion> fileAttachment(String leadRecordId) {
        System.debug('leadRecordId: ' + leadRecordId);
        System.debug('fileAttachment=======');




        List<ContentVersion> conVer = new List<ContentVersion>();
        try {
            // First, get the ContentDocumentIds related to the Lead record
            List<ContentDocumentLink> contentDocumentLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :leadRecordId
            ];




            // Collect all ContentDocumentIds into a set
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink cdl : contentDocumentLinks) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }




            // Query ContentVersion using the set of ContentDocumentIds
            if (!contentDocumentIds.isEmpty()) {
                conVer = [
                    SELECT Id, ContentDocumentId, Title
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocumentIds
                ];
            }
        } catch (Exception ex) {
            System.debug('Error retrieving attachments for lead ' + leadRecordId + ': ' + ex.getMessage());
        }
        return conVer;
    }




    private static ContentVersion getContentVersion(Id contentDocumentId) {
        return [
            SELECT Id, Title, FileType, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            ORDER BY VersionNumber DESC
            LIMIT 1
        ];
    }
}

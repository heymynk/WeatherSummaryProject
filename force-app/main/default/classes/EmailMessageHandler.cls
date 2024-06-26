public with sharing class EmailMessageHandler {
    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getEmailMessages(String leadEmail) {
        return [
            SELECT Id, CreatedDate, FromAddress, ReplyToEmailMessageId, TextBody, ToAddress
            FROM EmailMessage
            WHERE ToAddress = :leadEmail
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }
    
    
    
}

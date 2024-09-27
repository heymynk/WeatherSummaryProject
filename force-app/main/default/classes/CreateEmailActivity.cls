/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 09-27-2024
 * @last modified by  : Mayank Singh
**/
global class CreateEmailActivity implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        // Create an instance of InboundEmailResult
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            String fromAddr = email.fromAddress;
            System.debug('From Address: ' + fromAddr);
            
            // Query for Lead record using email address
            Lead leadEmail = [SELECT Id, Email, Lead_Response__c FROM Lead WHERE Email = :fromAddr LIMIT 1];
            
            if (leadEmail == null) {
                result.success = false;
                result.message = 'No lead found for email address: ' + fromAddr;
                System.debug('No lead found for email address: ' + fromAddr);
                return result;
            }
            
            System.debug('Lead found: ' + leadEmail);
            
            // Process the email body and subject
            String emailBody = email.plainTextBody;
            String emailSubject = email.subject;
            
            // Prepare attachments for email
            List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
            
            if (email.binaryAttachments != null && !email.binaryAttachments.isEmpty()) {
                for (Messaging.InboundEmail.BinaryAttachment binAtt : email.binaryAttachments) {
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(binAtt.fileName);
                    efa.setBody(binAtt.body);
                    attachmentList.add(efa);
                }
            }
            
            System.debug('Attachments processed: ' + attachmentList);
            
            // Update Lead Response field based on current state
            if (leadEmail.Lead_Response__c == 'Working - Contacted') {
                // Update to "Working - Reply" after receiving email reply from the lead
                System.debug('Updating Lead_Response__c from Working - Contacted to Working - Reply');
                leadEmail.Lead_Response__c = 'Working - Reply';
            }
            
            update leadEmail;
            
            // Forward the email and save it as an activity on the Lead
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(new String[] { UserInfo.getUserEmail() });
            message.setReplyTo('esolarcorp_email_service@t-2tw8qj2trynxrvktpo2nzr0kdje70zfp2u66nzqnrh16ygu3ar.c1-1fdgbmak.ind16s.apex.sandbox.salesforce.com'); // Replace with your reply-to email address
            message.setSubject(String.isNotBlank(emailSubject) ? emailSubject : 'No Subject');
            message.setPlainTextBody(String.isNotBlank(emailBody) ? emailBody : 'No Body');
            
            if (email.htmlBody != null) {
                message.setHtmlBody(email.htmlBody);
            }
            
            if (!attachmentList.isEmpty()) {
                message.setFileAttachments(attachmentList);
            }
            
            message.setSaveAsActivity(true);
            message.setTreatTargetObjectAsRecipient(true);
            message.setTargetObjectId(leadEmail.Id);
            
            System.debug('Email message prepared: ' + message);
            
            // Send email
            if (!Test.isRunningTest()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
                
                if (results[0].success) {
                    System.debug('Email sent and saved as activity successfully.');
                    result.success = true;
                } else {
                    System.debug('Failed to send email: ' + results[0].errors[0].message);
                    
                    result.success = false;
                    result.message = 'Failed to send email: ' + results[0].errors[0].message;
                }
            } else {
                result.success = true;
                System.debug('Email sending skipped in test context.');
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error processing inbound email: ' + e.getMessage();
            
            System.debug('Exception: ' + e.getMessage());
            System.debug('Exception stack trace: ' + e.getStackTraceString());
        }
        
        return result;
    }

    @AuraEnabled
    public static void sendOutboundEmail(String leadId, String toEmailAddress, String subject, String body) {
        try {
            // Create email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { toEmailAddress });
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setSenderDisplayName('Salesforce Support');
            email.setReplyTo('your-reply-to-email@example.com');
            
            // Send email
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            if (results[0].success) {
                // Update Lead_Response__c field to "Working - Contacted" after sending initial email
                Lead lead = [SELECT Id, Lead_Response__c FROM Lead WHERE Id = :leadId LIMIT 1];
                lead.Lead_Response__c = 'Working - Contacted';
                update lead;
            } else {
                throw new EmailException('Failed to send email: ' + results[0].errors[0].message);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }
    
    public class EmailException extends Exception {}
}

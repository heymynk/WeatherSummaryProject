/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 11-01-2024
 * @last modified by  : Mayank Singh
**/
public class EmailMessageHandler {

    public static void updateLeadStatusOnEmailSent(List<EmailMessage> emailMessages) {
        Set<String> emailAddressesToUpdate = new Set<String>();
        System.debug('EmailMessages received: ' + emailMessages);

        for (EmailMessage email : emailMessages) {
            if (email != null) {
                // Check if the email was sent and has a valid ToEmailAddress
                System.debug('Processing EmailMessage Id: ' + email.Id + ', Status: ' + email.Status + ', ToEmailAddress: ' + email.ToAddress);

                if (email.Status != null && email.Status == '3' && email.ToAddress != null) {
                    System.debug('EmailMessage sent to: ' + email.ToAddress);
                    emailAddressesToUpdate.add(email.ToAddress);
                } else {
                    System.debug('EmailMessage does not meet criteria for update. EmailMessage Id: ' + email.Id);
                }
            } else {
                System.debug('EmailMessage is null.');
            }
        }

        if (!emailAddressesToUpdate.isEmpty()) {
            System.debug('Email addresses to update: ' + emailAddressesToUpdate);
            List<Lead> leadsToUpdate = [SELECT Id, Lead_Response__c FROM Lead WHERE Email IN :emailAddressesToUpdate];
            System.debug('Leads fetched for update: ' + leadsToUpdate);

            for (Lead lead : leadsToUpdate) {
                lead.Lead_Response__c = 'Working - Contacted'; // Update to your desired value
                System.debug('Updating Lead Id: ' + lead.Id + ' to status: Working - Contacted');
            }

            try {
                update leadsToUpdate;
                System.debug('Leads updated successfully.');
            } catch (DmlException e) {
                System.debug('Error updating leads: ' + e.getMessage());
            }
        } else {
            System.debug('No email addresses to update.');
        }
    }

    
    public static void updateLeadStatusOnEmailReply(List<EmailMessage> emailMessages) {
        Set<String> emailAddressesToUpdate = new Set<String>();
        System.debug('EmailMessages received: ' + emailMessages);
    
        for (EmailMessage email : emailMessages) {
            if (email != null) {
                // Check if the email was a reply and has a valid FromEmailAddress
                System.debug('Processing EmailMessage Id: ' + email.Id + ', Status: ' + email.Status + ', FromEmailAddress: ' + email.FromAddress);
    
                if (email.Status != null && email.Status == '2' && email.FromAddress != null) { // Assuming Status '2' indicates a reply
                    System.debug('EmailMessage reply from: ' + email.FromAddress);
                    emailAddressesToUpdate.add(email.FromAddress);
                } else {
                    System.debug('EmailMessage does not meet criteria for reply update. EmailMessage Id: ' + email.Id + ', Status: ' + email.Status + ', FromEmailAddress: ' + email.FromAddress);
                }
            } else {
                System.debug('EmailMessage is null.');
            }
        }
    
        if (!emailAddressesToUpdate.isEmpty()) {
            System.debug('Email addresses to update from replies: ' + emailAddressesToUpdate);
            List<Lead> leadsToUpdate = [SELECT Id, Lead_Response__c FROM Lead WHERE Email IN :emailAddressesToUpdate];
            System.debug('Leads fetched for reply update: ' + leadsToUpdate);
    
            for (Lead lead : leadsToUpdate) {
                lead.Lead_Response__c = 'Working - Replied'; // Update to your desired value
                System.debug('Updating Lead Id: ' + lead.Id + ' to status: Working - Replied');
            }
    
            try {
                update leadsToUpdate;
                System.debug('Leads updated successfully.');
            } catch (DmlException e) {
                System.debug('Error updating leads: ' + e.getMessage());
            }
        } else {
            System.debug('No email addresses to update from replies.');
        }
    }
    
}

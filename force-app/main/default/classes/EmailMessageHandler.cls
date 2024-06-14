public class EmailMessageHandler {

    public static void updateLeadStatusOnEmailSent(List<EmailMessage> emailMessages) {
        Set<Id> leadIdsToUpdate = new Set<Id>();
        System.debug('EmailMessages received: ' + emailMessages);

        for (EmailMessage email : emailMessages) {
            if (email != null) {
                // Check if the email was sent and related to a Lead via Related_Lead__c field
                System.debug('Processing EmailMessage Id: ' + email.Id + ', Status: ' + email.Status + ', Related_Lead__c: ' + email.Related_Lead__c);

                if (email.Status != null && email.Status == '3' && email.Related_Lead__c != null) {
                    System.debug('EmailMessage related to Lead found. EmailMessage Id: ' + email.Id + ', Related_Lead__c: ' + email.Related_Lead__c);
                    leadIdsToUpdate.add(email.Related_Lead__c);
                } else {
                    System.debug('EmailMessage not related to Lead or status not Sent. EmailMessage Id: ' + email.Id);
                }
            } else {
                System.debug('EmailMessage is null.');
            }
        }

        if (!leadIdsToUpdate.isEmpty()) {
            System.debug('Lead IDs to update: ' + leadIdsToUpdate);
            List<Lead> leadsToUpdate = [SELECT Id, Lead_Response__c FROM Lead WHERE Id IN :leadIdsToUpdate];
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
            System.debug('No Lead IDs to update.');
        }
    }

    public static void updateLeadStatusOnEmailReply(List<EmailMessage> emailMessages) {
        Set<Id> leadIdsToUpdate = new Set<Id>();
        System.debug('EmailMessages received: ' + emailMessages);

        for (EmailMessage email : emailMessages) {
            if (email != null) {
                // Check if the email is a reply and related to a Lead via Related_Lead__c field
                System.debug('Processing EmailMessage Id: ' + email.Id + ', Status: ' + email.Status + ', Related_Lead__c: ' + email.Related_Lead__c);

                if (email.Incoming && email.Status != null && email.Related_Lead__c != null) {
                    System.debug('Incoming EmailMessage related to Lead found. EmailMessage Id: ' + email.Id + ', Related_Lead__c: ' + email.Related_Lead__c);
                    leadIdsToUpdate.add(email.Related_Lead__c);
                } else {
                    System.debug('EmailMessage not related to Lead or not Incoming. EmailMessage Id: ' + email.Id);
                }
            } else {
                System.debug('EmailMessage is null.');
            }
        }

        if (!leadIdsToUpdate.isEmpty()) {
            System.debug('Lead IDs to update: ' + leadIdsToUpdate);
            List<Lead> leadsToUpdate = [SELECT Id, Lead_Response__c FROM Lead WHERE Id IN :leadIdsToUpdate];
            System.debug('Leads fetched for update: ' + leadsToUpdate);

            for (Lead lead : leadsToUpdate) {
                lead.Lead_Response__c = 'Working - Reply/Call'; // Update to your desired value
                System.debug('Updating Lead Id: ' + lead.Id + ' to status: Working - Reply/Call');
            }

            try {
                update leadsToUpdate;
                System.debug('Leads updated successfully.');
            } catch (DmlException e) {
                System.debug('Error updating leads: ' + e.getMessage());
            }
        } else {
            System.debug('No Lead IDs to update.');
        }
    }
}

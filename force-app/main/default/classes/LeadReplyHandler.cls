global class LeadReplyHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            // Find the lead based on the email address
            Lead lead = [SELECT Id, Email FROM Lead WHERE Email = :envelope.fromAddress LIMIT 1];
            
            if (lead != null) {
                // Create a task to log the email response
                Task t = new Task();
                t.Subject = 'Lead Response: ' + email.subject;
                t.Description = email.plainTextBody;
                t.OwnerId = UserInfo.getUserId();
                t.WhatId = lead.Id;
                insert t;
                
                // Optionally update the lead record with the response
                // lead.Custom_Response_Field__c = email.plainTextBody;
                // update lead;
            }
        } catch (Exception e) {
            System.debug('Error processing inbound email: ' + e.getMessage());
        }
        
        result.success = true;
        return result;
    }
}

global class ReplyEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            // Create a new Task to log the email reply
            Task task = new Task();
            task.Subject = 'Email Reply: ' + email.subject;
            task.Description = email.plainTextBody;
            task.Status = 'Completed';
            task.Priority = 'Normal';
            task.ActivityDate = Date.today();
            
            // Optionally, relate this task to a specific record (like a Lead, Contact, or Case)
            // Example: task.WhatId = someRecordId;

            insert task;
            result.success = true;
        } catch (Exception e) {
            System.debug('Exception in handleInboundEmail: ' + e.getMessage());
            result.success = false;
        }
        
        return result;
    }
}
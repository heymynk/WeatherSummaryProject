
global class EmailHandlerInbound implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        // Create an instance of InboundEmailResult

                Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
                try {
                    String fromAddr = email.fromAddress;
                    System.debug('fromAddr: ' + fromAddr);
                    
                    // Query for Lead record using email address
                    Lead leadEmail = [SELECT Id, Email, Lead_Response__c FROM Lead WHERE Email = :fromAddr LIMIT 1];
                    if (leadEmail == null) {
                        result.success = false;
                        result.message = 'No lead found for email address: ' + fromAddr;
                        System.debug('No lead found for email address: ' + fromAddr);
                        return result;
                    }
                    System.debug('leadEmail: ' + leadEmail);
                    
                    // Update Lead Response field to "Working - Reply"
                    System.debug('Updating Lead_Response__c from ' + leadEmail.Lead_Response__c + ' to Working - Reply');
                    leadEmail.Lead_Response__c = 'Working - Reply';
        
                    update leadEmail;
                    
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
        
                    // Forward the email and save it as an activity on the Lead
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setToAddresses(new String[] { UserInfo.getUserEmail() });
                    //message.setReplyTo('esolarcorp_email_service@2z44w6hzvpw0whp3369j44g37ghjwwreyv2w5ujftu5fq7wykk.c1-11nfdmaa.ind16s.apex.sandbox.salesforce.com');
                    message.setSubject(emailSubject != null ? emailSubject : 'No Subject');
                    message.setPlainTextBody(emailBody != null ? emailBody : 'No Body');
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
        }
        
        
    

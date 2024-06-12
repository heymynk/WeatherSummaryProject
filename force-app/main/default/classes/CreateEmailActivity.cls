global class CreateEmailActivity implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        try {
            // Debug log for inbound email and envelope
            System.debug('Inbound Email: ' + email);
            System.debug('Inbound Envelope: ' + envelope);

            // Initialize lists
            List<Lead> leads = new List<Lead>();
            List<Attachment> attachments = new List<Attachment>();
            List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
            List<String> toEmailAddresss = new List<String>();
            List<String> ccEmailAddresss = new List<String>();

            // Debug log for initialized lists
            System.debug('Initialized lists for leads, attachments, and email addresses.');

            // Extract email details
            String senderName = email.fromName;
            String fromEmailAddress = email.fromAddress;
            toEmailAddresss = email.toAddresses;
            ccEmailAddresss = email.ccAddresses;

            // Debug log for email details
            System.debug('Sender Name: ' + senderName);
            System.debug('From Email Address: ' + fromEmailAddress);
            System.debug('To Email Addresses: ' + toEmailAddresss);
            System.debug('CC Email Addresses: ' + ccEmailAddresss);

            // Query leads
            leads = [SELECT Id FROM Lead WHERE Email = :fromEmailAddress LIMIT 1];
            System.debug('Queried Leads: ' + leads);

            // Extract email body and subject
            String htmlBody = email.htmlBody;
            String taskSubject = email.subject;

            // Debug log for email body and subject
            System.debug('Email Subject: ' + taskSubject);
            System.debug('HTML Body: ' + htmlBody);

            // Extract verification link from email body
            String verificationLink = extractVerificationLink(htmlBody);
            System.debug('Verification Link: ' + verificationLink);

            Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = email.binaryAttachments;

            if (leads.size() > 0) {
                System.debug('Leads found. Proceeding with forwarding the email.');
                
                /****************** Forward mail to current user ******************************/
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                if (binaryAttachments != null && binaryAttachments.size() > 0) {
                    for (Integer i = 0; i < binaryAttachments.size(); i++) {
                        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                        attach.filename = binaryAttachments[i].filename;
                        attach.body = binaryAttachments[i].body;
                        attachmentList.add(attach);
                    }
                    System.debug('Binary Attachments processed: ' + attachmentList);
                }

                // Set email message details
                List<String> toAddress = new List<String>();
                toAddress.add(UserInfo.getUserEmail());
                if (attachmentList.size() > 0) {
                    message.setFileAttachments(attachmentList);
                }
                message.setToAddresses(toAddress);
                message.setSubject(taskSubject);
                message.setHtmlBody(htmlBody);
                message.setReplyTo(fromEmailAddress);
                message.setSaveAsActivity(true);
                message.setTreatTargetObjectAsRecipient(true);
                message.setTargetObjectId(leads[0].Id);

                // Debug log for email message
                System.debug('Email message prepared: ' + message);

                // Send email
                if (!Test.isRunningTest()) {
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
                    if (results != null && results.size() > 0 && !results[0].success) {
                        System.debug('Failed to send email: ' + results[0].errors[0].message);
                    } else {
                        System.debug('Email sent successfully.');
                    }
                }

                // Process email message relations and attachments
                List<EmailMessage> emailmessageList = new List<EmailMessage>();
                List<EmailMessageRelation> emrObj = new List<EmailMessageRelation>();
                if (Schema.sObjectType.EmailMessageRelation.isQueryable()) {
                    emrObj = [SELECT Id, EmailMessageId, CreatedDate FROM EmailMessageRelation WHERE RelationId = :leads[0].Id ORDER BY CreatedDate Desc LIMIT 1];
                    System.debug('EmailMessageRelation queried: ' + emrObj);
                }
                if (Schema.sObjectType.EmailMessage.isQueryable()) {
                    emailmessageList = [SELECT Id, ActivityId, CreatedDate FROM EmailMessage WHERE Id = :emrObj[0].EmailMessageId LIMIT 1];
                    System.debug('EmailMessage queried: ' + emailmessageList);
                    if (binaryAttachments != null && binaryAttachments.size() > 0) {
                        for (Integer i = 0; i < binaryAttachments.size(); i++) {
                            Attachment attachment = new Attachment();
                            if (emailmessageList.size() > 0) {
                                attachment.ParentId = emailmessageList[0].Id;
                            }
                            attachment.Name = binaryAttachments[i].filename;
                            attachment.Body = binaryAttachments[i].body;
                            attachments.add(attachment);
                        }
                        if (attachments.size() > 0) {
                            insert attachments;
                            System.debug('Attachments inserted: ' + attachments);
                        }
                    }
                }
                if (emailmessageList.size() > 0) {
                    emailmessageList[0].FromName = senderName;
                    emailmessageList[0].FromAddress = fromEmailAddress;
                    if (toEmailAddresss.size() > 0) {
                        emailmessageList[0].ToAddress = toEmailAddresss[0] + ',' + fromEmailAddress;
                    }
                    update emailmessageList[0];
                    System.debug('EmailMessage updated: ' + emailmessageList[0]);
                }
            } else {
                System.debug('No leads found with the given email address.');
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
        }
        return result;
    }

    private String extractVerificationLink(String htmlBody) {
        System.debug('Extracting verification link from HTML body.');
        String verificationLink = '';
        String linkStart = '<a href="';
        String linkEnd = '"';
        
        Integer startIndex = htmlBody.indexOf(linkStart);
        if (startIndex != -1) {
            startIndex += linkStart.length();
            Integer endIndex = htmlBody.indexOf(linkEnd, startIndex);
            if (endIndex != -1) {
                verificationLink = htmlBody.substring(startIndex, endIndex);
            }
        }
        System.debug('Extracted Verification Link: ' + verificationLink);
        return verificationLink;
    }
}
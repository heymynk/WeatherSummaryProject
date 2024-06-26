trigger UpdateLeadStatusOnEmailReply on EmailMessage (after insert) {
    EmailMessageHandler.updateLeadStatusOnEmailSent(Trigger.new);
    EmailMessageHandler.updateLeadStatusOnEmailReply(Trigger.new);
}


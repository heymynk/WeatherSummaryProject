trigger UpdateLeadStatusOnEmailSent on EmailMessage (after insert) {
    EmailMessageHandler.updateLeadStatusOnEmailSent(Trigger.new);
}

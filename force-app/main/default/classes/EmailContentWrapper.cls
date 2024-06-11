public class EmailContentWrapper {
    @AuraEnabled
    public String subjectEmail;
    @AuraEnabled
    public String emailContent;

    public EmailContentWrapper(String subjectEmail, String emailContent) {
        this.subjectEmail = subjectEmail;
        this.emailContent = emailContent;
    }
}

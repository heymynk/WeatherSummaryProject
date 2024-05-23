public with sharing class CompanyInfoWrapper {
       
        @AuraEnabled
        public String displayName;
        @AuraEnabled
        public String summary;

        public CompanyInfoWrapper(String displayName, String summary) {
            this.displayName = displayName;
            this.summary = summary;
        }
}
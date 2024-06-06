import { LightningElement, api, track } from 'lwc';
import generateEmailContent from '@salesforce/apex/LeadInteractionHandler.generateEmailContent';
import generateCallScript from '@salesforce/apex/LeadInteractionHandler.generateCallScript';
import getCompanyData from '@salesforce/apex/LeadInteractionHandler.getCompanyData';

export default class PersonalizedEmailGenerator extends LightningElement {
    @api recordId; 
    @track emailContent;
    @track callScript;
    @track companyData;
    customPromptByUser = '';

    connectedCallback() {
        this.fetchCompanyData();
    }

    fetchCompanyData() {
        getCompanyData({ leadId: this.recordId })
            .then(result => {
                this.companyData = result;
            })
            .catch(error => {
                console.error('Error fetching company data:', error);
                this.companyData = null;
            });
    }

    handleInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleEmailContentChange(event) {
        this.emailContent = event.target.value;
    }

    handleCallScriptChange(event) {
        this.callScript = event.target.value;
    }

    generateEmail() {
        generateEmailContent({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                this.emailContent = result;
            })
            .catch(error => {
                console.error('Error generating email content:', error);
                this.emailContent = 'Failed to generate content: ' + error.body.message;
            });
    }

    generateCallScript() {
        generateCallScript({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                this.callScript = result;
            })
            .catch(error => {
                console.error('Error generating call script:', error);
                this.callScript = 'Failed to generate content: ' + error.body.message;
            });
    }

    sendEmail() {
        // Implement the logic to send the email using your backend setup
    }
}

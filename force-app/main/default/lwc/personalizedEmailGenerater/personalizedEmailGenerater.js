import { LightningElement, api } from 'lwc';
import generateEmailContent from '@salesforce/apex/LeadInteractionHandler.generateEmailContent';
export default class PersonalizedEmailGenerater extends LightningElement {

    @api recordId; // Automatically populated with the Lead record Id
    emailContent;
    companyInfo = 'Sample Company Info';

    handleInputChange(event) {
        this[event.target.name] = event.target.value;
    }

    generateEmailContent() {
        generateEmailContent({ leadId: this.recordId, customPromptByUser: this.template.querySelector('[name="customPrompt"]').value })
            .then(result => {
                this.emailContent = result;
            })
            .catch(error => {
                this.emailContent = 'Failed to generate content: ' + error.body.message;
            });
    }

    sendEmail() {
        // Implement sending email logic or integrate with existing methods
    }
}
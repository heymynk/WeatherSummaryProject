import { LightningElement, api, track } from 'lwc';
import getCompanyData from '@salesforce/apex/LeadInteractionHandler.getCompanyData';

export default class CompanyData extends LightningElement {
    @api recordId;
    @track companyData;

    connectedCallback() {
        this.fetchCompanyData();
    }

    fetchCompanyData() {
        getCompanyData({ leadId: this.recordId })
            .then(result => {
                this.companyData = result;
                console.log('Company Data:', JSON.stringify(this.companyData));
            })
            .catch(error => {
                this.handleError(error, 'Error fetching company data');
            });
    }

    handleError(error, message) {
        console.error(message, error);
        // Optionally, you can show an error message to the user
    }
}

import { LightningElement, api } from 'lwc';
import getCompanyData from '@salesforce/apex/LeadInteractionHandler.getCompanyData';


export default class CompanyInformation extends LightningElement {

    @api recordId;
    @api isWorkingContacted;
    companyData;

    connectedCallback() {
        // Simulated data fetching
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
}
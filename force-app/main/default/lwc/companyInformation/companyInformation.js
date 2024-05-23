import { LightningElement, wire, api } from 'lwc';
import getCompanyData from '@salesforce/apex/CompanyInformationHandler.getCompanyData';

export default class CompanyInfo extends LightningElement {
    @api recordId;  
    companyData;
    error;

    @wire(getCompanyData, { leadId: '$recordId' }) 
    wiredgetCompanyData({ error, data }) {
        if (data) {
            console.log('companyData:', data); 
            this.companyData = data;
            this.error = undefined;
        } else if (error) {
            console.error(error);
            this.error = error;
            this.companyData = undefined;
        }
    }
}

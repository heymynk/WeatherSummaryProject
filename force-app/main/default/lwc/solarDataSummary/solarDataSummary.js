import { LightningElement, api } from 'lwc';
import generateSolarDataSummary from '@salesforce/apex/LeadInteractionHandler.generateSolarDataSummary';

export default class SolarDataSummary extends LightningElement {
    @api leadId;
    summary;
    error;

    connectedCallback() {
        this.fetchSummary();
    }

    fetchSummary() {
        console.log('Fetching summary for Lead ID:', this.leadId);
        generateSolarDataSummary({ leadId: this.leadId })
            .then(result => {
                console.log('Summary result:', result);
                this.summary = result;
                this.error = undefined;
            })
            .catch(error => {
                console.error('Error fetching summary:', error);
                this.error = error;
                this.summary = undefined;
            });
    }
}

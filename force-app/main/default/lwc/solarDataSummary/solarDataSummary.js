import { LightningElement, api,wire } from 'lwc';
import generateSolarPanelDataSummary from '@salesforce/apex/LeadInteractionHandler.generateSolarPanelDataSummary';

export default class SolarPanelSummary extends LightningElement {
        @api leadId;
        solarPanelSummary;
        hasError = false;
        errorMessage = '';
    
        @wire(generateSolarPanelDataSummary, { leadId: '$leadId' })
        wiredGenerateSolarPanelDataSummary({ error, data }) {
            if (data) {
                this.solarPanelSummary = data;
                console.log('solarPanelSummary',this.solarPanelSummary);
                this.hasError = false;
            } else if (error) {
                this.errorMessage = error.body ? error.body.message : 'Unknown error';
                this.isLoading = false;
                this.hasError = true;
            }
        }
    
        get isNoData() {
            return !this.isLoading && !this.hasError && !this.solarPanelSummary;
        }
}

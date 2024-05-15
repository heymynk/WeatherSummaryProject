/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 05-15-2024
 * @last modified by  : Mayank Singh
**/
import { LightningElement, wire, api } from 'lwc';
import PlacesAndWeatherSummary from '@salesforce/apex/WeatherSummaryHandler.PlacesAndWeatherSummary';

export default class LeadWeatherSummary extends LightningElement {
    @api recordId;  
    openAiResponse;
    isLoading = true; // Property to track loading state

    // Wire method to fetch OpenAI response
    @wire(PlacesAndWeatherSummary, { leadId: '$recordId' }) 
    wiredOpenAiResponse({ error, data }) {
        if (data) {
            console.log('OpenAI Response:', data); 
            this.openAiResponse = data;
            this.isLoading = false; // Set loading to false when data is loaded
        } else if (error) {
            console.error(error);
            this.isLoading = false; // Set loading to false on error
        }
    }
}
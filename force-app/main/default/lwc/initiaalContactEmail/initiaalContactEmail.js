import { LightningElement, wire, track } from 'lwc';
import fetchLeads from '@salesforce/apex/WeatherSummaryHandler.fetchLeads';
import fetchLeadById from '@salesforce/apex/WeatherSummaryHandler.fetchLeadById';
import sendEmail from '@salesforce/apex/WeatherSummaryHandler.sendEmail'; // Import the Apex method

export default class GoogleFormEmbed extends LightningElement {
    @track leadOptions = [];
    @track selectedLead = null;
    @track leadDetails = null;
    error = null;

    // Use the Google Form URL directly
    googleFormUrl = 'https://forms.gle/mAQifyktFwQ1xXpu8';

    @wire(fetchLeads)
    wiredLeads({ error, data }) {
        if (data) {
            this.leadOptions = data.map(lead => ({
                label: lead.Name,
                value: lead.Id
            }));
        } else if (error) {
            this.error = error;
            console.error('Error fetching leads:', error);
        }
    }

    handleChange(event) {
        const leadId = event.detail.value;
        this.selectedLead = leadId;
        this.fetchLeadDetails(leadId);
    }

    fetchLeadDetails(leadId) {
        fetchLeadById({ leadId })
            .then(result => {
                this.leadDetails = result;
                this.error = null;
            })
            .catch(error => {
                this.error = error;
                this.leadDetails = null;
                console.error('Error fetching lead details:', error);
            });
    }

    handleSendEmail() {
        sendEmail({ 
            leadId: this.selectedLead, 
            formUrl: this.googleFormUrl 
        })
        .then(result => {
            // Handle success, e.g., show a success message
            console.log('Email sent successfully:', result);
        })
        .catch(error => {
            // Handle error, e.g., show an error message
            console.error('Error sending email:', error);
        });
    }
}

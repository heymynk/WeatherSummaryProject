/**
 * @description       : Controller for Activity Timeline component to display emails.
 * @author            : Mayank Singh
 * @last modified on  : 07-09-2024
 * @last modified by  : Mayank Singh
**/
import { LightningElement, api, wire, track } from 'lwc';
import getEmails from '@salesforce/apex/HtmlEmailParser.getLatestEmailDetails';
//import getLatestEmailDetails from '@salesforce/apex/HtmlEmailParser.getLatestEmailDetails';


export default class ActivityTimeline extends LightningElement {
    @api recordId;
    // @track emailDetails = {};

    // @track emailsData = [];

    @track emails = [];
    @track error;

    @wire(getEmails, { leadId: '$recordId' })
    wiredEmails({ error, data }) {
        if (data) {
            console.log('Emails data:', data);
            this.emails = Object.values(data).map(email => ({
                id: email.Id,
                subject: email.Subject,
                sentDate: new Date(email.CreatedDate).toLocaleString(),
                fromName: email.FromName,
                fromEmail: email.FromAddress,
                toName: email.ToName,
                toEmail: email.ToAddress,
                message: email.HtmlBody,
            }));
            this.error = undefined; // Reset error if data is fetched successfully
        } else if (error) {
            this.error = error;
            this.emails = []; // Clear emails array on error
            console.error('Error fetching emails:', error);
        }
    }

    // @wire(getEmails, { leadId: '$recordId' })
    // wiredEmails({ error, data }) {
    //     if (data) {

    //         console.log('Emails data:', data);
    //         this.emails = Object.values(data).map(email => ({
    //             id: email.Id,
    //             subject: email.Subject,
    //             sentDate: new Date(email.CreatedDate).toLocaleString(),
    //             fromName: email.FromName,
    //             fromEmail: email.FromAddress,
    //             toName: email.ToName,
    //             toEmail: email.ToAddress,
    //             message: email.HtmlBody,
    //         }));
    //     } else if (error) {
    //         console.error('Error fetching emails:', error);
    //     }
    // }

    // get emailSubjects() {
    //     return this.emailDetails.subject ? [this.emailDetails.subject] : [];
    // }



    // @wire(getLatestEmailDetails, { leadId: '$recordId' })
    // wiredEmailDetails({ error, data }) {
    //     if (data) {
    //         this.emailDetails = data;
    //         this.error = undefined;
    //     } else if (error) {
    //         this.error = error;
    //         this.emailDetails = {};
    //     }
    // }


    toggleDetails(event) {
        let emailId = event.target.getAttribute('aria-controls');
        let detailsContainer = this.template.querySelector('#' + emailId);
        detailsContainer.hidden = !detailsContainer.hidden;

        let actionIcon = event.target.querySelector('.slds-timeline__details-action-icon');
        if (actionIcon) {
            actionIcon.style.transform = detailsContainer.hidden ? 'rotate(0)' : 'rotate(-90deg)';
        }
    }

    viewEmailDetails(event) {
        event.preventDefault();
        // Add logic to handle viewing email details
    }

    showEmailOptions(event) {
        // Add logic to show more options for the email
    }
}

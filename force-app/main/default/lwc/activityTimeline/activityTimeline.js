
import { LightningElement, track,api } from 'lwc';
import getLatestEmailMessageForLead from '@salesforce/apex/HtmlEmailParser.getLatestEmailMessageForLead';


export default class EmailTimeline extends LightningElement {
    @track emails = { data: [], error: null };
    @api recordId;


    connectedCallback() {
        this.loadEmails();
    }


    loadEmails() {
        getLatestEmailMessageForLead({leadId: this.recordId})
        .then(data => {
            console.log('Data received:', JSON.parse(JSON.stringify(data)));
            this.emails.data = data.map(email => ({
                ...email,
                formattedDate: this.formatDateToIST(email.CreatedDate),
                isExpanded: false,
                timelineItemClass: 'slds-timeline__item_expandable slds-timeline__item_email',
                ariaControls: `email-item-expanded-${email.Id}`,
                hiddenState: true
            }));
        })
        .catch(error => {
            console.error('Error received:', error);
            this.emails.error = error;
        });
    }


    formatDateToIST(dateString) {
        const date = new Date(dateString);
        const options = {
            timeZone: 'Asia/Kolkata',
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: 'numeric',
            hour12: true,
        };
        return date.toLocaleString('en-US', options);
    }


    toggleDetails(event) {
        const emailId = event.currentTarget.dataset.emailId;
        console.log('Toggle details for emailId:', emailId);


        this.emails.data = this.emails.data.map(email => {
            if (email.Id === emailId) {
                console.log('Toggling expansion for email:', JSON.stringify(email));
                const isExpanded = !email.isExpanded;
                return {
                    ...email,
                    isExpanded,
                    timelineItemClass: `slds-timeline__item_expandable slds-timeline__item_email${isExpanded ? ' slds-is-open' : ''}`,
                    hiddenState: !isExpanded
                };
            }
            return email;
        });


        console.log('Updated emails:', JSON.stringify(this.emails.data));
    }
}




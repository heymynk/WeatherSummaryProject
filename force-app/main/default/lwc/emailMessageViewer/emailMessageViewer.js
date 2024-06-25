import { LightningElement, api, wire } from 'lwc';
import getEmailMessages from '@salesforce/apex/LeadInteractionHandler.getLatestEmailMessageForLead';

export default class EmailMessageViewer extends LightningElement {
    @api recordId;
    
    @wire(getEmailMessages, { leadId: '$recordId' }) emailMessages;
}

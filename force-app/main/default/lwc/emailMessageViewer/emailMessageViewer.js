import { LightningElement, wire } from 'lwc';
import getEmailMessages from '@salesforce/apex/LeadInteractionHandler.getEmailMessages';

export default class EmailMessageViewer extends LightningElement {
    @wire(getEmailMessages) emailMessages;
}

import { LightningElement, api, track,wire } from 'lwc';
import generateEmailContent from '@salesforce/apex/LeadInteractionHandler.generateEmailContent';
import generateCallScript from '@salesforce/apex/LeadInteractionHandler.generateCallScript';
import getCompanyData from '@salesforce/apex/LeadInteractionHandler.getCompanyData';
import getLeadEmailAddress from '@salesforce/apex/LeadInteractionHandler.getLeadEmailAddress';
import getOrgwideEmailAddress from '@salesforce/apex/LeadInteractionHandler.getOrgwideEmailAddress';
import sendEmailToController from '@salesforce/apex/LeadInteractionHandler.sendEmailToController';
import fileAttachment from '@salesforce/apex/LeadInteractionHandler.fileAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEmailMessagesForLead from '@salesforce/apex/LeadInteractionHandler.getEmailMessagesForLead';


export default class PersonalizedEmailGenerator extends LightningElement {
    @api recordId; 
    @track emailContent;
    @track callScript;
    @track companyData;
    @track toAddress;
    @track orgWideAddress;
    @track orgWideId;
    @track subject = '';
    @track HtmlValue;
    @track uploadFile = [];
    @track acceptedFormats = ['.pdf', '.png', '.jpg'];
    @track isLoading = false; 
    @track showEmailFields = false; 
    @track showCallScript = false; 
    @track showGenerateEmailButton = true; 
    @track showGenerateCallScriptButton = false; 
    @track customPromptByUser = ''; 
    @track emailMessages;
    @track emailError;

    connectedCallback() {
        this.fetchLeadEmailAddress();
        this.fetchOrgWideEmailAddress();
        this.fetchCompanyData();
        //this.fetchFileAttachments();
    }

    get dynamicTitle() {
        if (this.showGenerateCallScriptButton) {
            return 'Personalized Call Script Generator';
        }
        return 'Personalized Email Generator';
    }

    fetchLeadEmailAddress() {
        if (this.recordId) {
            getLeadEmailAddress({ leadRecordId: this.recordId })
                .then(result => {
                    this.toAddress = result;
                })
                .catch(error => {
                    this.handleError(error, 'Error fetching lead email address');
                });
        }
    }

    @wire(getEmailMessagesForLead, { leadRecordId: '$recordId' })
    wiredEmailMessages({ error, data }) {
        if (data) {
            this.emailMessages = data;
            this.emailError = undefined;
            console.log('Email Messages:', JSON.stringify(this.emailMessages));
        } else if (error) {
            this.emailError = error;
            this.emailMessages = undefined;
            this.handleError(error, 'Error fetching email messages');
        }
    }



    fetchOrgWideEmailAddress() {
        getOrgwideEmailAddress()
            .then(result => {
                this.orgWideAddress = result.Address;
                this.orgWideId = result.Id;
            })
            .catch(error => {
                this.handleError(error, 'Error fetching org-wide email address');
            });
    }

    fetchCompanyData() {
        getCompanyData({ leadId: this.recordId })
            .then(result => {
                this.companyData = result;
                console.log('Company Data:',JSON.stringify(this.companyData));
            })
            .catch(error => {
                this.handleError(error, 'Error fetching company data');
            });
    }

    fetchFileAttachments() {
        if (this.recordId) {
            fileAttachment({ leadRecordId: this.recordId })
                .then(result => {
                    this.uploadFile = result.map(file => ({
                        contentVersionId: file.ContentDocumentId,
                        name: file.Title
                    }));
                })
                .catch(error => {
                    this.handleError(error, 'Error fetching file attachments');
                });
        }
    }

    handleInputChange(event) {
        const field = event.target.name;
        if (field === 'customPromptByUser') {
            this.customPromptByUser = event.target.value;
        } else {
            this[field] = event.target.value;
        }
    }

    handleEmailContentChange(event) {
        this.emailContent = event.target.value;
    }

    handleCallScriptChange(event) {
        this.callScript = event.target.value;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            this.uploadFile.push({ contentVersionId: file.documentId, name: file.name });
        });
    }

    fileRemove(event) {
        const contentVersionId = event.target.dataset.id;
        this.uploadFile = this.uploadFile.filter(file => file.contentVersionId !== contentVersionId);
    }

    sendEmail() {
        this.isLoading = true; // Show loader
        console.log('Preparing to send email');
        console.log('To Address:', this.toAddress);
        console.log('Org-Wide Email Address ID:', this.orgWideId);
        console.log('Subject:', this.subject);
        console.log('Body:', this.HtmlValue);
        console.log('Uploaded Files:', this.uploadFile.map(file => file.contentVersionId));
    
        sendEmailToController({
            toAddressEmail: [this.toAddress],
            orgwideEmailAddress: this.orgWideId,
            subjectEmail: this.subject,
            emailHtmlValue: this.HtmlValue,
            uploadedFiles: this.uploadFile.map(file => file.contentVersionId)
        })
        .then(() => {
            this.showToast('Success', 'Email sent successfully', 'success');
            this.isLoading = false; 
            this.showEmailFields = false; 
            this.showCallScript = false; 
            this.showGenerateEmailButton = false; 
            this.showGenerateCallScriptButton = true; // Show Generate Call Script button
            
            // Clear the form fields
            this.subject = '';
            this.HtmlValue = '';
            this.emailContent = '';
            this.customPromptByUser = ''; // Clear custom prompt
            this.uploadFile = [];
        })
        .catch(error => {
            this.isLoading = false; 
            this.handleError(error, 'Error sending email');
        });
    }

    generateEmail() {
        this.isLoading = true; 
        console.log('Generating email...');
        generateEmailContent({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                console.log('Email generated successfully.');
                console.log('Result:', result);
                // Extract the subject from the generated email content
                const subjectMatch = result.match(/<p>Subject: (.*?)<\/p>/);
                if (subjectMatch) {
                    this.subject = subjectMatch[1];
                    // Remove the subject line from the email content
                    this.HtmlValue = result.replace(subjectMatch[0], '').trim();
                } else {
                    this.HtmlValue = result;
                }
                this.emailContent = this.HtmlValue; 
                this.showEmailFields = true; 
                this.showCallScript = false; 
                this.isLoading = false; 
                this.showGenerateEmailButton = false; 
                this.customPromptByUser = '';


            })
            .catch(error => {
                this.isLoading = false; 
                this.handleError(error, 'Error generating email content');
            });
    }

    regenerateEmail() {
        this.isLoading = true; 
        console.log('Regenerating email...');
        generateEmailContent({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                console.log('Email regenerated successfully.');
                // console.log('Result:', result);
                const subjectMatch = result.match(/<p>Subject: (.*?)<\/p>/);
                if (subjectMatch) {
                    this.subject = subjectMatch[1];
                    this.HtmlValue = result.replace(subjectMatch[0], '').trim();
                } else {
                    this.HtmlValue = result;
                }
                this.emailContent = this.HtmlValue; 
                this.isLoading = false; 
                this.customPromptByUser = '';

            })
            .catch(error => {
                this.isLoading = false; 
                this.handleError(error, 'Error regenerating email content');
            });
    }


    generateCallScript() {
        this.isLoading = true; 
        console.log('Generating call script...');
        generateCallScript({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                console.log('Call script generated successfully.');
                console.log('Result:', result);
               // this.callScript = result;
                this.callScript = this.stripHtml(result);

                this.isLoading = false; 
                this.showCallScript = true; // Show call script fields
                this.showGenerateCallScriptButton = false; // Hide Generate Call Script button
                this.customPromptByUser = '';

            })
            .catch(error => {
                this.isLoading = false; 
                this.handleError(error, 'Error generating call script');
            });
    }

    regenerateCallScript() {
        this.isLoading = true; 
        console.log('Regenerating call script...');
        generateCallScript({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                console.log('Call script regenerated successfully.');
                console.log('Result:', result);
                this.callScript = this.stripHtml(result);
                this.isLoading = false; 
                this.customPromptByUser = '';

            })
            .catch(error => {
                this.isLoading = false; 
                this.handleError(error, 'Error regenerating call script');
            });
    }

    callLead() {
        console.log('Calling the lead...');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleError(error, message) {
        this.showToast('Error', message, 'error');
        console.error(message, error);
    }

    stripHtml(html) {
        const doc = new DOMParser().parseFromString(html, 'text/html');
        return doc.body.textContent || "";
    }
}
import { LightningElement, api, track } from 'lwc';
import generateEmailContent from '@salesforce/apex/LeadInteractionHandler.generateEmailContent';
import generateCallScript from '@salesforce/apex/LeadInteractionHandler.generateCallScript';
import getCompanyData from '@salesforce/apex/LeadInteractionHandler.getCompanyData';
import getLeadEmailAddress from '@salesforce/apex/LeadInteractionHandler.getLeadEmailAddress';
import getOrgwideEmailAddress from '@salesforce/apex/LeadInteractionHandler.getOrgwideEmailAddress';
import sendEmailToController from '@salesforce/apex/LeadInteractionHandler.sendEmailToController';
import fileAttachment from '@salesforce/apex/LeadInteractionHandler.fileAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
    @track isLoading = false; // Loader state
    @track showEmailFields = false; // Visibility of email fields
    customPromptByUser = '';

    connectedCallback() {
        this.fetchLeadEmailAddress();
        this.fetchOrgWideEmailAddress();
        //this.fetchCompanyData();
        //this.fetchFileAttachments();
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
        this[event.target.name] = event.target.value;
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
        })
        .catch(error => {
            this.handleError(error, 'Error sending email');
        });
    }

    generateEmail() {
        this.isLoading = true; // Show loader
        generateEmailContent({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                // Extract the subject from the generated email content
                const subjectMatch = result.match(/<p>Subject: (.*?)<\/p>/);
                if (subjectMatch) {
                    this.subject = subjectMatch[1];
                    // Remove the subject line from the email content
                    this.HtmlValue = result.replace(subjectMatch[0], '').trim();
                } else {
                    this.HtmlValue = result;
                }
                this.emailContent = this.HtmlValue; // Set the email body without subject
                this.showEmailFields = true; // Show email fields
                this.isLoading = false; // Hide loader
            })
            .catch(error => {
                this.isLoading = false; // Hide loader
                this.handleError(error, 'Error generating email content');
            });
    }
    

    generateCallScript() {
        generateCallScript({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                this.callScript = result;
            })
            .catch(error => {
                this.handleError(error, 'Error generating call script');
            });
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
}

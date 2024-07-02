import { LightningElement, api, track } from 'lwc';
import generateEmailContent from '@salesforce/apex/LeadInteractionHandler.generateEmailContent';
import fileAttachment from '@salesforce/apex/LeadInteractionHandler.fileAttachment';
import sendEmailToController from '@salesforce/apex/LeadInteractionHandler.sendEmailToController';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class GenerateEmail extends LightningElement {
    @api recordId;
    @api isOpenContacted;
    @track emailContent;
    @track uploadFile = [];
    @track isLoading = false;
    @track showEmailFields = false;
    @track showGenerateEmailButton = true;
    customPromptByUser = '';
    subject = '';
    HtmlValue = '';

    generateEmail() {
        this.toggleLoading(true);
        generateEmailContent({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                const subjectMatch = result.match(/<p>Subject: (.*?)<\/p>/);
                if (subjectMatch) {
                    this.subject = subjectMatch[1];
                    this.HtmlValue = result.replace(subjectMatch[0], '').trim();
                } else {
                    this.HtmlValue = result;
                }
                this.emailContent = this.HtmlValue;
                this.showEmailFields = true;
                this.showGenerateEmailButton = false;
                this.customPromptByUser = '';
            })
            .catch(error => this.handleError(error, 'Error generating email content'))
            .finally(() => this.toggleLoading(false));
    }

    regenerateEmail() {
        if (!this.customPromptByUser) {
            this.showToast('Alert', 'Please enter the prompt to regenerate the email.', 'warning');
            return;
        }
        this.toggleLoading(true);
        generateEmailContent({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                const subjectMatch = result.match(/<p>Subject: (.*?)<\/p>/);
                if (subjectMatch) {
                    this.subject = subjectMatch[1];
                    this.HtmlValue = result.replace(subjectMatch[0], '').trim();
                } else {
                    this.HtmlValue = result;
                }
                this.emailContent = this.HtmlValue;
                this.customPromptByUser = '';
                this.showEmailFields = true;
            })
            .catch(error => this.handleError(error, 'Error regenerating email content'))
            .finally(() => this.toggleLoading(false));
    }

    handleInputChange(event) {
        this[event.target.name] = event.target.value;
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
                .catch(error => this.handleError(error, 'Error fetching file attachments'));
        }
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
        this.toggleLoading(true);
        sendEmailToController({
            toAddressEmail: [this.toAddress],
            orgwideEmailAddress: this.orgWideId,
            subjectEmail: this.subject,
            emailHtmlValue: this.HtmlValue,
            uploadedFiles: this.uploadFile.map(file => file.contentVersionId)
        })
        .then(() => {
            this.showToast('Success', 'Email sent successfully', 'success');
            this.resetForm();
        })
        .catch(error => this.handleError(error, 'Error sending email'))
        .finally(() => this.toggleLoading(false));
    }

    toggleLoading(isLoading) {
        this.isLoading = isLoading;
    }

    resetForm() {
        this.showEmailFields = false;
        this.showGenerateEmailButton = true;
        this.subject = '';
        this.HtmlValue = '';
        this.emailContent = '';
        this.customPromptByUser = '';
        this.uploadFile = [];
    }

    handleError(error, message) {
        console.error(message, error);
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}

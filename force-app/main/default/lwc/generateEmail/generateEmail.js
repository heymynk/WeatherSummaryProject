import { LightningElement, api, track } from 'lwc';
import generateEmailContent from '@salesforce/apex/LeadInteractionHandler.generateEmailContent';
import fileAttachment from '@salesforce/apex/LeadInteractionHandler.fileAttachment';
import sendEmailToController from '@salesforce/apex/LeadInteractionHandler.sendEmailToController';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GenerateEmail extends LightningElement {
    @api recordId;
    @api isOpenContacted;
    @api isOpenNotContacted;
    @track emailContent;
    @track uploadFile = [];
    @track isLoading = false;
    @track showEmailFields = false;
    @track showGenerateEmailButton = true;
    @track additionalPrompt = true;
    customPromptByUser = '';
    subject = '';
    HtmlValue = '';
    loadingMessage = '';

    generateEmail() {
        this.setLoading(true, 'Generating email content...');
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
                this.additionalPrompt = false;
            })
            .catch(error => this.handleError(error, 'Error generating email content'))
            .finally(() => this.setLoading(false, ''));
    }

    regenerateEmail() {
        this.setLoading(true, 'Regenerating email content...');
        if (!this.customPromptByUser) {
            this.showToast('Alert', 'Email Regenerated Sucessfully.', 'Success');
            return;
        }
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
            .finally(() => this.setLoading(false, ''));
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
        this.setLoading(true, 'Sending email...');
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
        .finally(() => this.setLoading(false, ''));
    }

    setLoading(isLoading, message) {
        this.isLoading = isLoading;
        this.loadingMessage = message;
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

    handleError(error, defaultMessage) {
        const message = error.body?.message || defaultMessage;
        this.showToast('Error', message, 'error');
        this.setLoading(false, '');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
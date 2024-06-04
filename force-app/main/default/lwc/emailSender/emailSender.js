import { LightningElement, api, track, wire } from 'lwc';
import getEmailTemplateFolders from '@salesforce/apex/EmailController.getEmailTemplateFolders';
import getEmailTemplates from '@salesforce/apex/EmailController.getEmailTemplates';
import getLeadEmailAddress from '@salesforce/apex/EmailController.getLeadEmailAddress';
import getOrgwideEmailAddress from '@salesforce/apex/EmailController.getOrgwideEmailAddress';
import sendEmailToController from '@salesforce/apex/EmailController.sendEmailToController';
import fileAttachment from '@salesforce/apex/EmailController.fileAttachment';

export default class EmailSender extends LightningElement {
    @api recordId;
    @track toAddress;
    @track orgWideAddress;
    @track orgWideId;
    @track getTempList = [];
    @track emailTempList = [];
    @track subject;
    @track body;
    @track uploadFile = [];
    @track acceptedFormats = ['.pdf', '.png', '.jpg'];
    @track isModalOpen = false;


    connectedCallback() {
        this.fetchEmailTemplateFolders();
        this.fetchLeadEmailAddress();
        this.fetchOrgWideEmailAddress();
        this.fetchFileAttachments();
    }

    fetchEmailTemplateFolders() {
        getEmailTemplateFolders()
            .then(result => {
                this.getTempList = result.map(folder => ({ label: folder.Name, value: folder.Id }));
            })
            .catch(error => {
                console.error('Error fetching email template folders: ', error);
            });
    }

    fetchLeadEmailAddress() {
        if (this.recordId) {
            getLeadEmailAddress({ leadRecordId: this.recordId })
                .then(result => {
                    this.toAddress = result;
                })
                .catch(error => {
                    console.error('Error fetching lead email address: ', error);
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
                console.error('Error fetching org-wide email address: ', error);
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
                    console.error('Error fetching file attachments: ', error);
                });
        }
    }

    handleToEmailAddress(event) {
        this.toAddress = event.target.value;
    }

    handleChange(event) {
        this.orgWideAddress = event.target.value;
    }

    handleEmailTempFolderChange(event) {
        const folderId = event.detail.value;
        getEmailTemplates({ folderName: folderId })
            .then(result => {
                this.emailTempList = result.map(template => ({ label: template.Name, value: template.Id }));
            })
            .catch(error => {
                console.error('Error fetching email templates: ', error);
            });
    }

    handleEmailTemplateChange(event) {
        const templateId = event.detail.value;
        getEmailTemplates({ folderName: templateId })
            .then(result => {
                this.subject = result[0].Subject;
                this.body = result[0].body;
            })
            .catch(error => {
                console.error('Error fetching email template: ', error);
            });
    }

    handleSubject(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
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
        console.log('Body:', this.body);
        console.log('Uploaded Files:', this.uploadFile.map(file => file.contentVersionId));
    
        sendEmailToController({
            toAddressEmail: [this.toAddress],
            orgwideEmailAddress: this.orgWideId,
            subjectEmail: this.subject,
            bodyEmail: this.body,
            uploadedFiles: this.uploadFile.map(file => file.contentVersionId)
        })
        .then(() => {
            console.log('Email sent successfully');
        })
        .catch(error => {
            console.error('Error sending email:', error);
        });
    }
    

    openModal(){
        this.isModalOpen = true;
    }

    cancelPopup(){
        this.isModalOpen = false;
    }
}






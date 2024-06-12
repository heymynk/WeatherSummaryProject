import { LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLeadEmailAddress from '@salesforce/apex/EmailSender.getLeadEmailAddress';
import getOrgwideEmailAddress from '@salesforce/apex/EmailSender.getOrgwideEmailAddress';
import sendEmailToController from '@salesforce/apex/EmailSender.sendEmailToController';
import fileAttachment from '@salesforce/apex/EmailSender.fileAttachment';
import getCompanyData from '@salesforce/apex/WeatherSummaryHandler.getCompanyData';

export default class EscropEmailSender extends LightningElement {

    @api recordId;
    companyData;
    error;

    @track toAddress;
    @track orgWideAddress;
    @track orgWideId;
    @track uploadFile = [];
    @track acceptedFormats = ['.pdf', '.png', '.jpg'];
    @track subject = 'Testing Lead Email';
    @track HtmlValue = `I'm [Your Name] from Esolar Corp, offering tailored solar solutions for businesses like Concretio. Our solar panel installations not only cut costs but also promote environmental sustainability. By harnessing solar energy, Concretio can enjoy significant savings on electricity bills while reducing its carbon footprint. Let's discuss how solar energy can benefit Concretio and the environment.

Additionally, our team at Esolar Corp is dedicated to providing seamless installation and ongoing support to ensure that Concretio maximizes the benefits of solar energy. We prioritize customer satisfaction and are committed to delivering high-quality, reliable solutions that meet your specific needs.`;
   

    connectedCallback() {
        this.fetchLeadEmailAddress();
        this.fetchOrgWideEmailAddress();
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
    @wire(getCompanyData, { leadId: '$recordId' })
    wiredgetCompanyData({ error, data }) {
        if (data) {
            console.log('companyData:', data);
            this.companyData = data;
            this.error = undefined;
        } else if (error) {
            console.error(error);
            this.error = error;
            this.companyData = undefined;
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

    handleSubject(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.HtmlValue = event.target.value;
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
            console.error('Error sending email:', error);
            this.showToast('Error', error.body.message, 'error');
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

}
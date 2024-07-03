import { LightningElement, api, track, wire } from 'lwc';
import generateEmailContent from '@salesforce/apex/LeadInteractionHandler.generateEmailContent';
import generateCallScript from '@salesforce/apex/LeadInteractionHandler.generateCallScript';
import getCompanyData from '@salesforce/apex/LeadInteractionHandler.getCompanyData';
import getLeadEmailAddress from '@salesforce/apex/LeadInteractionHandler.getLeadEmailAddress';
import getOrgwideEmailAddress from '@salesforce/apex/LeadInteractionHandler.getOrgwideEmailAddress';
import sendEmailToController from '@salesforce/apex/LeadInteractionHandler.sendEmailToController';
import fileAttachment from '@salesforce/apex/LeadInteractionHandler.fileAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEmailMessages from '@salesforce/apex/LeadInteractionHandler.getLatestEmailMessageForLead';
import getLeadResponse from '@salesforce/apex/LeadInteractionHandler.getLeadResponse';
import { getRecord } from 'lightning/uiRecordApi';
import LEAD_REPLY_RECEIVED_FIELD from '@salesforce/schema/Lead.Reply_Received__c';



export default class PersonalizedEmailGenerator extends LightningElement {
    @track leadResponse;
    @api recordId;
    @track emailContent;
    @track callScript;
    @track companyData = true;
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
    @track emailMessages = { data: null, error: null };
    @track isWorkingContacted = true;

    connectedCallback() {
        this.fetchLeadEmailAddress();
        this.fetchOrgWideEmailAddress();
        this.fetchCompanyData();
        this.fetchLeadResponse();
        this.fetchEmailMessages();

    }

    get dynamicTitle() {
        if (this.showGenerateCallScriptButton) {
            return 'Personalized Call Script Generator';
        } else if (!this.isWorkingContacted) {
            return '';
        }
        return 'Personalized Email Generator';
    }

    get dynamicIcon() {
        if (this.showGenerateCallScriptButton) {
            return 'utility:call';
        } else if (!this.isWorkingContacted) {
            return '';
        }
        return 'utility:email';
    }

    @wire(getRecord, { recordId: '$recordId', fields: [LEAD_REPLY_RECEIVED_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            if (data.fields.Reply_Received__c.value) {
                this.showToast('Reply Notification', 'A reply has been received from the lead.', 'success');
            }
        } else if (error) {
            console.error('Error fetching lead record:', error);
        }
    }

    // @wire(getEmailMessages, { leadId: '$recordId' }) emailMessages;

    fetchEmailMessages() {
        if (this.recordId) {
            getEmailMessages({ leadId: this.recordId })
                .then(result => {
                    // Replace '>' with a newline in the TextBody of each email
                    this.emailMessages.data = result.map(email => {
                        return {
                            ...email,
                            TextBody: email.TextBody.replace(/[<>]/g, '\n')
                        };
                    });
                    console.log('Email Messages:', JSON.stringify(this.emailMessages.data));
                })
                .catch(error => {
                    this.emailMessages.error = error;
                    this.handleError(error, 'Error fetching email messages');
                });
        }
    }


    // fetchLeadResponse() {
    //     if (this.recordId) {
    //         getLeadResponse({ leadId: this.recordId })
    //             .then(result => {
    //                 this.leadResponse = result;
    //                 console.log('leadResponse',this.leadResponse);
    //                 this.showGenerateCallScriptButton = result === 'Working - Reply';
    //                 this.showGenerateEmailButton = !this.showGenerateCallScriptButton;  
    //             })
    //             .catch(error => {
    //                 this.handleError(error, 'Error fetching lead response');
    //             });
    //     }
    // }



    fetchLeadResponse() {
        if (this.recordId) {
            getLeadResponse({ leadId: this.recordId })
                .then(result => {
                    this.leadResponse = result;
                    console.log('leadResponse', this.leadResponse);
    
                    if (result === 'Working - Contacted') {
                        // Set flags to hide both buttons and clear any related data
                        this.showGenerateCallScriptButton = false;
                        this.showGenerateEmailButton = false;
                        this.companyData = false; 
                        this.isWorkingContacted = false;
                    } else {
                        // Default behavior when result is not 'Working - Contacted'
                        this.showGenerateCallScriptButton = result === 'Working - Reply';
                        this.showGenerateEmailButton = !this.showGenerateCallScriptButton;

                    }
                })
                .catch(error => {
                    this.handleError(error, 'Error fetching lead response');
                });
        }
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
                console.log('Company Data:', JSON.stringify(this.companyData));
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
            this.showGenerateCallScriptButton = false; // Show Generate Call Script button
            this.companyData = false;      
            this.isWorkingContacted = false;      
            // Clear the form fields
            this.subject = '';
            this.HtmlValue = '';
            this.emailContent = '';
            this.customPromptByUser = ''; 
            this.uploadFile = [];
           // location.reload();
           setTimeout(() => {
            location.reload();
        },4000); 
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
                this.showToast('Success', 'Email successfully generated', 'success');
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


    replyWithEmail() {
        this.isLoading = true; 
        console.log('Generating email...');
        generateEmailContent({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
            .then(result => {
                this.showToast('Success', 'Email successfully generated', 'success');
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
                // this.showCallScript = false; 
                this.isLoading = false; 
                this.showGenerateCallScriptButton = false
                // this.showGenerateEmailButton = false; 
                // this.customPromptByUser = '';


            })
            .catch(error => {
                this.isLoading = false; 
                this.handleError(error, 'Error generating email content');
            });
    }


    
    // regenerateEmail() {
    //     if (!this.customPromptByUser) {
    //         this.showToast('Alert', 'Email Successfully regenerated.', 'Success');
    //         return;
    //     }
    
    //     this.isLoading = true; // Show loading spinner
    //     console.log('Loading state set to true:', this.isLoading);
    
    //     generateEmailContent({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
    //         .then(result => {
    //             console.log('Email regenerated successfully.');
    //             // Handle result and update component state accordingly
    //             const subjectMatch = result.match(/<p>Subject: (.*?)<\/p>/);
    //             if (subjectMatch) {
    //                 this.subject = subjectMatch[1];
    //                 this.HtmlValue = result.replace(subjectMatch[0], '').trim();
    //             } else {
    //                 this.HtmlValue = result;
    //             }
    //             this.emailContent = this.HtmlValue;
    //         })
    //         .catch(error => {
    //             this.handleError(error, 'Error regenerating email content');
    //         })
    //         .finally(() => {
    //             this.isLoading = false; // Hide loading spinner
    //             console.log('Loading state reset to false:', this.isLoading);
    //         });
    // }


    // regenerateEmail() {
    //     // if (!this.customPromptByUser) {
    //     //     this.showToast('Alert', 'Email Successfully regenerated.', 'Success');
    //     //     return;
    //     // }
    
    //     this.isLoading = true; // Show loading spinner
    //     console.log('Loading state set to true:', this.isLoading);
    
    //     // Define the hard-coded prompt
    //     const hardCodedPrompt = 'Use diffrent words and approach for the email, it must  not be same as before.';
        
    //     // Append the hard-coded prompt to the custom prompt
    //     const combinedPrompt = hardCodedPrompt + this.customPromptByUser;
    //     console.log('Combined Prompt:', combinedPrompt);
    
    //     // Call the Apex method with the combined prompt
    //     generateEmailContent({ leadId: this.recordId, customPromptByUser: combinedPrompt })
    //         .then(result => {
    //             console.log('Email regenerated successfully.');
    //             // Handle result and update component state accordingly
    //             const subjectMatch = result.match(/<p>Subject: (.*?)<\/p>/);
    //             if (subjectMatch) {
    //                 this.subject = subjectMatch[1];
    //                 this.HtmlValue = result.replace(subjectMatch[0], '').trim();
    //             } else {
    //                 this.HtmlValue = result;
    //             }
    //             this.emailContent = this.HtmlValue;
    //             this.showToast('Success', 'Email Successfully regenerated.', 'success');
    //         })
    //         .catch(error => {
    //             this.handleError(error, 'Error regenerating email content');
    //         })
    //         .finally(() => {
    //             this.isLoading = false; // Hide loading spinner
    //             console.log('Loading state reset to false:', this.isLoading);
    //         });
    // }

    regenerateEmail() {
    
        this.isLoading = true; // Show loading spinner
        console.log('Loading state set to true:', this.isLoading);
    
        // Define the hard-coded prompt
        const hardCodedPrompt = 'Create a unique version of the email with different wording and approach compared to previous versions. Make it engaging, personalized, and fresh.';
        
        // Generate a random number or use a timestamp to make each prompt unique
        const uniqueSuffix = ` (unique ID: ${Math.random().toString(36).substring(2)})`;
        
        // Append the hard-coded prompt and the unique suffix to the custom prompt
        const combinedPrompt = hardCodedPrompt + ' ' + this.customPromptByUser + uniqueSuffix;
        console.log('Combined Prompt:', combinedPrompt);
    
        // Call the Apex method with the combined prompt
        generateEmailContent({ leadId: this.recordId, customPromptByUser: combinedPrompt })
            .then(result => {
                console.log('Email regenerated successfully.');
                // Handle result and update component state accordingly
                const subjectMatch = result.match(/<p>Subject: (.*?)<\/p>/);
                if (subjectMatch) {
                    this.subject = subjectMatch[1];
                    this.HtmlValue = result.replace(subjectMatch[0], '').trim();
                } else {
                    this.HtmlValue = result;
                }
                this.emailContent = this.HtmlValue;
                this.showToast('Success', 'Email Successfully regenerated.', 'success');
            })
            .catch(error => {
                this.handleError(error, 'Error regenerating email content');
            })
            .finally(() => {
                this.isLoading = false; // Hide loading spinner
                console.log('Loading state reset to false:', this.isLoading);
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

    // regenerateCallScript() {

    //     if (!this.customPromptByUser) {
    //         this.showToast('Alert', 'Please enter the prompt to regenerate the call script.', 'warning');
    //         return;
    //     }
    //     this.isLoading = true; 
    //     console.log('Regenerating call script...');
    //     generateCallScript({ leadId: this.recordId, customPromptByUser: this.customPromptByUser })
    //         .then(result => {
    //             console.log('Call script regenerated successfully.');
    //             console.log('Result:', result);
    //             this.callScript = this.stripHtml(result);
    //             this.isLoading = false; 
    //             this.customPromptByUser = '';

    //         })
    //         .catch(error => {
    //             this.isLoading = false; 
    //             this.handleError(error, 'Error regenerating call script');
    //         });
    // }


    regenerateCallScript() {
        this.isLoading = true; 
        const hardCodedPrompt = 'Create a unique version of the call script with different wording and approach compared to previous versions. Make it engaging, personalized, and fresh.';
        const uniqueSuffix = ` (unique ID: ${Math.random().toString(36).substring(2, 8)})`;
        generateCallScript({ leadId: this.recordId, customPromptByUser: hardCodedPrompt + uniqueSuffix })
            .then(result => {
                this.showToast('Success', 'Call Script successfully regenerated', 'success');
                console.log('Call script regenerated successfully.');
                console.log('Result:', result);
                this.callScript = result;
                this.callScript = this.stripHtml(result);
                this.isLoading = false; 
                this.customPromptByUser = '';
            })
            .catch(error => {
                this.isLoading = false; 
                this.updateLoadingState(false);
                this.handleError(error, 'Error regenerating call script');
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

    stripHtml(html) {
        const doc = new DOMParser().parseFromString(html, 'text/html');
        return doc.body.textContent || "";
    }

    
}
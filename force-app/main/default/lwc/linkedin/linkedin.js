import { LightningElement, track } from 'lwc';
import postonLinkedIn from '@salesforce/apex/LinkedinService.postonLinkedIn';

export default class Linkedin extends LightningElement {
    @track result;
    @track author = 'urn:li:person:oLL5giqIwt';  // Default value, can be dynamic
    @track lifecycleState = 'PUBLISHED';
    @track shareCommentary = '';
    @track shareMediaCategory = 'NONE';
    @track visibility = 'PUBLIC';

    handleInputChange(event) {
        const field = event.target.dataset.id;
        if (field === 'author') {
            this.author = event.target.value;
        } else if (field === 'lifecycleState') {
            this.lifecycleState = event.target.value;
        } else if (field === 'shareCommentary') {
            this.shareCommentary = event.target.value;
        } else if (field === 'shareMediaCategory') {
            this.shareMediaCategory = event.target.value;
        } else if (field === 'visibility') {
            this.visibility = event.target.value;
        }
    }

    handlePostOnLinkedIn() {
        postonLinkedIn({ 
            author: this.author,
            lifecycleState: this.lifecycleState,
            shareCommentary: this.shareCommentary,
            shareMediaCategory: this.shareMediaCategory,
            visibility: this.visibility
        })
        .then(response => {
            this.result = 'Post on LinkedIn Response: ' + JSON.stringify(response);
        })
        .catch(error => {
            this.result = 'Error: ' + JSON.stringify(error);
        });
    }
}

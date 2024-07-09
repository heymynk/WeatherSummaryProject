/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 07-09-2024
 * @last modified by  : Mayank Singh
**/
import { LightningElement } from 'lwc';

export default class TimelineFilterPanel extends LightningElement {
    handleSearch(event) {
        const searchValue = event.target.value;
        // Dispatch the search value to parent component
        const searchEvent = new CustomEvent('search', { detail: searchValue });
        this.dispatchEvent(searchEvent);
    }
}

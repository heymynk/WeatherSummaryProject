import { LightningElement, api, wire, track } from 'lwc';
import fetchLeadAddressByCoordinates from '@salesforce/apex/LeadInteractionHandler.fetchLeadAddressByCoordinates';
import fetchLeadAddress from '@salesforce/apex/LeadInteractionHandler.getLeadAddress';

export default class LeadLocation extends LightningElement {
    @api recordId;
    @track mapMarkers = [];
    @track selectedMarker;
    @track leadAddress;
    @track isLoading = true; // Initial loading state
    @track mapLoading = true; // Initial map loading state

    connectedCallback() {
        console.log('Record Id:', this.recordId);
        this.fetchLeadAddressDetails();
    }

    fetchLeadAddressDetails() {
        fetchLeadAddress({ leadId: this.recordId })
            .then(result => {
                console.log('Lead Address:', result);
                // Split the address string by commas, filter out null values, and join with new lines
                const addressParts = result.split(', ');
                const filteredAddressParts = addressParts.filter(part => part && part.trim() !== 'null');
                const formattedAddress = filteredAddressParts.join(',\n');
                this.leadAddress = formattedAddress;
            })
            .catch(error => {
                console.error('Error fetching lead address:', error);
            })
            .finally(() => {
                this.isLoading = false; // Set loading state to false once address is fetched
            });
    }
    
    

    @wire(fetchLeadAddressByCoordinates, { leadId: '$recordId' })
    wiredLead({ error, data }) {
        console.log('Fetching lead coordinates with leadId:', this.recordId);
        
        if (data) {
            try {
                console.log('Lead Coordinates data received:', data);
                const latitude = data.latitude;
                const longitude = data.longitude;
                console.log('Latitude:', latitude, 'Longitude:', longitude);
                this.mapMarkers = [{
                    location: {
                        Latitude: latitude,
                        Longitude: longitude,
                    },
                    icon: 'standard:location',
                    title: 'Lead Location',
                    description: 'This is the location of the Lead.'
                }];
                console.log('Map markers set:', JSON.stringify(this.mapMarkers));
            } catch (err) {
                console.error('Error processing data:', err);
            } finally {
                this.mapLoading = false;
            }
        } else if (error) {
            console.error('Error fetching Lead Coordinates:', error);
        }
    }

    callMarkerHandler(event) {
        console.log('Marker selected:', event.detail.selectedMarkerValue);
        this.selectedMarker = event.detail.selectedMarkerValue;
    }
}

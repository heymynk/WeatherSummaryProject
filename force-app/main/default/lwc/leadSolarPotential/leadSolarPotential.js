import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJs from '@salesforce/resourceUrl/chartJs';
import getSolarDataJSON from '@salesforce/apex/LeadInteractionHandler.getSolarDataJSON';
import generateSolarDataSummary from '@salesforce/apex/LeadInteractionHandler.generateSolarDataSummary';


export default class LeadSolarPotential extends LightningElement {
    @api recordId;
    showSpinner = true;
    showDescription = false;
    showError = false;
    showChart = false;
    chart;
    summaryText;
    isLoading = true; 


    months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    connectedCallback() {
        this.loadSummary();
        console.log('Record Id:', this.recordId);
    }

    renderedCallback() {
        if (this.chartJsInitialized) {
            return;
        }
        this.chartJsInitialized = true;

        loadScript(this, chartJs)
            .then(() => {
                this.fetchSolarData();
            })
            .catch(error => {
                this.showError = true;
                this.showSpinner = false;
                console.error('Error loading ChartJS', error);
            });
    }

    fetchSolarData() {
        getSolarDataJSON({ leadId: this.recordId })
            .then(result => {
                console.log('Solar Data Result:', result);
                if (result) {
                    const solarData = JSON.parse(result);
                    if (solarData && solarData.poaMonthly && solarData.poaMonthly.length > 0) {
                        this.showChart = true;
                        this.plotSolarData(solarData);
                        this.showDescription = true;
                        
                    } else {
                        this.showError = true;
                    }
                } else {
                    this.showError = true;
                }
                this.showSpinner = false;
            });
    }
    
    plotSolarData(solarData) {
        const canvas = document.createElement('canvas');
        canvas.style.width = '100%';
        canvas.style.height = '100%';
        canvas.style.backgroundColor = '#f3f3f3'; 
        canvas.style.boxShadow = '0 4px 8px rgba(0,0,0,0.1)'; 



        this.template.querySelector('div.chart-container').appendChild(canvas);
        const ctx = canvas.getContext('2d');
        this.chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: [...this.months],
                datasets: [
                    {
                        label: 'POA Monthly (kWh/m2)',
                        data: [...solarData.poaMonthly],
                        backgroundColor: 'rgba(255, 99, 132, 0.2)',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 1,
                        fill: true
                    },
                    {
                        label: 'AC Monthly (kWhac)',
                        data: [...solarData.acMonthly],
                        backgroundColor: 'rgba(75, 192, 192, 0.2)',
                        borderColor: 'rgba(75, 192, 192, 1)',
                        borderWidth: 1,
                        fill: true
                    },
                    {
                        label: 'Solar Radiation Monthly (kWh/m2/day)',
                        data: [...solarData.solradMonthly],
                        backgroundColor: 'rgba(0, 0, 0, 0.2)',
                        borderColor: 'rgba(0, 0, 0, 1)',
                        borderWidth: 1,
                        fill: true
                    },
                    {
                        label: 'DC Monthly (kWhdc)',
                        data: [...solarData.dcMonthly],
                        backgroundColor: 'rgba(255, 206, 86, 0.2)',
                        borderColor: 'rgba(255, 206, 86, 1)',
                        borderWidth: 1,
                        fill: true
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    xAxes: [{
                        display: true,
                        scaleLabel: {
                            display: true,
                            labelString: 'Month',
                            fontSize:12
                        },
                        ticks: {
                            fontColor: 'black',
                            fontSize: 12
                        }
                    }],
                    yAxes: [{
                        display: true,
                        ticks: {
                            display: false 
                        }
                    }]
                },
                legend: {
                    display: true,
                    labels: {
                        fontColor: 'black',
                        fontSize: 10 
                    }
                },
                tooltips: {
                    mode: 'index',
                    intersect: false
                },
                hover: {
                    mode: 'nearest',
                    intersect: true
                },
                animation: {
                    duration: 1000
                }
            }
        });
    }



    loadSummary() {
        generateSolarDataSummary({ leadId: this.recordId })
            .then(result => {
                this.summaryText = String(result).replace(/<\/?[^>]+(>|$)/g, ""); 
            })
            .catch(error => {
                console.error('Error fetching solar data summary:', error);
                this.summaryText = 'Error fetching solar data summary.';
            })
            .finally(() => {
                this.isLoading = false; // Set loading state to false after fetching data
            });
    }
}

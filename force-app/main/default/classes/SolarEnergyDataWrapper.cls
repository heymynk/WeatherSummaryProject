public class SolarEnergyDataWrapper {
    @AuraEnabled
    public List<Object> poaMonthly;
    
    @AuraEnabled
    public List<Object> acMonthly;
    
    @AuraEnabled
    public List<Object> solradMonthly;
    
    @AuraEnabled
    public List<Object> dcMonthly;

    public SolarEnergyDataWrapper(List<Object> poaMonthly, List<Object> acMonthly, List<Object> solradMonthly, List<Object> dcMonthly) {
        this.poaMonthly = poaMonthly;
        this.acMonthly = acMonthly;
        this.solradMonthly = solradMonthly;
        this.dcMonthly = dcMonthly;
    }
}

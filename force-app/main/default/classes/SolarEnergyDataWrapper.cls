public class SolarEnergyDataWrapper {
    public List<Object> poaMonthly;
    public List<Object> acMonthly;
    public List<Object> solradMonthly;
    public List<Object> dcMonthly;
    
    public SolarEnergyDataWrapper(List<Object> poaMonthly, List<Object> acMonthly, List<Object> solradMonthly, List<Object> dcMonthly) {
        this.poaMonthly = poaMonthly;
        this.acMonthly = acMonthly;
        this.solradMonthly = solradMonthly;
        this.dcMonthly = dcMonthly;
    }
}
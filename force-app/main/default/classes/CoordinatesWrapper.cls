public class CoordinatesWrapper {
    @AuraEnabled
    public String latitude;
    @AuraEnabled
    public String longitude;
    
    public CoordinatesWrapper(String latitude, String longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }
}
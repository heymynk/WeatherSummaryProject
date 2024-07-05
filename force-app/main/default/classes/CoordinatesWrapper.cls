/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 07-05-2024
 * @last modified by  : Mayank Singh
**/
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
public class TwitterAuth {
    public static Twitter_API_Setting__mdt getTwitterSettings() {
        System.debug('Fetching Twitter API settings from Custom Metadata');

        // Fetch the custom metadata records
        List<Twitter_API_Setting__mdt> settingsList = [SELECT Consumer_Key__c, Consumer_Secret__c FROM Twitter_API_Setting__mdt LIMIT 1];
        
        if (settingsList.isEmpty()) {
            System.debug('Error: Twitter API settings not found');
            throw new AuraHandledException('Twitter API settings not found. Please ensure the metadata record exists.');
        }
        
        Twitter_API_Setting__mdt settings = settingsList[0];
        System.debug('Twitter API settings retrieved successfully');
        System.debug('Settings' +settings);
        return settings;
    }
}

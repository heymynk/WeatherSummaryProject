/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 05-27-2024
 * @last modified by  : Mayank Singh
**/
public class TwitterPost_Utility {
    public static void twitterPost(String ApiKey, String ApiSecret, String AccessToken, String AccessTokenSecret, String message) {
        if (String.isNotBlank(ApiKey) && String.isNotBlank(ApiSecret) && String.isNotBlank(AccessToken) && String.isNotBlank(AccessTokenSecret) && String.isNotBlank(message)) {
            String oathNonce = TwitterPost_Utility.generateOathNonce();
            Long timestamp = TwitterPost_Utility.generateTimeStamp();
            String signature = '';

            message = EncodingUtil.urlEncode(message, 'UTF-8');
            String othSecret = EncodingUtil.urlEncode(AccessTokenSecret, 'UTF-8');
            String consumSecret = EncodingUtil.urlEncode(ApiSecret, 'UTF-8');
            String othToken = EncodingUtil.urlEncode(AccessToken, 'UTF-8');
            String othNonce = EncodingUtil.urlEncode(oathNonce, 'UTF-8');
            String consumKey = EncodingUtil.urlEncode(ApiKey, 'UTF-8');
            message = message.replaceAll('\\+','%20');
            String paramString = 'include_entities=true&'+
                                 'oauth_consumer_key='+consumKey+'&'+
                                 'oauth_nonce='+othNonce+'&'+
                                 'oauth_signature_method=HMAC-SHA1&'+
                                 'oauth_timestamp='+timestamp+'&'+
                                 'oauth_token='+othToken+'&'+
                                 'oauth_version=1.0&'+
                                 'status='+message;
            String baseString = 'POST&'+EncodingUtil.urlEncode('https://api.twitter.com/1.0/statuses/update.json', 'UTF-8')+'&'+        
                  EncodingUtil.urlEncode(paramString, 'UTF-8');
            System.debug('### baseString :'+baseString);
            String signString = consumSecret+'&'+othSecret;
            System.debug('### signString :'+signString);
            Blob blobBaseString = Blob.valueOf(baseString);
            Blob blobSignString = Blob.valueOf(signString);
            Blob signBlob = Crypto.generateMac('hmacSHA1', blobBaseString, blobSignString);        
            signature = EncodingUtil.base64Encode(signBlob);
            System.debug('### Sign :'+signature);

            if (String.isNotBlank(signature)) {
                signature = EncodingUtil.urlEncode(signature, 'UTF-8');
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://api.twitter.com/1.1/statuses/update.json?include_entities=true');
                req.setMethod('POST');
                String reqString = 'OAuth oauth_consumer_key="'+consumKey+'",'+
                                   'oauth_nonce="'+othNonce+'",'+
                                   'oauth_signature="'+signature +'",'+
                                   'oauth_signature_method="HMAC-SHA1",'+
                                   'oauth_timestamp="'+timestamp+'",'+
                                   'oauth_token="'+othToken+'",'+
                                   'oauth_version="1.0"';
                System.debug('### req String :'+reqString);
                req.setHeader('Authorization', reqString);
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                req.setBody('status='+message);

                if (!Test.isRunningTest()) {
                    Http http = new Http();
                    HttpResponse res = http.send(req);
                    System.debug(res.getBody());
                }
            }
        }
    }

    public static String generateOathNonce() {
        Blob blobKey = Crypto.generateAesKey(256);
        String key = EncodingUtil.convertToHex(blobKey);
        String oathNonce = EncodingUtil.base64Encode(Blob.valueOf(key));
        oathNonce = oathNonce.replaceAll('[^a-zA-Z0-9]+',''+Integer.valueOf(Math.random() * 10));
        oathNonce = oathNonce.substring(0,42);
        return oathNonce;
    }

    // method to generate current timestamp in seconds
    public static long generateTimeStamp() {
        long timestamp = DateTime.now().getTime(); 
        timestamp = timestamp / 1000;
        return timestamp;
    }
}

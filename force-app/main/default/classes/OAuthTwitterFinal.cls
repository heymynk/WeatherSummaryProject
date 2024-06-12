public class OAuthTwitterFinal {
    
    public static HttpRequest signRequest(HttpRequest req, String consumerKey, String oauthToken, String consumerSecret) {
        String nonce = String.valueOf(Crypto.getRandomLong());
        String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        
        Map<String, String> parameters = new Map<String, String>();
        parameters.put('oauth_consumer_key', consumerKey);
        if (oauthToken != null) {
            parameters.put('oauth_token', oauthToken);
        }
        parameters.put('oauth_signature_method', 'HMAC-SHA1');
        parameters.put('oauth_timestamp', timestamp);
        parameters.put('oauth_nonce', nonce);
        parameters.put('oauth_version', '1.0');
        
        String signature = generateSignature(req, consumerSecret, oauthToken, parameters);
        String header = generateHeader(signature, parameters);
        req.setHeader('Authorization', header);
        return req;
    }
    
    private static String generateHeader(String signature, Map<String, String> parameters) {
        String header = 'OAuth ';
        for (String key : parameters.keySet()) {
            header = header + key + '="' + EncodingUtil.urlEncode(parameters.get(key), 'UTF-8') + '", ';
        }
        return header + 'oauth_signature="' + EncodingUtil.urlEncode(signature, 'UTF-8') + '"';
    }
    
    private static String generateSignature(HttpRequest req, String consumerSecret, String tokenSecret, Map<String, String> parameters) {
        String s = createBaseString(parameters, req);
        String signingKey = EncodingUtil.urlEncode(consumerSecret, 'UTF-8') + '&' + (tokenSecret != null ? EncodingUtil.urlEncode(tokenSecret, 'UTF-8') : '');
        Blob sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(s), Blob.valueOf(signingKey));
        return EncodingUtil.base64Encode(sig);
    }
    
    private static String createBaseString(Map<String, String> oauthParams, HttpRequest req) {
        Map<String, String> p = oauthParams.clone();
        
        if (req.getMethod().equalsIgnoreCase('post') && req.getBody() != null) {
            p.putAll(getUrlParams(req.getBody()));
        }
        
        String host = req.getEndpoint();
        Integer n = host.indexOf('?');
        if (n > -1) {
            p.putAll(getUrlParams(host.substring(n + 1)));
            host = host.substring(0, n);
        }
        
        List<String> keys = new List<String>();
        keys.addAll(p.keySet());
        keys.sort();
        
        String s = '';
        for (Integer i = 0; i < keys.size(); i++) {
            if (i > 0) {
                s += '&';
            }
            s += keys.get(i) + '=' + p.get(keys.get(i));
        }
        
        return req.getMethod().toUpperCase() + '&' +
               EncodingUtil.urlEncode(host, 'UTF-8') + '&' +
               EncodingUtil.urlEncode(s, 'UTF-8');
    }
    
    private static Map<String, String> getUrlParams(String value) {
        Map<String, String> res = new Map<String, String>();
        if (value == null || value == '') {
            return res;
        }
        for (String s : value.split('&')) {
            List<String> kv = s.split('=');
            if (kv.size() > 1) {
                String encName = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[0], 'UTF-8'), 'UTF-8').replace('+', '%20');
                String encValue = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[1], 'UTF-8'), 'UTF-8').replace('+', '%20');
                res.put(encName, encValue);
            }
        }
        return res;
    }
}
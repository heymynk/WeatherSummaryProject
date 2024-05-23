/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 05-16-2024
 * @last modified by  : Mayank Singh
**/
public class HttpHelper {
    public static HttpResponse sendGetRequest(String endPoint) {
        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('GET');
        httpReq.setEndpoint(endPoint);
        httpReq.setHeader('content-type', 'application/json');

        try {
            HttpResponse response = http.send(httpReq);
            if (response.getStatusCode() == 200) {
                return response;
            } else {
                System.debug('Error: ' + response.getStatus() + ' Status code: ' + response.getStatusCode());
            }
        } catch (System.CalloutException e) {
            System.debug('Error: ' + e.getMessage());
        }
        return null;
    }

    public static HttpResponse sendPostRequest(String endPoint, String body, String apiKey) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        req.setBody(body);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                return res;
            } else {
                System.debug('Error response: ' + res.getBody());
            }
        } catch (System.CalloutException e) {
            System.debug('Error: ' + e.getMessage());
        }
        return null;
    }   
}
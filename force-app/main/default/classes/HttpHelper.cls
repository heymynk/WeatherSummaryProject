/**
 * @description       : 
 * @author            : Mayank Singh
 * @group             : 
 * @last modified on  : 07-08-2024
 * @last modified by  : Mayank Singh
**/
public class HttpHelper {

    public static HttpResponse sendGetRequestCompany(String endpoint, String apiKey) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);

        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('accept', 'application/json');
        request.setTimeout(40000);
        request.setHeader('X-API-Key', apiKey);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                return response;
            } else {
                System.debug('HTTP Request failed with status code: ' + response.getStatusCode());
            }
        } catch (System.CalloutException e) {
            System.debug('HTTP Request failed: ' + e.getMessage());
        }
        return null;
    }

    public static HttpResponse sendGetRequest(String endPoint) {
        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('GET');
        httpReq.setTimeout(40000);
        httpReq.setEndpoint(endPoint);
        httpReq.setHeader('Content-Type', 'application/json');

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
        req.setTimeout(40000);
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
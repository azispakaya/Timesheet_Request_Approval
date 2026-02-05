public with sharing class N8N_Utils {
  /**
   * N8N_Utils is a utility class for making HTTP requests to an N8N workflow.
   * It provides methods to send requests with a specified method, path, and payload.
   */
  private final String Method;
  private final String path;
  private final String Payload;

  public N8N_Utils(String method, String path, String Payload) {
    this.Method = method;
    this.path = path;
    this.Payload = Payload;
  }
  public HttpResponse sendRequest() {
    try {
      HttpRequest req = new HttpRequest();
      //   String jsonPayload = '';
      if (String.isNotBlank(Payload)) {
        // jsonPayload = JSON.serialize(payload);
        req.setBody(Payload);
      }

      System.debug('Request Payload: ' + Payload);

      req.setHeader('Content-Type', 'application/json');
      req.setEndpoint(uriFormatted(path));
      req.setTimeout(120000);
      req.setMethod(Method);

      Http http = new Http();
      HTTPResponse res = http.send(req);
      System.debug(res.getBody());

      return res;
    } catch (Exception e) {
      System.debug('Error making callout: ' + e);
      throw new CustomException('Error making callout: ' + e.getMessage());
    }
  }

  private String uriFormatted(String path) {
    // return 'callout:n8n_webhook_prod/' + path;
    return '' + System.label.n8n_callout_url + path;
  }

  public static Boolean checkingPayload(Map<String, String> mapToCheck) {
    return mapToCheck != null && !mapToCheck.isEmpty();
  }

  // Custom exception class
  public class CustomException extends Exception {
  }
}

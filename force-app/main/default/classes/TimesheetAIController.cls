public with sharing class TimesheetAIController {
  private static final String N8N_METHOD = 'POST';
  private static final String N8N_PATH = '/timesheet/remark/generate';

  // ====== DTOs ======
  public class GenerateRemarkRequest {
    @AuraEnabled
    public String ObjectRecordId { get; set; }
    @AuraEnabled
    public String type { get; set; } // 'case' | 'project' | 'poc' | 'opty' | 'campaign'
    @AuraEnabled
    public String remark { get; set; }
    @AuraEnabled
    public String start_date { get; set; }
    @AuraEnabled
    public String end_date { get; set; }
    @AuraEnabled
    public String stime { get; set; }
    @AuraEnabled
    public String EmployeeID { get; set; }
  }

  public class GenerateRemarkResponse {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public Integer httpStatus;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String suggestedRemark;
    @AuraEnabled
    public String raw;
  }

  // ====== Internal type config ======
  private class TypeConfig {
    String objectApiName;
    List<String> fields;
    TypeConfig(String obj, List<String> f) {
      objectApiName = obj;
      fields = f;
    }
  }

  // single source of truth (no if spam)
  private static final Map<String, TypeConfig> TYPE_CFG = new Map<String, TypeConfig>{
    'case' => new TypeConfig(
      'Case',
      new List<String>{
        'Id',
        'CaseNumber',
        'Subject',
        'Status',
        'Description',
        'Summary__c'
      }
    ),
    'project' => new TypeConfig(
      'Project__c',
      new List<String>{
        'Id',
        'Name',
        'SPK__c',
        'Status__c',
        'Overview__c',
        'Assumptions__c'
      }
    ),
    'poc' => new TypeConfig(
      'POC__c',
      new List<String>{
        'Id',
        'Name',
        'POC_Number__c',
        'Status__c',
        'Description__c',
        'Objective__c',
        'Scope_of_POC__c'
      }
    ),
    'opty' => new TypeConfig(
      'Opportunity',
      new List<String>{ 'Id', 'Name', 'StageName', 'Amount', 'CloseDate' }
    ),
    'campaign' => new TypeConfig(
      'Campaign',
      new List<String>{ 'Id', 'Name', 'Status', 'StartDate', 'EndDate' }
    )
  };

  // ====== PUBLIC API for LWC ======
  @AuraEnabled
  public static GenerateRemarkResponse generateTimesheetRemark(
    String payloadJson
  ) {
    GenerateRemarkResponse out = new GenerateRemarkResponse();
    out.success = false;
    out.httpStatus = 0;

    String rawReq = JSON.serialize(JSON.deserializeUntyped(payloadJson));
    GenerateRemarkRequest req = (GenerateRemarkRequest) JSON.deserialize(
      rawReq,
      GenerateRemarkRequest.class
    );

    System.debug(
      'TimesheetAIController.generateTimesheetRemark called with: ' + req
    );

    // System.debug(
    //   'TimesheetAIController.generateTimesheetRemark called with: ' + req
    // );

    try {
      if (req == null)
        return fail(out, 400, 'Invalid request.');
      if (String.isBlank(req.ObjectRecordId) || String.isBlank(req.type)) {
        return fail(out, 400, 'Missing required fields: ObjectRecordId/type.');
      }

      String typeKey = req.type.trim().toLowerCase();
      TypeConfig cfg = TYPE_CFG.get(typeKey);
      if (cfg == null)
        return fail(out, 400, 'Unsupported timesheet type: ' + req.type);

      // Validate ID format early (basic hardening)
      if (!isValidSfId(req.ObjectRecordId)) {
        return fail(out, 400, 'Invalid ObjectRecordId format.');
      }

      // fetch record safely (sharing + OLS + FLS)
      Map<String, Object> recordMap = fetchRecordForPayload(
        cfg,
        req.ObjectRecordId
      );

      // Build payload for n8n (simple + enriched)
      Map<String, Object> payload = new Map<String, Object>{
        'ObjectRecordId' => req.ObjectRecordId,
        'type' => typeKey,
        'remark' => req.remark,
        'start_date' => req.start_date,
        'end_date' => req.end_date,
        'stime' => req.stime,
        'EmployeeID' => req.EmployeeID,
        'record' => recordMap // <— enriched data (already sanitized)
      };

      String jsonPayload = JSON.serialize(payload);

      N8N_Utils client = new N8N_Utils(N8N_METHOD, N8N_PATH, jsonPayload);
      HttpResponse res = client.sendRequest();

      out.httpStatus = (res != null) ? res.getStatusCode() : 0;
      out.raw = (res != null) ? res.getBody() : null;

      if (res == null)
        return fail(out, 502, 'No response from AI service.');
      if (out.httpStatus < 200 || out.httpStatus >= 300) {
        return fail(
          out,
          out.httpStatus,
          'AI service failed. Please try again.'
        );
      }

      // robust parse:
      // - if n8n returns plain text -> use it
      // - if returns JSON -> try read suggestedRemark
      String suggestion = extractSuggestedRemark(res.getBody());
      if (String.isBlank(suggestion)) {
        return fail(
          out,
          out.httpStatus,
          'AI generated an empty remark. Please try again.'
        );
      }

      out.success = true;
      out.message = 'OK';
      out.suggestedRemark = suggestion.trim();
      return out;
    } catch (Exception e) {
      // jangan expose detail sensitif ke user
      System.debug('TimesheetAIController error: ' + e);
      Integer code = (out.httpStatus != null &&
        out.httpStatus != 0)
        ? out.httpStatus
        : 500;
      return fail(
        out,
        code,
        'Something went wrong while generating the remark.'
      );
    }
  }

  public static Map<String, Object> fetchRecordForPayload(
    TypeConfig cfg,
    String recordIdStr
  ) {
    Schema.SObjectType sType = Schema.getGlobalDescribe()
      .get(cfg.objectApiName);
    if (sType == null)
      throw new AuraHandledException(
        'Unsupported object: ' + cfg.objectApiName
      );

    Schema.DescribeSObjectResult d = sType.getDescribe();
    if (!d.isAccessible()) {
      throw new AuraHandledException(
        'You are not authorized to access this record.'
      );
    }

    // optional: keyPrefix check (anti spoof)
    String keyPrefix = d.getKeyPrefix();
    if (
      !String.isBlank(keyPrefix) && !recordIdStr.startsWithIgnoreCase(keyPrefix)
    ) {
      throw new AuraHandledException(
        'Record type does not match the selected timesheet type.'
      );
    }

    // FLS safe fields
    Map<String, Schema.SObjectField> fieldsMap = d.fields.getMap();
    List<String> safeFields = new List<String>();
    for (String f : cfg.fields) {
      Schema.SObjectField sf = fieldsMap.get(f);
      if (sf != null && sf.getDescribe().isAccessible())
        safeFields.add(f);
    }
    if (!safeFields.contains('Id'))
      safeFields.add('Id');

    String soql =
      'SELECT ' +
      String.join(safeFields, ',') +
      ' FROM ' +
      cfg.objectApiName +
      ' WHERE Id = :recordIdStr' + // ⚠️ BONUS FIX: Use bind variable
      ' LIMIT 1';

    List<SObject> rows = Database.query(soql);
    if (rows.isEmpty()) {
      throw new AuraHandledException(
        cfg.objectApiName + ' not found for Id: ' + recordIdStr
      );
    }

    // ✅ CORRECTED:
    SObjectAccessDecision decision = Security.stripInaccessible(
      AccessType.READABLE,
      rows
    );
    List<SObject> safeRecords = decision.getRecords();

    SObject sanitized = safeRecords.isEmpty() ? null : safeRecords[0];
    if (sanitized == null) {
      throw new AuraHandledException('Record not accessible.');
    }

    Map<String, Object> immutableMap = sanitized.getPopulatedFieldsAsMap();
    Map<String, Object> mutableResult = new Map<String, Object>();
    mutableResult.putAll(immutableMap); // Deep copy
    mutableResult.put('Id', sanitized.get('Id')); // ✅ Safe
    return mutableResult;
  }

  // ====== Helpers ======
  private static Boolean isValidSfId(String s) {
    // basic SF Id validation: 15 or 18 alnum
    if (String.isBlank(s))
      return false;
    Integer len = s.length();
    if (len != 15 && len != 18)
      return false;
    return Pattern.matches('^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$', s);
  }

  private static String extractSuggestedRemark(String body) {
    if (String.isBlank(body))
      return null;

    // try JSON first
    try {
      Object o = JSON.deserializeUntyped(body);
      if (o instanceof Map<String, Object>) {
        Map<String, Object> m = (Map<String, Object>) o;
        // support multiple possible keys from n8n
        if (m.containsKey('suggestedRemark'))
          return String.valueOf(m.get('suggestedRemark'));
        if (m.containsKey('remark'))
          return String.valueOf(m.get('remark'));
        if (m.containsKey('text'))
          return String.valueOf(m.get('text'));
      }
    } catch (Exception ignore) {
    }

    // fallback: plain text
    return body;
  }

  private static GenerateRemarkResponse fail(
    GenerateRemarkResponse out,
    Integer status,
    String msg
  ) {
    out.success = false;
    out.httpStatus = status;
    out.message = String.isBlank(msg) ? 'Unknown error.' : msg;
    return out;
  }
}

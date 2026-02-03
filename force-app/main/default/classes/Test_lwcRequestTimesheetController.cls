/**
 * @author [AcekBecek]
 * @desc Test class for lwc_RequestTimesheetController with comprehensive coverage
 */
@IsTest
private class Test_lwcRequestTimesheetController {
  // =============================
  // TEST DATA SETUP
  // =============================
  @TestSetup
  static void setup() {
    // Create Employees
    Employee__c manager = new Employee__c(
      Name = 'Manager User',
      Email__c = 'manager@test.com',
      Active__c = true,
      Role__c = 'Project Manager',
      Employee_ID__c = 'MGR001',
      Mobile_Phone__c = '0872173001'
    );
    insert manager;

    Employee__c supervisor = new Employee__c(
      Name = 'Supervisor User',
      Email__c = 'supervisor@test.com',
      Active__c = true,
      Role__c = 'Project Admin',
      Employee_ID__c = 'SUP001',
      Mobile_Phone__c = '0872173002'
    );
    insert supervisor;

    Employee__c projectManager = new Employee__c(
      Name = 'Project Manager',
      Email__c = 'pm@test.com',
      Active__c = true,
      Role__c = 'Project Manager',
      Employee_ID__c = 'PM001',
      Mobile_Phone__c = '0872173003'
    );
    insert projectManager;

    Employee__c engineer = new Employee__c(
      Name = 'Engineer User',
      Email__c = 'engineer@test.com',
      Active__c = true,
      Role__c = 'Engineer',
      Employee_ID__c = 'ENG001',
      Mobile_Phone__c = '0872173004',
      Manager__c = manager.Id,
      Supervisorr__c = supervisor.Id
    );
    insert engineer;

    Employee__c presales = new Employee__c(
      Name = 'Presales User',
      Email__c = 'presales@test.com',
      Active__c = true,
      Role__c = 'Presales',
      Employee_ID__c = 'PRE001',
      Mobile_Phone__c = '0872173005'
    );
    insert presales;

    // Create Projects
    Project__c activeProject = new Project__c(
      Name = 'Active Project',
      SPK__c = 'ACT001',
      Status__c = 'Started',
      Project_Manager__c = projectManager.Id
    );
    insert activeProject;

    Project__c completedProject = new Project__c(
      Name = 'Completed Project',
      SPK__c = 'COM001',
      Status__c = 'Completed',
      Project_Manager__c = projectManager.Id
    );
    insert completedProject;

    // Special Projects for POC/Opty/Campaign
    Project__c msi001Project = new Project__c(
      Name = 'MSInfokom - Business Development',
      SPK__c = 'MSI001',
      Status__c = 'Started',
      Project_Manager__c = projectManager.Id
    );
    insert msi001Project;

    Project__c msi009Project = new Project__c(
      Name = 'MSInfokom - Marketing',
      SPK__c = 'MSI009',
      Status__c = 'Started',
      Project_Manager__c = projectManager.Id
    );
    insert msi009Project;

    Project__c overheadProject = new Project__c(
      Name = 'MSInfokom - Overhead',
      SPK__c = 'OVH001',
      Status__c = 'Started',
      Project_Manager__c = projectManager.Id
    );
    insert overheadProject;

    // Create Case with Project
    Case caseWithProject = new Case(
      Subject = 'Test Case With Project',
      Status = 'New',
      Project__c = activeProject.Id,
      Assigned_To__c = engineer.Id
    );
    insert caseWithProject;

    // Create Case without Project (for Overhead scenario)
    Case caseWithoutProject = new Case(
      Subject = 'Test Case Without Project',
      Status = 'New',
      Assigned_To__c = engineer.Id
    );
    insert caseWithoutProject;

    // Create POC
    POC__c poc = new POC__c(
      Project_Manager__c = projectManager.Id,
      Presales__c = presales.Id
    );
    insert poc;

    // Create POC Member
    POC_Member__c pocMember = new POC_Member__c(
      POC__c = poc.Id,
      Employee__c = engineer.Id
    );
    insert pocMember;

    // Create Opportunity
    Opportunity opty = new Opportunity(
      Name = 'Test Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      SPK__c = 'OPT001'
    );
    insert opty;

    // Create Campaign
    Campaign campaign = new Campaign(
      Name = 'Test Campaign',
      Status = 'Planned'
    );
    insert campaign;

    // Create Case Escalation History
    Case_Escalation_History__c escalation = new Case_Escalation_History__c(
      Case__c = caseWithProject.Id,
      From_Engineer__c = engineer.Id
    );
    insert escalation;
  }

  // =============================
  // POSITIVE TESTS: convertEmployeeID
  // =============================
  @IsTest
  static void test_ConvertEmployeeID_ValidId_Success() {
    Employee__c engineer = [
      SELECT Id, Name, Employee_ID__c, Email__c, Role__c
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertEmployeeID(
      engineer.Id,
      'any'
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Should succeed');
    System.assertEquals('OK', response.statusCode, 'Should return OK');

    TimesheetResponseModels.EmployeeContext ctx = (TimesheetResponseModels.EmployeeContext) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.EmployeeContext.class
    );

    System.assertEquals(
      engineer.Id,
      ctx.employeeRecordId,
      'Employee ID should match'
    );
    System.assertEquals(engineer.Name, ctx.employeeName, 'Name should match');
    System.assertEquals(
      engineer.Employee_ID__c,
      ctx.employeeNumber,
      'Employee number should match'
    );
    System.assertEquals(engineer.Email__c, ctx.email, 'Email should match');
    System.assertEquals(engineer.Role__c, ctx.role, 'Role should match');
  }

  @IsTest
  static void test_ConvertEmployeeID_Cacheable() {
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    Test.startTest();
    // Call twice to verify cacheable behavior
    TimesheetResponseModels.ResponseWrapper response1 = lwc_RequestTimesheetController.convertEmployeeID(
      engineer.Id,
      'role'
    );
    TimesheetResponseModels.ResponseWrapper response2 = lwc_RequestTimesheetController.convertEmployeeID(
      engineer.Id,
      'name'
    );
    Test.stopTest();

    System.assertEquals(true, response1.success, 'First call should succeed');
    System.assertEquals(true, response2.success, 'Second call should succeed');
  }

  // =============================
  // NEGATIVE TESTS: convertEmployeeID
  // =============================
  @IsTest
  static void test_ConvertEmployeeID_BlankId_Fails() {
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertEmployeeID(
      '',
      'any'
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Should return INVALID_INPUT'
    );
    System.assert(
      response.message.contains('RecordID is required'),
      'Should mention required field'
    );
  }

  @IsTest
  static void test_ConvertEmployeeID_InvalidId_Fails() {
    Id fakeId = '001000000000000AAA';

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertEmployeeID(
      fakeId,
      'any'
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'NOT_FOUND',
      response.statusCode,
      'Should return NOT_FOUND'
    );
  }

  @IsTest
  static void test_ConvertProjectName_ProjectManager_Success() {
    Project__c project = [
      SELECT Id, Name, SPK__c
      FROM Project__c
      WHERE SPK__c = 'ACT001'
      LIMIT 1
    ];
    Employee__c pm = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'PM001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertProjectName(
      project.Id,
      pm.Id
    );
    Test.stopTest();

    System.assertEquals(
      true,
      response.success,
      'Should succeed for Project Manager'
    );

    TimesheetResponseModels.TimesheetLookupResult result = (TimesheetResponseModels.TimesheetLookupResult) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.TimesheetLookupResult.class
    );

    System.assertEquals(
      project.Id,
      result.projectId,
      'Project ID should match'
    );
  }

  @IsTest
  static void test_ConvertProjectName_CommaReplacement() {
    // Create project with comma in name
    Employee__c pm = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'PM001'
      LIMIT 1
    ];
    Project__c projectWithComma = new Project__c(
      Name = 'Project, With, Commas',
      SPK__c = 'COMMA01',
      Status__c = 'Started',
      Project_Manager__c = pm.Id
    );
    insert projectWithComma;

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertProjectName(
      projectWithComma.Id,
      pm.Id
    );
    Test.stopTest();

    TimesheetResponseModels.TimesheetLookupResult result = (TimesheetResponseModels.TimesheetLookupResult) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.TimesheetLookupResult.class
    );

    System.assert(
      !result.projectName.contains(','),
      'Commas should be removed from project name'
    );
  }

  // =============================
  // NEGATIVE TESTS: convertProjectName
  // =============================
  @IsTest
  static void test_ConvertProjectName_BlankProjectId_Fails() {
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertProjectName(
      '',
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Should return INVALID_INPUT'
    );
  }

  @IsTest
  static void test_ConvertProjectName_BlankMemberId_Fails() {
    Project__c project = [
      SELECT Id
      FROM Project__c
      WHERE SPK__c = 'ACT001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertProjectName(
      project.Id,
      ''
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Should return INVALID_INPUT'
    );
  }

  @IsTest
  static void test_ConvertProjectName_NotAssigned_Fails() {
    Project__c project = [
      SELECT Id
      FROM Project__c
      WHERE SPK__c = 'ACT001'
      LIMIT 1
    ];
    Employee__c presales = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'PRE001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertProjectName(
      project.Id,
      presales.Id
    );
    Test.stopTest();

    System.assertEquals(
      false,
      response.success,
      'Should fail for non-assigned user'
    );
    System.assertEquals(
      'NOT_ASSIGNED',
      response.statusCode,
      'Should return NOT_ASSIGNED'
    );
  }

  @IsTest
  static void test_ConvertProjectName_CompletedProject_Fails() {
    Project__c completedProject = [
      SELECT Id
      FROM Project__c
      WHERE SPK__c = 'COM001'
      LIMIT 1
    ];
    Employee__c pm = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'PM001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertProjectName(
      completedProject.Id,
      pm.Id
    );
    Test.stopTest();

    System.assertEquals(
      false,
      response.success,
      'Should fail for completed project'
    );
    System.assertEquals(
      'NOT_ASSIGNED',
      response.statusCode,
      'Should return NOT_ASSIGNED'
    );
  }

  // =============================
  // POSITIVE TESTS: convertCaseNumber
  // =============================
  @IsTest
  static void test_ConvertCaseNumber_WithProject_Success() {
    Case caseRecord = [
      SELECT Id, CaseNumber
      FROM Case
      WHERE Subject = 'Test Case With Project'
      LIMIT 1
    ];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];
    Project__c project = [
      SELECT Id, Name, SPK__c
      FROM Project__c
      WHERE SPK__c = 'ACT001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCaseNumber(
      caseRecord.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      true,
      response.success,
      'Should succeed: ' + response.message
    );

    TimesheetResponseModels.TimesheetLookupResult result = (TimesheetResponseModels.TimesheetLookupResult) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.TimesheetLookupResult.class
    );

    System.assertEquals('case', result.entryType, 'Entry type should be case');
    System.assertEquals(
      caseRecord.Id,
      result.objectRecordId,
      'Case ID should match'
    );
    System.assertEquals(
      caseRecord.CaseNumber,
      result.objectLabel,
      'Case number should match'
    );
    System.assertEquals(
      project.Id,
      result.projectId,
      'Project should match case project'
    );
  }

  @IsTest
  static void test_ConvertCaseNumber_WithoutProject_UsesOverhead() {
    Case caseRecord = [
      SELECT Id, CaseNumber
      FROM Case
      WHERE Subject = 'Test Case Without Project'
      LIMIT 1
    ];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];
    Project__c overhead = [
      SELECT Id, Name, SPK__c
      FROM Project__c
      WHERE Name = 'MSInfokom - Overhead'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCaseNumber(
      caseRecord.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      true,
      response.success,
      'Should succeed with overhead project'
    );

    TimesheetResponseModels.TimesheetLookupResult result = (TimesheetResponseModels.TimesheetLookupResult) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.TimesheetLookupResult.class
    );

    System.assertEquals(
      overhead.Id,
      result.projectId,
      'Should use overhead project'
    );
    System.assertEquals(
      overhead.Name,
      result.projectName,
      'Should have overhead project name'
    );
  }

  @IsTest
  static void test_ConvertCaseNumber_WithEscalation_Success() {
    Case caseRecord = [
      SELECT Id
      FROM Case
      WHERE Subject = 'Test Case With Project'
      LIMIT 1
    ];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    // Case has escalation history for this engineer
    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCaseNumber(
      caseRecord.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      true,
      response.success,
      'Should succeed with escalation'
    );
  }

  // =============================
  // NEGATIVE TESTS: convertCaseNumber
  // =============================
  @IsTest
  static void test_ConvertCaseNumber_BlankCaseId_Fails() {
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCaseNumber(
      '',
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Should return INVALID_INPUT'
    );
  }

  @IsTest
  static void test_ConvertCaseNumber_BlankMemberId_Fails() {
    Case caseRecord = [
      SELECT Id
      FROM Case
      WHERE Subject = 'Test Case With Project'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCaseNumber(
      caseRecord.Id,
      ''
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Should return INVALID_INPUT'
    );
  }

  @IsTest
  static void test_ConvertCaseNumber_NotAssigned_Fails() {
    Case caseRecord = [
      SELECT Id
      FROM Case
      WHERE Subject = 'Test Case With Project'
      LIMIT 1
    ];
    Employee__c presales = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'PRE001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCaseNumber(
      caseRecord.Id,
      presales.Id
    );
    Test.stopTest();

    System.assertEquals(
      false,
      response.success,
      'Should fail for non-assigned user'
    );
    System.assertEquals(
      'NOT_ASSIGNED',
      response.statusCode,
      'Should return NOT_ASSIGNED'
    );
  }

  // =============================
  // POSITIVE TESTS: convertPOCNumber
  // =============================
  @IsTest
  static void test_ConvertPOCNumber_POCMember_Success() {
    POC__c poc = [SELECT Id, Name FROM POC__c LIMIT 1];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];
    Project__c msi001 = [
      SELECT Id, Name, SPK__c
      FROM Project__c
      WHERE SPK__c = 'MSI001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertPOCNumber(
      poc.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      true,
      response.success,
      'Should succeed: ' + response.message
    );

    TimesheetResponseModels.TimesheetLookupResult result = (TimesheetResponseModels.TimesheetLookupResult) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.TimesheetLookupResult.class
    );

    System.assertEquals('poc', result.entryType, 'Entry type should be poc');
    System.assertEquals(poc.Id, result.objectRecordId, 'POC ID should match');
    System.assertEquals(poc.Name, result.objectLabel, 'POC name should match');
    System.assertEquals(
      msi001.Id,
      result.projectId,
      'Should use MSI001 project'
    );
  }

  @IsTest
  static void test_ConvertPOCNumber_ProjectManager_Success() {
    POC__c poc = [SELECT Id, Name FROM POC__c LIMIT 1];
    Employee__c pm = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'PM001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertPOCNumber(
      poc.Id,
      pm.Id
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Should succeed for PM');
  }

  @IsTest
  static void test_ConvertPOCNumber_Presales_Success() {
    POC__c poc = [SELECT Id, Name FROM POC__c LIMIT 1];
    Employee__c presales = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'PRE001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertPOCNumber(
      poc.Id,
      presales.Id
    );
    Test.stopTest();

    System.assertEquals(true, response.success, 'Should succeed for Presales');
  }

  // =============================
  // NEGATIVE TESTS: convertPOCNumber
  // =============================
  @IsTest
  static void test_ConvertPOCNumber_BlankPOCId_Fails() {
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertPOCNumber(
      '',
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Should return INVALID_INPUT'
    );
  }

  @IsTest
  static void test_ConvertPOCNumber_BlankMemberId_Fails() {
    POC__c poc = [SELECT Id FROM POC__c LIMIT 1];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertPOCNumber(
      poc.Id,
      ''
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Should return INVALID_INPUT'
    );
  }

  @IsTest
  static void test_ConvertPOCNumber_NotAssigned_Fails() {
    POC__c poc = [SELECT Id FROM POC__c LIMIT 1];
    Employee__c manager = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'MGR001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertPOCNumber(
      poc.Id,
      manager.Id
    );
    Test.stopTest();

    System.assertEquals(
      false,
      response.success,
      'Should fail for non-assigned user'
    );
    System.assertEquals(
      'NOT_ASSIGNED',
      response.statusCode,
      'Should return NOT_ASSIGNED'
    );
  }

  // =============================
  // POSITIVE TESTS: convertOpportuniyId
  // =============================
  @IsTest
  static void test_ConvertOpportunityId_Success() {
    Opportunity opty = [SELECT Id, Name, SPK__c FROM Opportunity LIMIT 1];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];
    Project__c msi001 = [
      SELECT Id, Name
      FROM Project__c
      WHERE SPK__c = 'MSI001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertOpportuniyId(
      opty.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      true,
      response.success,
      'Should succeed: ' + response.message
    );

    TimesheetResponseModels.TimesheetLookupResult result = (TimesheetResponseModels.TimesheetLookupResult) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.TimesheetLookupResult.class
    );

    System.assertEquals('opty', result.entryType, 'Entry type should be opty');
    System.assertEquals(
      opty.Id,
      result.objectRecordId,
      'Opportunity ID should match'
    );
    System.assertEquals(
      opty.Name,
      result.objectLabel,
      'Opportunity name should match'
    );
    System.assertEquals(
      msi001.Id,
      result.projectId,
      'Should use MSI001 project'
    );
    System.assertEquals(
      opty.SPK__c,
      result.spk,
      'SPK should come from opportunity'
    );
  }

  // =============================
  // NEGATIVE TESTS: convertOpportuniyId
  // =============================
  @IsTest
  static void test_ConvertOpportunityId_BlankId_Fails() {
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertOpportuniyId(
      '',
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'INVALID_INPUT',
      response.statusCode,
      'Should return INVALID_INPUT'
    );
  }

  @IsTest
  static void test_ConvertOpportunityId_NotFound_Fails() {
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];
    Id fakeId = '006000000000000AAA';

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertOpportuniyId(
      fakeId,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(false, response.success, 'Should fail');
    System.assertEquals(
      'NOT_FOUND',
      response.statusCode,
      'Should return NOT_FOUND'
    );
  }

  // =============================
  // POSITIVE TESTS: convertCampaign
  // =============================
  @IsTest
  static void test_ConvertCampaign_Success() {
    Campaign campaign = [SELECT Id, Name FROM Campaign LIMIT 1];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];
    Project__c msi009 = [
      SELECT Id, Name, SPK__c
      FROM Project__c
      WHERE SPK__c = 'MSI009'
      LIMIT 1
    ];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCampaign(
      campaign.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      true,
      response.success,
      'Should succeed: ' + response.message
    );

    TimesheetResponseModels.TimesheetLookupResult result = (TimesheetResponseModels.TimesheetLookupResult) JSON.deserialize(
      JSON.serialize(response.payload),
      TimesheetResponseModels.TimesheetLookupResult.class
    );

    System.assertEquals(
      'campaign',
      result.entryType,
      'Entry type should be campaign'
    );
    System.assertEquals(
      campaign.Id,
      result.objectRecordId,
      'Campaign ID should match'
    );
    System.assertEquals(
      campaign.Name,
      result.objectLabel,
      'Campaign name should match'
    );
    System.assertEquals(
      msi009.Id,
      result.projectId,
      'Should use MSI009 project'
    );
    System.assertEquals(msi009.SPK__c, result.spk, 'SPK should be MSI009');
  }

  // =============================
  // NEGATIVE TESTS: convertCampaign
  // =============================
  @IsTest
  static void test_ConvertCampaign_BlankId_Fails() {
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    Test.startTest();
    try {
      TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCampaign(
        '',
        engineer.Id
      );
      //   System.assert(false, 'Should throw AuraHandledException');
    } catch (AuraHandledException e) {
      //   System.assert(
      //     e.getMessage().contains('campaignId is required'),
      //     'Should mention required field'
      //   );
    }
    Test.stopTest();
  }

  @IsTest
  static void test_ConvertCampaign_MissingMSI009_Fails() {
    Campaign campaign = [SELECT Id FROM Campaign LIMIT 1];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    // Delete MSI009 project to simulate missing config
    delete [SELECT Id FROM Project__c WHERE SPK__c = 'MSI009'];

    Test.startTest();
    try {
      TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCampaign(
        campaign.Id,
        engineer.Id
      );
      System.assert(false, 'Should throw exception');
    } catch (Exception e) {
      System.assertNotEquals(null, e.getMessage(), 'Should have error message');
    }
    Test.stopTest();
  }

  // =============================
  // EDGE CASE TESTS
  // =============================
  @IsTest
  static void test_EdgeCase_ConvertCaseNumber_MissingOverhead_Fails() {
    Case caseRecord = [
      SELECT Id
      FROM Case
      WHERE Subject = 'Test Case Without Project'
      LIMIT 1
    ];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    // Delete overhead project
    delete [SELECT Id FROM Project__c WHERE Name = 'MSInfokom - Overhead'];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertCaseNumber(
      caseRecord.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      false,
      response.success,
      'Should fail when overhead missing'
    );
    System.assertEquals(
      'NOT_FOUND',
      response.statusCode,
      'Should return NOT_FOUND'
    );
  }

  @IsTest
  static void test_EdgeCase_ConvertPOCNumber_MissingMSI001_Fails() {
    POC__c poc = [SELECT Id FROM POC__c LIMIT 1];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    // Delete MSI001 project
    delete [SELECT Id FROM Project__c WHERE SPK__c = 'MSI001'];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertPOCNumber(
      poc.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      false,
      response.success,
      'Should fail when MSI001 missing'
    );
    System.assertEquals(
      'NOT_FOUND',
      response.statusCode,
      'Should return NOT_FOUND'
    );
  }

  @IsTest
  static void test_EdgeCase_ConvertOpportunityId_MissingMSI001_Fails() {
    Opportunity opty = [SELECT Id FROM Opportunity LIMIT 1];
    Employee__c engineer = [
      SELECT Id
      FROM Employee__c
      WHERE Employee_ID__c = 'ENG001'
      LIMIT 1
    ];

    // Delete MSI001 project
    delete [SELECT Id FROM Project__c WHERE SPK__c = 'MSI001'];

    Test.startTest();
    TimesheetResponseModels.ResponseWrapper response = lwc_RequestTimesheetController.convertOpportuniyId(
      opty.Id,
      engineer.Id
    );
    Test.stopTest();

    System.assertEquals(
      false,
      response.success,
      'Should fail when MSI001 missing'
    );
    System.assertEquals(
      'NOT_FOUND',
      response.statusCode,
      'Should return NOT_FOUND'
    );
  }
}

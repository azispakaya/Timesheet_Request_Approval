/* eslint-disable no-confusing-arrow */
import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";

// Apex (wrapper-based)
import convertEmployeeID from "@salesforce/apex/lwc_RequestTimesheetController.convertEmployeeID";
import convertProjectName from "@salesforce/apex/lwc_RequestTimesheetController.convertProjectName";
import convertCaseNumber from "@salesforce/apex/lwc_RequestTimesheetController.convertCaseNumber";
import convertPOCNumber from "@salesforce/apex/lwc_RequestTimesheetController.convertPOCNumber";
import convertOpportuniyId from "@salesforce/apex/lwc_RequestTimesheetController.convertOpportuniyId";
import convertCampaign from "@salesforce/apex/lwc_RequestTimesheetController.convertCampaign";
import { CloseActionScreenEvent } from "lightning/actions";

import createMultiTimesheet from "@salesforce/apex/lwc_ApprovalTimesheetController.createMultiTimesheet";

export default class RequestTimesheet extends LightningElement {
  @api recordId; // Employee__c Id

  // ========= UI flags =========
  @track uiState = {
    isLoadingEmployee: false,
    isConvertingRow: false,
    isSaving: false,
    isSubmitting: false
  };

  // ========= Header / Role =========
  employeName = "Timesheet";
  employeeRole = true; // same behavior with your existing HTML
  selectedPicklist = "Project";

  // used by your HTML
  PicklistObject = [];

  // ========= Lists =========
  @track listProjects = [];
  @track listCases = [];
  @track listPOCs = [];
  @track listOpportunities = [];
  @track listCampaigns = [];

  // ========= employee context (from wrapper) =========
  @track employeeContext = {
    employeeRecordId: null,
    employeeName: "",
    employeeNumber: "",
    email: "",
    role: ""
  };

  // ========= Computed =========
  get desktopSupport() {
    return FORM_FACTOR !== "Small";
  }

  get mobileSupport() {
    return FORM_FACTOR === "Small";
  }

  // keep this for your HTML binding
  get isLoading() {
    return (
      this.uiState.isLoadingEmployee ||
      this.uiState.isSaving ||
      this.uiState.isSubmitting
    );
  }

  // empty state flag used by HTML (your "isVisible")
  get isVisible() {
    const totalRows =
      this.listProjects.length +
      this.listCases.length +
      this.listPOCs.length +
      this.listOpportunities.length +
      this.listCampaigns.length;
    return totalRows === 0;
  }

  // your HTML uses formFactorClass for desktop grid layout
  get formFactorClass() {
    // desktop uses your existing "row layout" class
    return "slds-grid slds-gutters_small";
  }

  // Count hours for header
  get countHours() {
    const allRows = this.getAllRows();
    let total = 0;

    allRows.forEach((rowItem) => {
      const value = Number(rowItem.stime);
      if (!Number.isNaN(value)) total += value;
    });

    return total;
  }

  // ========= Wire employee context =========
  @wire(convertEmployeeID, { RecordID: "$recordId", render: "loaddata" })
  wiredEmployeeContext(wireResult) {
    const { data, error } = wireResult;

    this.uiState.isLoadingEmployee = true;

    if (error) {
      const normalizedError = this.normalizeApexError(error);
      this.toast("Employee", normalizedError.message, "error");
      this.uiState.isLoadingEmployee = false;
      return;
    }

    if (data) {
      const responseWrapper = this.normalizeResponse(data);

      if (!responseWrapper.success) {
        this.toast(
          "Employee",
          responseWrapper.message || "Failed to load employee context.",
          "error"
        );
        this.uiState.isLoadingEmployee = false;
        return;
      }

      const payload = responseWrapper.payload || {};
      this.employeeContext = {
        employeeRecordId: payload.employeeRecordId || this.recordId,
        employeeName: payload.employeeName || "",
        employeeNumber: payload.employeeNumber || "",
        email: payload.email || "",
        role: payload.role || ""
      };

      this.employeName = this.employeeContext.employeeName || "Timesheet";
      this.applyRoleRules(this.employeeContext.role);

      this.uiState.isLoadingEmployee = false;
    }
  }

  applyRoleRules(roleValue) {
    const role = roleValue || "";

    if (role === "Presales") {
      this.employeeRole = false;
      this.selectedPicklist = "Opportunity";
      this.PicklistObject = [
        { label: "Opportunity", value: "Opportunity" },
        { label: "Project", value: "Project" },
        { label: "POC", value: "POC" }
      ];
      return;
    }

    if (role === "Marketing") {
      this.employeeRole = true;
      this.selectedPicklist = "Campaign";
      this.PicklistObject = [
        { label: "Campaign", value: "Campaign" },
        { label: "Project", value: "Project" }
      ];
      return;
    }

    // default
    this.employeeRole = true;
    this.selectedPicklist = "Project";
    this.PicklistObject = [
      { label: "Project", value: "Project" },
      { label: "Case", value: "Case" },
      { label: "POC", value: "POC" }
    ];
  }

  // ========= Header handlers (menu) =========
  setProjectHandler() {
    this.selectedPicklist = "Project";
  }
  setCaseHandler() {
    this.selectedPicklist = "Case";
  }
  setPOCHandler() {
    this.selectedPicklist = "POC";
  }
  setOptyHandler() {
    this.selectedPicklist = "Opportunity";
  }
  setCampaignHandler() {
    this.selectedPicklist = "Campaign";
  }

  // ========= Add row =========
  addNewHandler() {
    const typeLabel = this.selectedPicklist;
    this.addRowByTypeLabel(typeLabel);
  }

  addRowByTypeLabel(typeLabel) {
    const tempId = this.generateTempId();

    const newRow = {
      tempId,

      // lookup record selected by user
      objectRecordId: null,

      // resolved from Apex convert payload
      objectLabel: "",
      projectId: null,
      projectName: "",
      projectSpk: "",

      // approver info (optional, if you return them)
      approverId: null,
      approverOptionalId: null,

      // user fields
      date: null,
      stime: null,
      temp_remark: ""
    };

    if (typeLabel === "Project")
      this.listProjects = [...this.listProjects, newRow];
    if (typeLabel === "Case") this.listCases = [...this.listCases, newRow];
    if (typeLabel === "POC") this.listPOCs = [...this.listPOCs, newRow];
    if (typeLabel === "Opportunity")
      this.listOpportunities = [...this.listOpportunities, newRow];
    if (typeLabel === "Campaign")
      this.listCampaigns = [...this.listCampaigns, newRow];
  }

  // ========= Child events =========
  handleRowRemove(event) {
    try {
      const { tempId, entityType } = event.detail || {};
      if (!tempId || !entityType) return;

      // IMPORTANT: blur active element to prevent base-component focusing/validation crash
      const activeElement = this.template.activeElement;
      if (activeElement && typeof activeElement.blur === "function") {
        activeElement.blur();
      }

      if (entityType === "opty") {
        this.listOpportunities = (this.listOpportunities || []).filter(
          (row) => row.tempId !== tempId
        );
      } else if (entityType === "project") {
        this.listProjects = (this.listProjects || []).filter(
          (row) => row.tempId !== tempId
        );
      } else if (entityType === "case") {
        this.listCases = (this.listCases || []).filter(
          (row) => row.tempId !== tempId
        );
      } else if (entityType === "poc") {
        this.listPOCs = (this.listPOCs || []).filter(
          (row) => row.tempId !== tempId
        );
      } else if (entityType === "campaign") {
        this.listCampaigns = (this.listCampaigns || []).filter(
          (row) => row.tempId !== tempId
        );
      }

      // optional:
      // this.recalculateHours();
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("handleRowRemove crashed:", error);
    }
  }

  async handleRowFieldChange(event) {
    const { tempId, entityType, fieldName, value } = event.detail || {};
    if (!tempId || !entityType || !fieldName) return;

    console.log("handleRowFieldChange", JSON.stringify(event.detail, null, 2));

    // 1) always update local state first
    const patch = { [fieldName]: value };
    if (entityType === "project") {
      this.listProjects = this.updateRow(this.listProjects, tempId, patch);
    } else if (entityType === "case") {
      this.listCases = this.updateRow(this.listCases, tempId, patch);
    } else if (entityType === "poc") {
      this.listPOCs = this.updateRow(this.listPOCs, tempId, patch);
    } else if (entityType === "opty") {
      this.listOpportunities = this.updateRow(
        this.listOpportunities,
        tempId,
        patch
      );
    } else if (entityType === "campaign") {
      this.listCampaigns = this.updateRow(this.listCampaigns, tempId, patch);
    }

    // 2) if lookup changed -> trigger convert
    const isLookupField = fieldName === "objectRecordId";
    if (!isLookupField) return;

    const employeeMemberId =
      this.employeeContext.employeeRecordId || this.recordId;

    const resolvedPayload = await this.resolveLookup(
      entityType,
      value, // objectRecordId
      employeeMemberId
    );

    if (resolvedPayload) {
      // normalize if Apex doesn't return objectRecordId
      const payloadToApply = {
        ...resolvedPayload,
        objectRecordId: resolvedPayload.objectRecordId || value
      };

      this.applyResolvedPayloadToRow(entityType, tempId, payloadToApply);
    }
  }

  updateRow(list = [], tempId, patch = {}) {
    const rowIndex = list.findIndex((row) => row.tempId === tempId);
    if (rowIndex === -1) return list;

    const updatedRow = { ...list[rowIndex], ...patch };
    const clonedList = [...list];
    clonedList[rowIndex] = updatedRow;
    return clonedList;
  }

  recalculateHours() {
    const allRows = [
      ...(this.listOpportunities || []),
      ...(this.listProjects || []),
      ...(this.listCases || []),
      ...(this.listPOCs || []),
      ...(this.listCampaigns || [])
    ];

    const totalHours = allRows.reduce((sum, rowItem) => {
      const hoursValue = Number(rowItem.stime || 0);
      return sum + (Number.isFinite(hoursValue) ? hoursValue : 0);
    }, 0);

    this.countHours = totalHours;
  }

  // ========= Row update helpers =========
  updateRowValue(entityType, tempId, fieldName, value) {
    const updater = (rows) =>
      rows.map((rowItem) =>
        rowItem.tempId === tempId ? { ...rowItem, [fieldName]: value } : rowItem
      );

    if (entityType === "project")
      this.listProjects = updater(this.listProjects);
    if (entityType === "case") this.listCases = updater(this.listCases);
    if (entityType === "poc") this.listPOCs = updater(this.listPOCs);
    if (entityType === "opty")
      this.listOpportunities = updater(this.listOpportunities);
    if (entityType === "campaign")
      this.listCampaigns = updater(this.listCampaigns);
  }

  applyResolvedPayloadToRow(entityType, tempId, payload) {
    // payload shape recommended from Apex:
    // {
    //   objectRecordId,
    //   objectLabel,
    //   projectId,
    //   projectName,
    //   projectSpk,
    //   approverId,
    //   approverOptionalId
    // }

    const safePayload = payload || {};

    const patch = {
      objectLabel: safePayload.objectLabel || "",
      projectId: safePayload.projectId || null,
      projectName: safePayload.projectName || "",
      projectSpk: safePayload.projectSpk || "",
      approverId: safePayload.approverId || null,
      approverOptionalId: safePayload.approverOptionalId || null,

      // always keep selected objectRecordId if payload returns it
      objectRecordId: safePayload.objectRecordId || null
    };

    Object.keys(patch).forEach((fieldName) => {
      this.updateRowValue(entityType, tempId, fieldName, patch[fieldName]);
    });
  }

  // ========= Convert lookup via Apex =========
  async resolveLookup(entityType, objectRecordId, memberId) {
    if (!objectRecordId) return null;

    this.uiState.isConvertingRow = true;

    try {
      let rawResponse;

      if (entityType === "project") {
        rawResponse = await convertProjectName({
          ProjectID: objectRecordId,
          memberId
        });
      } else if (entityType === "case") {
        rawResponse = await convertCaseNumber({
          caseId: objectRecordId,
          memberId
        });
      } else if (entityType === "poc") {
        rawResponse = await convertPOCNumber({
          pocId: objectRecordId,
          memberId
        });
      } else if (entityType === "opty") {
        rawResponse = await convertOpportuniyId({
          OptyID: objectRecordId,
          memberId
        });
      } else if (entityType === "campaign") {
        rawResponse = await convertCampaign({
          campaignId: objectRecordId,
          memberId
        });
      } else {
        this.toast("Convert", `Unsupported type: ${entityType}`, "error");
        this.uiState.isConvertingRow = false;
        return null;
      }

      const responseWrapper = this.normalizeResponse(rawResponse);

      if (!responseWrapper.success) {
        this.toast(
          "Convert",
          responseWrapper.message || "Convert failed.",
          "error"
        );
        this.uiState.isConvertingRow = false;
        return null;
      }

      console.log(
        "convertLookup response",
        JSON.stringify(responseWrapper, null, 2)
      );

      this.uiState.isConvertingRow = false;
      return responseWrapper.payload || null;
    } catch (caughtError) {
      const normalizedError = this.normalizeApexError(caughtError);
      this.toast("Convert", normalizedError.message, "error");
      this.uiState.isConvertingRow = false;
      return null;
    }
  }

  // ========= Save / Submit =========
  async saveTimesheet() {
    await this.persistTimesheet("Draft");
  }

  async submitTimesheet() {
    await this.persistTimesheet("Waiting for Approval");
  }

  async persistTimesheet(statusValue) {
    // const isValid = this.validateAllInputs();
    // if (!isValid) {
    //   this.toast("Validation", "Please complete all required fields.", "error");
    //   return;
    // }

    const payloadList = this.buildCreateTimesheetPayload();
    // console.log("payloadList>>", JSON.stringify(payloadList, null, 2));

    if (payloadList.length === 0) {
      this.toast("Timesheet", "No entry to submit.", "warning");
      return;
    }

    const isSubmit = statusValue === "Submitted";
    this.uiState.isSubmitting = isSubmit;
    this.uiState.isSaving = !isSubmit;

    try {
      const rawResponse = await createMultiTimesheet({
        Timesheet: JSON.stringify(payloadList),
        ApprovalStatus: statusValue
      });

      const responseWrapper = this.normalizeResponse(rawResponse);

      if (!responseWrapper.success) {
        this.toast(
          "Timesheet",
          responseWrapper.message || "Failed to save.",
          "error"
        );
        this.uiState.isSubmitting = false;
        this.uiState.isSaving = false;
        return;
      }

      this.toast(
        "Success",
        responseWrapper.message || "Timesheet saved.",
        "success"
      );

      // Optional: clear rows after submit only
      if (isSubmit) {
        this.resetAllRows();
      }

      this.uiState.isSubmitting = false;
      this.uiState.isSaving = false;
      this.cancelHandler();
    } catch (caughtError) {
      const normalizedError = this.normalizeApexError(caughtError);
      this.toast("Timesheet", normalizedError.message, "error");
      this.uiState.isSubmitting = false;
      this.uiState.isSaving = false;
    }
  }

  cancelHandler() {
    // up to you: close quick action / modal / navigate back
    this.dispatchEvent(
      new CloseActionScreenEvent({ bubbles: true, composed: true })
    );
  }

  // ========= Validation =========
  validateAllInputs() {
    let isValid = true;

    // 1) Validate child rows (desktop)
    const rowComponents = this.template.querySelectorAll("c-timesheet-row");
    rowComponents.forEach((rowComponent) => {
      const childValid = rowComponent.reportValidity();
      if (!childValid) isValid = false;
    });

    // 2) Validate inline mobile inputs (mobile section uses direct inputs)
    // This will only find elements in parent template (mobile markup)
    const mobileInputs = this.template.querySelectorAll(
      "lightning-input.validated, lightning-textarea.validated, lightning-input-field.validated"
    );

    mobileInputs.forEach((inputElement) => {
      if (typeof inputElement.reportValidity === "function") {
        const ok = inputElement.reportValidity();
        if (!ok) isValid = false;
      }
    });

    return isValid;
  }

  // ========= Payload builder =========
  buildCreateTimesheetPayload() {
    const employeeId = this.employeeContext.employeeRecordId || this.recordId;

    const mapRowToRecord = (rowItem, entityType) => ({
      ProjectId: rowItem.projectId,
      Approver: rowItem.approverId,
      Approver_Optional: rowItem.approverOptionalId,
      start_date: rowItem.date,
      end_date: rowItem.date,
      stime: rowItem.stime,
      EmployeeID: employeeId,
      remark: rowItem.temp_remark,
      Email: this.employeeContext.email,
      type: entityType,
      ObjectRecordId: rowItem.objectRecordId
    });

    const records = []
      .concat(
        this.listProjects.map((rowItem) => mapRowToRecord(rowItem, "project"))
      )
      .concat(this.listCases.map((rowItem) => mapRowToRecord(rowItem, "case")))
      .concat(this.listPOCs.map((rowItem) => mapRowToRecord(rowItem, "poc")))
      .concat(
        this.listOpportunities.map((rowItem) => mapRowToRecord(rowItem, "opty"))
      )
      .concat(
        this.listCampaigns.map((rowItem) => mapRowToRecord(rowItem, "campaign"))
      );

    return records;
  }

  // ========= Utility =========
  getAllRows() {
    return []
      .concat(this.listProjects)
      .concat(this.listCases)
      .concat(this.listPOCs)
      .concat(this.listOpportunities)
      .concat(this.listCampaigns);
  }

  resetAllRows() {
    this.listProjects = [];
    this.listCases = [];
    this.listPOCs = [];
    this.listOpportunities = [];
    this.listCampaigns = [];
  }

  generateTempId() {
    return `${Date.now()}_${Math.random().toString(16).slice(2)}`;
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  normalizeResponse(apexData) {
    let responseObject = apexData;

    try {
      if (typeof apexData === "string") {
        responseObject = JSON.parse(apexData);
      }
    } catch (parseError) {
      return {
        success: false,
        code: "INVALID_RESPONSE",
        message: "Response is not valid JSON.",
        payload: null
      };
    }

    return {
      success: responseObject?.success === true,
      code: responseObject?.code,
      message: responseObject?.message,
      payload: responseObject?.payload
    };
  }

  normalizeApexError(apexError) {
    let message = "Unknown error.";
    let code = "APEX_ERROR";

    if (apexError?.body) {
      if (Array.isArray(apexError.body)) {
        message = apexError.body.map((item) => item.message).join(", ");
      } else if (typeof apexError.body.message === "string") {
        message = apexError.body.message;
      }
      code = apexError.body.errorCode || code;
    } else if (apexError?.message) {
      message = apexError.message;
    }

    return { code, message };
  }

  getListNameByEntityType(entityType) {
    const mapEntityToList = {
      opty: "listOpportunities",
      project: "listProjects",
      case: "listCases",
      poc: "listPOCs",
      campaign: "listCampaigns"
    };
    return mapEntityToList[entityType];
  }
}

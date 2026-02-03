/* eslint-disable no-confusing-arrow */
import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";

// Apex (wrapper-based)
import convertEmployeeID from "@salesforce/apex/lwc_RequestTimesheetController.convertEmployeeID";
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

  @track uiMessage = {
    visible: false,
    variant: "info", // error | warning | info
    title: "",
    message: ""
  };

  get uiMessageClass() {
    return `ts-msg ts-msg--${this.uiMessage.variant || "info"}`;
  }

  showMessage(variant, title, message) {
    this.uiMessage = {
      visible: true,
      variant: variant || "info",
      title: title || "Notice",
      message: message || ""
    };
  }

  clearMessage() {
    this.uiMessage = {
      visible: false,
      variant: "info",
      title: "",
      message: ""
    };
  }

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
      this.showMessage("error", "Employee", normalizedError.message);
      this.uiState.isLoadingEmployee = false;
      return;
    }

    if (data) {
      const responseWrapper = this.normalizeResponse(data);

      if (!responseWrapper.success) {
        this.showMessage(
          "error",
          "Employee",
          responseWrapper.message || "Failed to load employee context."
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

    // ---- get previous value (before we patch) ----
    const prevRow = this.getRowByTempId(entityType, tempId);
    const prevValue = prevRow ? prevRow[fieldName] : null;

    // ---- VALIDATION: stime (hours) ----
    if (fieldName === "stime") {
      const num = Number(value);

      // allow empty/null (user clearing input)
      if (
        value !== null &&
        value !== undefined &&
        value !== "" &&
        Number.isFinite(num)
      ) {
        if (num > 24) {
          const msg = "Hours cannot be more than 24 hours (1 day).";
          this.showMessage("error", "Validation", msg);
          this.notifyChildFieldError(tempId, "stime", msg, prevValue);
          this.revertRowField(entityType, tempId, fieldName, prevValue);
          return;
        }
        if (num < 0) {
          const msg = "Hours cannot be less than 0.";
          this.showMessage("error", "Validation", msg);
          this.notifyChildFieldError(tempId, "stime", msg, prevValue);
          this.revertRowField(entityType, tempId, fieldName, prevValue);
          return;
        }
        this.clearMessage();
      }
    }

    // ---- VALIDATION: date ----
    if (fieldName === "date") {
      // value biasanya "YYYY-MM-DD"
      if (value) {
        const selected = this.toLocalDate(value); // midnight local
        const today = this.getTodayLocal(); // midnight local
        const earliest = this.addDays(today, -7); // today - 7 days

        if (selected > today || selected < earliest) {
          const msg = "Date must be within the last 7 days (including today).";
          this.showMessage("error", "Validation", msg);
          this.notifyChildFieldError(tempId, "date", msg, prevValue);
          this.revertRowField(entityType, tempId, fieldName, prevValue);
          return;
        }
        this.clearMessage();
      }
    }
    const rowCmp = this.getChildRowComponent(tempId);
    if (rowCmp && typeof rowCmp.clearFieldError === "function") {
      rowCmp.clearFieldError(fieldName);
    }
    // 1) always update local state first (ONLY if valid)
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
  }

  handleRowLookupResolved(event) {
    const { tempId, entityType, payload } = event.detail || {};
    if (!tempId || !entityType) return;

    const safePayload = payload || {};

    // enforce objectRecordId exists
    const patch = {
      ...safePayload,
      objectRecordId:
        safePayload.objectRecordId ||
        this.getRowByTempId(entityType, tempId)?.objectRecordId ||
        null
    };

    this.applyResolvedPayloadToRow(entityType, tempId, patch);
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
      projectSpk: safePayload.spk || "",
      approverId: safePayload.approverId || null,
      approverOptionalId: safePayload.approverOptionalId || null,

      // always keep selected objectRecordId if payload returns it
      objectRecordId: safePayload.objectRecordId || null
    };

    Object.keys(patch).forEach((fieldName) => {
      this.updateRowValue(entityType, tempId, fieldName, patch[fieldName]);
    });
  }

  // ========= Save / Submit =========
  async saveTimesheet() {
    await this.persistTimesheet("Draft");
  }

  async submitTimesheet() {
    await this.persistTimesheet("Waiting for Approval");
  }

  async persistTimesheet(statusValue) {
    const payloadList = this.buildCreateTimesheetPayload();
    console.log("payloadList>>", JSON.stringify(payloadList, null, 2));
    console.log("isValid", this.uiMessage.visible);
    console.log("uiMessage", JSON.stringify(this.uiMessage, null, 2));
    return;
    // const isValid = this.validateAllInputs();
    // if (!isValid) {
    //   this.toast("Validation", "Please complete all required fields.", "error");
    //   return;
    // }

    if (payloadList.length === 0) {
      this.showMessage("warning", "Timesheet", "No entry to submit.");
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
        this.showMessage(
          "error",
          "Timesheet",
          responseWrapper.message || "Failed to save."
        );
        this.uiState.isSubmitting = false;
        this.uiState.isSaving = false;
        return;
      }
      this.clearMessage();

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
      //   remark: rowItem.temp_remark,
      remark: this.buildCombinedRemark(rowItem, entityType),
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

  buildCombinedRemark(rowItem, entityType) {
    const r = rowItem || {};

    console.log(
      "buildCombinedRemark rowItem",
      JSON.stringify(rowItem, null, 2)
    );

    // prefix rule:
    // - project => SPK (fallback projectName)
    // - others  => objectLabel (fallback objectRecordId)
    let prefix = "";

    if (entityType === "project") {
      prefix = (r.projectSpk || r.projectName || "").trim();
    } else {
      prefix = (r.objectLabel || r.objectRecordId || "").trim();
    }

    const note = (r.temp_remark || "").trim();

    // if both empty, return empty string
    if (!prefix && !note) return "";

    // if only one exists
    if (!prefix) return note;
    if (!note) return prefix;

    // both exist
    return `${prefix} - ${note}`;
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
    // Only allow SUCCESS toast per requirement
    if (variant !== "success") {
      this.showMessage(variant || "info", title, message);
      return;
    }
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

  getRowByTempId(entityType, tempId) {
    const list = this.getListByEntityType(entityType);
    return (list || []).find((r) => r.tempId === tempId) || null;
  }

  getListByEntityType(entityType) {
    if (entityType === "project") return this.listProjects;
    if (entityType === "case") return this.listCases;
    if (entityType === "poc") return this.listPOCs;
    if (entityType === "opty") return this.listOpportunities;
    if (entityType === "campaign") return this.listCampaigns;
    return [];
  }

  revertRowField(entityType, tempId, fieldName, prevValue) {
    // revert state ke value sebelumnya (atau null kalau gak ada)
    const patch = { [fieldName]: prevValue ?? null };

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
  }

  /** Convert "YYYY-MM-DD" to a local Date at 00:00:00 */
  toLocalDate(yyyyMmDd) {
    // safer parsing: split not relying on Date(string) quirks
    const [y, m, d] = (yyyyMmDd || "").split("-").map((x) => Number(x));
    if (!y || !m || !d) return null;
    return new Date(y, m - 1, d, 0, 0, 0, 0);
  }

  getTodayLocal() {
    const now = new Date();
    return new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      0,
      0,
      0,
      0
    );
  }

  addDays(dateObj, deltaDays) {
    const d = new Date(dateObj);
    d.setDate(d.getDate() + deltaDays);
    return d;
  }
  getChildRowComponent(tempId) {
    const nodes = this.template.querySelectorAll("c-timesheet-row");

    // console.log("nodes", JSON.stringify(nodes));
    return (
      Array.from(nodes).find((n) => String(n.tempid) === String(tempId)) || null
    );
  }

  notifyChildFieldError(tempId, fieldName, message, prevValue) {
    const rowCmp = this.getChildRowComponent(tempId);
    if (!rowCmp) return;

    rowCmp.setFieldError(fieldName, message);
    rowCmp.revertFieldValue(fieldName, prevValue);
  }
}

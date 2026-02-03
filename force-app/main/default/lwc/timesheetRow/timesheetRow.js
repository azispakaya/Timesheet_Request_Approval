/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api } from "lwc";

import convertProjectName from "@salesforce/apex/lwc_RequestTimesheetController.convertProjectName";
import convertCaseNumber from "@salesforce/apex/lwc_RequestTimesheetController.convertCaseNumber";
import convertPOCNumber from "@salesforce/apex/lwc_RequestTimesheetController.convertPOCNumber";
import convertOpportuniyId from "@salesforce/apex/lwc_RequestTimesheetController.convertOpportuniyId";
import convertCampaign from "@salesforce/apex/lwc_RequestTimesheetController.convertCampaign";

export default class TimesheetRow extends LightningElement {
  @api tempid;
  @api entityType;
  @api badgeLabel;
  @api badgeClass;
  @api formFactorClass;

  @api lookupFieldApiName;
  @api lookupName;

  // controlled props (optional, good practice)
  @api objectRecordId;
  @api date;
  @api stime;
  @api tempRemark;

  @api memberId;

  // last valid lookup for revert
  _lastValidLookup = null;
  _isResolvingLookup = false;

  // keep last valid values (for revert)
  _lastValid = {
    date: null,
    stime: null,
    temp_remark: null
  };

  // add near top of class
  lookupError = ""; // string

  get lookupWrapClass() {
    return this.lookupError
      ? "slds-form-element slds-has-error"
      : "slds-form-element";
  }

  setLookupError(msg) {
    this.lookupError = msg || "";
  }

  clearLookupError() {
    this.lookupError = "";
  }

  connectedCallback() {
    // initialize from parent props
    this._lastValid.date = this.date ?? null;
    this._lastValid.stime = this.stime ?? null;
    this._lastValid.temp_remark = this.tempRemark ?? null;
  }

  // =============================
  // REMOVE
  // =============================
  handleRemoveClick() {
    this.dispatchEvent(
      new CustomEvent("rowremove", {
        detail: { tempId: this.tempid, entityType: this.entityType },
        bubbles: true,
        composed: true
      })
    );
  }

  // =============================
  // LOOKUP
  // =============================
  // =============================
  // LOOKUP CHANGE -> resolve async in child
  // =============================
  async handleLookupChange(event) {
    const el = event.target;
    const nextValue = el?.value ?? null;

    // clear old error (important)
    this.clearLookupError();

    // allow clearing
    if (!nextValue) {
      this._lastValidLookup = null;
      this.dispatchRowFieldChange({ fieldName: "objectRecordId", value: null });
      return;
    }

    if (this._isResolvingLookup) return;
    this._isResolvingLookup = true;

    const result = await this.resolveLookupInChild(
      this.entityType,
      nextValue,
      this.memberId
    );
    this._isResolvingLookup = false;

    if (!result.success) {
      const msg =
        result.message || "You are not authorized to log time for this record.";

      // ✅ SHOW MESSAGE UNDER LOOKUP (reliable)
      this.setLookupError(msg);

      // revert UI
      this.revertTargetValue(el, this._lastValidLookup);
      return;
    }

    // success
    this._lastValidLookup = nextValue;
    this.clearLookupError();

    console.log("resolveLookupInChild", JSON.stringify(result, null, 2));

    this.dispatchRowFieldChange({
      fieldName: "objectRecordId",
      value: nextValue
    });

    this.dispatchEvent(
      new CustomEvent("rowlookupresolved", {
        detail: {
          tempId: this.tempid,
          entityType: this.entityType,
          payload: {
            ...(result.payload || {}),
            objectRecordId:
              (result.payload && result.payload.objectRecordId) || nextValue
          }
        },
        bubbles: true,
        composed: true
      })
    );
  }

  // =============================
  // Resolve based on entityType
  // =============================
  async resolveLookupInChild(entityType, objectRecordId, memberId) {
    try {
      let rawResponse;

      // memberId might be null if parent not loaded yet
      const safeMemberId = memberId || null;

      if (entityType === "project") {
        rawResponse = await convertProjectName({
          ProjectID: objectRecordId,
          memberId: safeMemberId
        });
      } else if (entityType === "case") {
        rawResponse = await convertCaseNumber({
          caseId: objectRecordId,
          memberId: safeMemberId
        });
      } else if (entityType === "poc") {
        rawResponse = await convertPOCNumber({
          pocId: objectRecordId,
          memberId: safeMemberId
        });
      } else if (entityType === "opty") {
        rawResponse = await convertOpportuniyId({
          OptyID: objectRecordId,
          memberId: safeMemberId
        });
      } else if (entityType === "campaign") {
        rawResponse = await convertCampaign({
          campaignId: objectRecordId,
          memberId: safeMemberId
        });
      } else {
        return {
          success: false,
          message: `Unsupported type: ${entityType}`,
          payload: null
        };
      }

      const wrapper = this.normalizeResponse(rawResponse);

      if (!wrapper.success) {
        return {
          success: false,
          message: this.getFriendlyLookupErrorMessage(wrapper),
          payload: null
        };
      }

      return { success: true, message: "", payload: wrapper.payload || null };
    } catch (e) {
      const rawMsg = this.normalizeApexError(e)?.message || "Convert failed.";
      return {
        success: false,
        message: this.getFriendlyLookupErrorMessage({
          code: "APEX_ERROR",
          message: rawMsg
        }),
        payload: null
      };
    }
  }

  // =============================
  // INPUT VALIDATION + DISPATCH
  // =============================
  handleInputChange(event) {
    const fieldName = event.target?.name;
    const value = event.target?.value;

    // --- STIME validation ---
    if (fieldName === "stime") {
      const num = Number(value);

      // allow empty (user clearing)
      if (
        value !== null &&
        value !== undefined &&
        value !== "" &&
        Number.isFinite(num)
      ) {
        if (num > 24) {
          const msg = "Hours cannot be more than 24 hours (1 day).";
          this.setFieldError(event.target, msg);
          this.revertTargetValue(event.target, this._lastValid.stime);
          return;
        }
        if (num < 0) {
          const msg = "Hours cannot be less than 0.";
          this.setFieldError(event.target, msg);
          this.revertTargetValue(event.target, this._lastValid.stime);
          return;
        }
      }

      // valid -> clear error & save as last valid
      this.clearFieldError(event.target);
      this._lastValid.stime = value;
    }

    // --- DATE validation ---
    if (fieldName === "date") {
      if (value) {
        const selected = this.toLocalDate(value);
        const today = this.getTodayLocal();
        const earliest = this.addDays(today, -7);

        if (selected > today || selected < earliest) {
          const msg = "Date must be within the last 7 days (including today).";
          this.setFieldError(event.target, msg);
          this.revertTargetValue(event.target, this._lastValid.date);
          return;
        }
      }

      // valid
      this.clearFieldError(event.target);
      this._lastValid.date = value;
    }

    // --- REMARKS just track last valid ---
    if (fieldName === "temp_remark") {
      this._lastValid.temp_remark = value;
    }

    // dispatch to parent only after valid
    this.dispatchRowFieldChange({ fieldName, value });
  }

  dispatchRowFieldChange({ fieldName, value }) {
    this.dispatchEvent(
      new CustomEvent("rowfieldchange", {
        detail: {
          tempId: this.tempid,
          entityType: this.entityType,
          fieldName,
          value
        },
        bubbles: true,
        composed: true
      })
    );
  }

  // =============================
  // Helpers (LWS-safe)
  // =============================
  setFieldError(targetEl, message) {
    if (targetEl && typeof targetEl.setCustomValidity === "function") {
      targetEl.setCustomValidity(message || "");
      targetEl.reportValidity?.();
    }
  }

  clearFieldError(targetEl) {
    if (targetEl && typeof targetEl.setCustomValidity === "function") {
      targetEl.setCustomValidity("");
      targetEl.reportValidity?.();
    }
  }

  revertTargetValue(targetEl, revertValue) {
    // IMPORTANT: do it in next tick, more reliable with base components
    const v = revertValue ?? null;
    requestAnimationFrame(() => {
      try {
        targetEl.value = v;
      } catch (e) {
        // ignore
      }
      targetEl.reportValidity?.();
    });
  }

  toLocalDate(yyyyMmDd) {
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

  // optional (parent validateAllInputs)
  @api
  reportValidity() {
    let ok = true;
    const inputs = this.template.querySelectorAll(
      "lightning-input.validated, lightning-textarea.validated, lightning-input-field.validated"
    );
    inputs.forEach((el) => {
      if (typeof el.reportValidity === "function") {
        if (!el.reportValidity()) ok = false;
      }
    });
    return ok;
  }

  // =============================
  // Normalizers (same as parent)
  // =============================
  normalizeResponse(apexData) {
    let responseObject = apexData;

    try {
      if (typeof apexData === "string") responseObject = JSON.parse(apexData);
    } catch (e) {
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
    if (apexError?.body) {
      if (Array.isArray(apexError.body)) {
        message = apexError.body.map((i) => i.message).join(", ");
      } else if (typeof apexError.body.message === "string") {
        message = apexError.body.message;
      }
    } else if (apexError?.message) {
      message = apexError.message;
    }
    return { message };
  }
  getFriendlyLookupErrorMessage({ code, message }) {
    const m = String(message || "").toLowerCase();
    const c = String(code || "").toLowerCase();

    // --- Authorization / access ---
    if (
      c.includes("insufficient_access") ||
      c.includes("no_access") ||
      c.includes("unauthorized") ||
      m.includes("insufficient access") ||
      m.includes("insufficient_privileges") ||
      m.includes("not authorized") ||
      m.includes("unauthorized") ||
      m.includes("permission") ||
      m.includes("access denied")
    ) {
      return "You are not authorized to log time for this record.";
    }

    // --- Record not found / invalid id ---
    if (
      c.includes("not_found") ||
      m.includes("invalid id") ||
      m.includes("malformed id") ||
      m.includes("not found") ||
      m.includes("does not exist")
    ) {
      return "This record is not available. Please select a different record.";
    }

    // --- Approver missing ---
    if (
      c.includes("approver") ||
      m.includes("approver") ||
      m.includes("no approver") ||
      m.includes("approver not found")
    ) {
      return "No approver was found for this record. Please contact your administrator.";
    }

    // default fallback (still English, not too technical)
    return "You are not assigned to this record. Please choose another one.";
  }
}

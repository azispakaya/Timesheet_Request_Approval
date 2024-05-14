/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:40:38
 * @modify date 2024-05-14 13:21:14
 * @desc [Controller for Add multiple Timehseet]
 */
import {
    LightningElement,
    api,
    track
} from 'lwc';
import convertPicName from '@salesforce/apex/lwc_RequestTimesheetController.convertEmployeeID'
import convertProjectName from '@salesforce/apex/lwc_RequestTimesheetController.convertProjectName'
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent'
import submitMultiTimesheet from '@salesforce/apex/lwc_RequestTimesheetController.submitTimesheet'
import convertCaseNumber from '@salesforce/apex/lwc_RequestTimesheetController.convertCaseNumber'
import convertPOCNumber from '@salesforce/apex/lwc_RequestTimesheetController.convertPOCNumber'
import {
    CloseActionScreenEvent
} from 'lightning/actions';
import assignApprover from '@salesforce/apex/lwc_ApprovalTimesheetController.getProjectManager'
import createMultiTimesheet from '@salesforce/apex/lwc_ApprovalTimesheetController.createMultiTimesheet'
import FORM_FACTOR from "@salesforce/client/formFactor";

export default class AddMultipleTimesheet extends LightningElement {
    @api recordId

    @track timesheets = []
    @track listProjects = []
    @track listCases = []
    @track listPOCs = []

    @track countHours = 0
    @track isLoading = false

    isValid = false
    isVisible = true

    @track validationErrors = []
    showproject = true
    showcase = false
    showpoc = false
    classProject = 'slds-col slds-size_2-of-8 slds-m-around_small'

    selectedPicklist = 'Project'
    fieldApiName = 'Project__c'

    employeName = null

    formFactorClass = 'slds-grid slds-grid_align-space'
    mobileSupport
    desktopSupport

    get PicklistObject() {
        return [{
                label: 'Project',
                value: 'Project'
            },
            {
                label: 'Case',
                value: 'Case'
            },
            {
                label: 'POC',
                value: 'POC'
            },
        ]
    }
    connectedCallback() {
        this.isVisible = true
        
        if(FORM_FACTOR == 'Large'){
            this.formFactorClass = 'slds-grid slds-grid_align-space'
            this.desktopSupport = true
        }else{
            this.formFactorClass = 'slds-grid slds-grid_vertical'
            this.mobileSupport = true
        }
    }

    //* Field Handling
    handleObject(event) {
        if (this.timesheets.length < 0) {
            this.toast('Unable to modify timesheet type when displaying more than one row.', 'warning', 'Warning')
        } else {
            this.selectedPicklist = event.detail.value;

            if (this.selectedPicklist == 'Project') {
                this.classProject = 'slds-col slds-size_2-of-8 slds-m-around_small'
                this.showproject = true
                this.showcase = false
                this.showpoc = false
            } else if (this.selectedPicklist == 'Case') {
                this.classProject = 'slds-col slds-size_1-of-8 slds-m-around_small'
                this.showproject = false
                this.showcase = true
                this.showpoc = false
            } else {
                this.showproject = false
                this.showcase = false
                this.showpoc = true
            }
        }


    }

    fieldChangeHandler(event) {
        //* define basic variable
        let timesheetRow = this.timesheets.find(record => record.tempId == event.target.dataset.tempid)
        let fieldValue = event.target.value
        let fieldName = event.target.name

        //* add validation for null field required
        this.controlValidityField()

        //* set the data to the object
        if (timesheetRow) {
            switch (fieldName) {
                case 'case':
                    convertCaseNumber({
                            caseId: fieldValue,
                            memberId: this.recordId
                        })
                        .then(res => {
                            let splitCode = res.split(';')
                            if (splitCode[0] === '200') {
                                let splitRes = splitCode[1].split(',')
                                this.isValid = true;
                                timesheetRow[fieldName] = splitRes[0];
                                timesheetRow['project_name'] = splitRes[1];
                                timesheetRow['spk'] = splitRes[2];
                                timesheetRow['ProjectId'] = splitRes[3];
                                timesheetRow['type'] = 'case'

                                assignApprover({
                                    ProjectId : splitRes[3],
                                    EmployeeID : this.recordId
                                }).then((res)=>{
                                    timesheetRow['Approver'] = res.split(';')[0];
                                    timesheetRow['Approver_Optional'] = res.split(';')[1]
                                })

                            } else if (splitCode[0] === '401') {
                                this.toast('You are not assigned to this Case. Please ensure proper assignment for continued request Timesheet.', 'error', 'Case Invalid!!');
                                this.isValid = false
                            } else {
                                this.isValid = false
                            }
                        });
                    break;

                case 'project_name':
                    convertProjectName({
                            ProjectID: (event.detail.value)[0],
                            memberId: this.recordId
                        })
                        .then(result => {
                            if (result === 'null') {
                                this.isValid = false;
                                this.toast('You are not assigned to this project, or the project has been closed. Please contact the project manager for further assistance.', 'error', 'Project Invalid!!');
                            } else if (result !== 'No Data') {
                                const projectName = result.split(',');
                                this.isValid = true;
                                timesheetRow['project_name'] = projectName[0];
                                timesheetRow['spk'] = projectName[1];
                                timesheetRow['ProjectId'] = projectName[2];
                                timesheetRow['type'] = 'project';

                                assignApprover({
                                    ProjectId : projectName[2],
                                    EmployeeID : this.recordId
                                }).then((res)=>{
                                    timesheetRow['Approver'] = res.split(';')[0];
                                    timesheetRow['Approver_Optional'] = res.split(';')[1]
                                })
                            } else {
                                this.isValid = false
                            }
                        });
                        
                    break;

                case 'poc_name':
                    convertPOCNumber({
                            pocId: fieldValue,
                            memberId: this.recordId
                        })
                        .then(res => {
                            let spliCode = res.split(';')
                            if (spliCode[0] === '200') {
                                let splitRes = spliCode[1].split(',')
                                timesheetRow[fieldName] = splitRes[0];
                                timesheetRow['project_name'] = splitRes[1];
                                timesheetRow['spk'] = splitRes[2];
                                timesheetRow['ProjectId'] = splitRes[3];
                                timesheetRow['type'] = 'poc'

                                assignApprover({
                                    ProjectId : splitRes[3],
                                    EmployeeID : this.recordId
                                }).then((res)=>{
                                    timesheetRow['Approver'] = res.split(';')[0];
                                    timesheetRow['Approver_Optional'] = res.split(';')[1]
                                })

                            } else if(spliCode[0] === '401'){
                                this.toast('You are not assigned to this POC as a member or project manager. Please contact the POC administrator for further assistance.','error','POC Invalid')
                                this.isValid = false
                            }else{
                                this.isValid = false;
                            }
                        });
                        
                    break;

                case 'stime' :
                    
                    let checkHours = this.validateField(fieldName, fieldValue);
                    if(checkHours =='valid'){
                        this.countHours = this.sumTotalHours(this.timesheets)
                        timesheetRow[fieldName] = fieldValue    
                    }else{
                        this.toast(checkHours, 'error', 'Hours Invalid!!')
                    }
                    
                    break;

                case 'date' :
                    
                    let checkingDateField = this.validateField(fieldName, fieldValue);
                    if(checkingDateField == 'valid'){
                        timesheetRow['start_date'] = fieldValue
                        timesheetRow['end_date'] = fieldValue
                    }

                default:
                    let checkingField = this.validateField(fieldName, fieldValue);
                    if (checkingField === 'valid') {
                        timesheetRow[fieldName] = fieldValue;
                    } else {
                        timesheetRow[fieldName] = null
                        this.toast(checkingField, 'error', 'Invalid');
                    }
            }
            
        }
       

    }

    //* Button Function
    addNewHandler(event) {
        
        if(this.timesheets.length > 4){
            this.toast("You've reached the maximum limit of entries. You can't add more than 5 entries.", 'error', 'Invalid')
            return
        }

        let typeTimesheet
        if(event.detail.value == 'Case'){
            typeTimesheet = 'Case'
        }else{
            typeTimesheet = this.selectedPicklist
        }
        
        if (typeTimesheet == 'Project') {
            this.listProjects.push({
                tempId: Date.now()
            })
        } else if (typeTimesheet == 'Case') {
            this.listCases.push({
                tempId: Date.now(),
            })
        } else if (typeTimesheet == 'POC') {
            this.listPOCs.push({
                tempId: Date.now()
            })
        }

        this.timesheets = this.listProjects.concat(this.listCases, this.listPOCs)
        this.isVisible = false
        if (this.timesheets.length > 0) {
            this.toast('Succesfully Add new Timesheet Entry', 'success', 'Info')
        }

    }

    cancelHandler() {
        this.timesheets = []
        this.dispatchEvent(new CloseActionScreenEvent())
    }

    removeHandler(event) {
        // if(this.timesheets.length==1){
        //     this.toast('Cannot Remove Last Timesheet Entry. Please ensure there is at least one entry remaining.','error','Warning!!')
        //     return
        // }
        let entity = event.target.dataset.entitytype
        let entityId = event.target.dataset.tempid
        if (entity === 'project') {
            this.listProjects = this.listProjects.filter(record => record.tempId != entityId)
        } else if (entity === 'case') {
            this.listCases = this.listCases.filter(record => record.tempId != entityId)
        } else {
            this.listPOCs = this.listPOCs.filter(record => record.tempId != entityId)
        }

        this.timesheets = this.timesheets.filter(record => record.tempId != event.target.dataset.tempid)
        this.toast('Successfully Remove Timesheet Entry', 'warning', 'Info')

        if (this.timesheets.length == 0) {
            this.isVisible = true
        }
    }

    async submitTimesheet(event) {
        this.handlingSaveRecord('Waiting for Approval')
    }

    async saveTimesheet(event){
        this.handlingSaveRecord('Draft')
    }

    async handlingSaveRecord(setApprovalStatus){
        try {
            //* Validate fields
            this.controlValidityField();
            if (this.validationErrors.length !== 0) {
                this.toast('Mandatory Fields Required. Please ensure all required fields are filled in.', 'error', 'Attention!!');
                return;
            }

            //* Validate StartDate EndDate
            if (!this.validateDateErrors(this.timesheets)) {
                this.toast('Start Date must be less than End Date', 'error', 'Error!!');
                return
            }

            //* validate Project Errors
            if (!this.validateProjectErrors(this.timesheets)) {
                this.toast('Kindly Ensure Valid Projects are Selected for Your Timesheet. Please check your Project on Case', 'error', 'Project Invalid!!')
                return
            }

            //* Prepare data to send
            if (!this.validateNullFields(this.timesheets)) {
                this.toast("Please ensure the Start Date, End Date, and Time fields are entered in the correct Value.", 'error', 'Invalid!!')
                return
            }

            //* Fetch PicName
            const employe = await convertPicName({
                RecordID: this.recordId,
                render: 'submit'
            });

            //* Assign PicName and set billable flag
            this.timesheets.forEach(record => {
                record.pic_name = employe.split(';')[0];
                record.Email = employe.split(';')[1]
                record.EmployeeID = this.recordId;
                record.billable = '1';
            });

            if (!this.isValid) {
                this.toast('Please Check Your Inputs!', 'error', 'Error');
                return;
            }

            //* Combine fields on array
            this.timesheets = this.combineRemarkItem(this.timesheets);

            //* Sort timesheets based on Start_date
            this.timesheets = this.sortListCollection(this.timesheets);


            //* Submit timesheet
            if (this.timesheets.length == 0) {
                this.toast('Please input at least one timesheet entry before submitting the request.', 'warning', 'Reminder!!')
                return
            }


            this.isLoading = true
            const resSubmit = await createMultiTimesheet({
                Timesheet: JSON.stringify(this.timesheets),
                ApprovalStatus : setApprovalStatus
            });

            const [resMSG, resCode] = resSubmit.split(',');
            
            if (resCode.includes('"000"')) {
                this.toast('Successfully Request Timesheet', 'success', 'Success');
                this.dispatchEvent(new CloseActionScreenEvent());
                this.isLoading = false
            } else {
                this.toast(`Failed to request timesheet with error: ${resMSG.split(':')[1]}`, 'error', 'Error');
                this.isLoading = false
            }
            // console.log(JSON.parse(resSubmit));
            // console.log(setApprovalStatus)
        } catch (error) {
            console.error('Error:', error);
            this.toast('An error occurred while processing the request.', 'error', 'Error!!');
        }

        // console.log(JSON.stringify(this.timesheets))
    }

    //* validation Fields
    controlValidityField() {
        this.validationErrors = []

        const requiredFields = this.template.querySelectorAll('.validated')
        requiredFields.forEach(field => {
            if (!field.value) {
                this.validationErrors.push(field.label + 'is Required')
            }
        })

    }

    validateField(fieldName, value) {

        if (fieldName === 'stime' && value > 24) {
            return 'Invalid Time Entry. The time should not exceed 24 hours. Please adjust your input.';
        }

        if ((fieldName === 'start_date' || fieldName === 'end_date') && (new Date(value) > new Date() || new Date(value) <= new Date().setDate(new Date().getDate() - 9))) {
            return 'Please enter a date that is not later than today and not more than 7 days ago.';
        }

        if (fieldName === 'date' && (new Date(value) > new Date() || new Date(value) <= new Date().setDate(new Date().getDate() - 9)) ){
            return 'Please enter a date that is not later than today and not more than 7 days ago.';
        }

        return 'valid';

    }


    //* utility Function
    toast(message, variant, title) {
        const callToast = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        })
        this.dispatchEvent(callToast);
    }

    compareDate(startDate, endDate) {
        const validStartDate = new Date(startDate)
        const validEndDate = new Date(endDate)

        if (validEndDate < validStartDate) {
            return false
        }
        return true
    }

    sumTotalHours(listArray) {
        let total = 0;

        for (let i = 0; i < listArray.length; i++) {
            total += parseInt(listArray[i].stime)
        }

        return total

    }

    validateDateErrors(listArray) {
        let dateErrors = [];
        listArray.forEach(fields => {
            if (!this.compareDate(fields.start_date, fields.end_date)) {
                dateErrors.push(`Start Date ${fields.start_date}: End Date ${fields.end_date}`);
            }else{
                dateErrors = []
            }

        });

        if (dateErrors.length > 0) {
            return false
        }
        return true

    }

    validateNullFields(listArray) {
        let nullFields = [];
        listArray.forEach(item => {
            if (item.stime == null) {
                nullFields.push("Time is Null")
            }else{
                nullFields = []
            }
            if (item.start_date == null || item.end_date == null) {
                nullFields.push('All dates must be filled');
            }else{
                nullFields = []
            }

            
        })

        if (nullFields.length > 0) {
            return false
        }
        return true
    }

    validateProjectErrors(listArray) {
        let ProjectError = []
        listArray.forEach(fields => {
            if (fields.spk == null) {
                ProjectError.push("Project is required")
            }else{
                ProjectError = []
            }
        })
        if (ProjectError.length > 0) {
            return false
        }
        return true
    }

    combineRemarkItem(listArray) {
        listArray.forEach(item => {
            if (item.type === 'case') {
                item.remark = `Case ${item.case} - ${item.temp_remark}`;
            } else if (item.type === 'project') {
                item.remark = `Project ${item.spk} - ${item.temp_remark}`;
            } else {
                item.remark = `${item.poc_name} - ${item.temp_remark}`;
            }
        });
        return listArray;
    }

    sortListCollection(listArray) {
        listArray = listArray.sort((recordCurrent, recordPrev) =>
            new Date(recordCurrent.start_date) - new Date(recordPrev.start_date)
        );
        return listArray;
    }

}
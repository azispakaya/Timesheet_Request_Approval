/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:45:40
 * @modify date 2024-04-04 19:53:53
 * @desc [Controller for List Timesheet Approval  Page] 
 */

import { LightningElement, api, track, wire } from 'lwc';
import { gql, graphql,refreshGraphQL } from "lightning/uiGraphQLApi";
import ConvertApproverName from "@salesforce/apex/lwc_ApprovalTimesheetController.ApproverName"
import updateStatus from "@salesforce/apex/lwc_ApprovalTimesheetController.updateApprovalStatus"
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent'
import modalEditLine from 'c/modalCommentTimesheet';
import modalConfirmation from 'c/modalConfirmationPage'
import { NavigationMixin } from 'lightning/navigation';

export default class ViewActiveTimesheetApproval extends NavigationMixin (LightningElement) {

    results = []
    totalCountRecord = 0
    errors
    @api recordId
    ApproverName
    ApproverId
    ApprovalStatus
    @track draftTimesheet = []
    isVisible
    after = null
    pageInfo
    showRecord = 5
    hasNext = true
    hasPrev = true
    setStartDate
    setEndDate
    selectedApprovalStatus = 'Waiting for Approval'
    approvalStyle = 'slds-truncate slds-badge slds-badge_inverse'
    isDisabled = false

    timesheetRecordId;
    projectRecordId;
    employeeRecordId;
    sortName;
  

    @wire(graphql, {
        query: gql`
        query timesheets(
                $ApproverName : ID, 
                $ApprovalStatus : Picklist,
                $nextCursor : String,
                $recordCount : Int,
                $startDate : Date,
                $endDate : Date
            ){
            uiapi{
                query{
                    Timesheet__c(
                        first : $recordCount
                        after : $nextCursor
                        where : {
                            and : [
                                {or:[
                                    {Timesheet_Approver__r:{Id:{eq : $ApproverName}}},
                                    {Timesheet_Approver_Optional__r:{Id:{eq : $ApproverName}}}
                                ]},
                                {Approval_Status__c:{eq : $ApprovalStatus}},
                                {Start_Date__c:{ gte:{value: $startDate}}},
                                {End_Date__c : {lte:{value: $endDate}}}

                            ]
                        }
                        orderBy :{
                            Start_Date__c: {
                                order: DESC
                            }
                        }
                    ){
                        edges{
                            node{
                                Id
                                Name{
                                    value
                                }
                                Employee__r{
                                    Id
                                    Name{
                                        value
                                    }
                                    Employee_ID__c{
                                        value
                                    }
                                }
                                Project__r{
                                    Id
                                    Name{
                                        value
                                    }
                                    SPK__c{
                                        value
                                    }
                                }
                                Start_Date__c{
                                    value
                                }
                                End_Date__c{
                                    value
                                }
                                Time__c{
                                    value
                                }
                                Remarks__c{
                                    value
                                }
                                Approval_Status__c{
                                    value
                                }
                                Timesheet_Approver__r{
                                    Name{
                                        value
                                    }
                                }
                                Timesheet_Approver_Optional__r{
                                    Name{
                                        value
                                    }
                                }
                            }
                            cursor
                        }
                        totalCount
                        pageInfo{
                            startCursor
                            endCursor
                            hasNextPage
                            hasPreviousPage
                        }
                    }
                }
            }
        }
        `,
        variables: "$variables",
    })
    graphqlQueryResult(result) {
        const { data, errors } = result

        if (data) {
          this.results = data.uiapi.query.Timesheet__c.edges.map((edge) => edge.node);
          this.totalCountRecord = data.uiapi.query.Timesheet__c.totalCount
          this.pageInfo = data.uiapi.query?.Timesheet__c?.pageInfo
          this.hasNext = this.pageInfo.hasNextPage
          this.hasPrev = this.pageInfo.hasPreviousPage

          if(this.totalCountRecord > 0){
            this.isVisible = false
          }else{
            this.isVisible = true
          }
          
        }
        this.errors = errors;
        this.graphQlData = result
    }

    connectedCallback(){
        ConvertApproverName({ recordPageId : this.recordId})
        .then((res)=>{
            this.ApproverName = res.split(';')[0];
            this.ApproverId = res.split(';')[1];
            this.ApprovalStatus = this.selectedApprovalStatus
        })

        let currentDate = new Date().toJSON().slice(0, 10);
        const date = new Date();

        let day = "01";
        let month = "01";
        let year = date.getFullYear()-1;
        let currentMonth = `${year}-${month}-${day}`;

        this.setStartDate = currentMonth
        this.setEndDate = currentDate

        this.sortName = 'StartDate';


    }

    fieldChangeHandler(event){
         let fieldName = event?.target.name
         let fieldValue = event?.target.value

         if(fieldName == 'StartDate'){
            this.setStartDate = fieldValue
         }else if(fieldName == 'EndDate'){
            this.setEndDate = fieldValue
         }else if(fieldName == 'ApprovalStatus'){
            this.selectedApprovalStatus = fieldValue

            switch (fieldValue) {
                case 'Fully Approved':
                    this.approvalStyle = 'slds-truncate slds-badge slds-theme_success'
                    this.isDisabled = true
                    break;
                case 'Waiting for Approval':
                    this.approvalStyle = 'slds-truncate slds-badge slds-badge_inverse'
                    this.isDisabled = false
                    break;
                default:
                    this.approvalStyle = 'slds-truncate slds-badge slds-theme_error'
                    this.isDisabled = true
                    break;
            }

         }
    }

    handleChecked(event){
        const timesheetId = event.target.dataset.id

        const duplicate = this.draftTimesheet.some((timesheet) => timesheet.recordid === timesheetId)
        if(!duplicate) {
            this.draftTimesheet.push({
                recordid : timesheetId
            })
        }else{
            this.draftTimesheet = this.draftTimesheet.filter(item => item.recordid !== timesheetId)
        }
        
        // console.log(JSON.stringify(this.draftTimesheet))
    }

    handleRefresh(event){

        refreshGraphQL(this.graphQlData)
        this.toast('Successfully Refresh', 'success', 'Info')
        if(this.totalCountRecord > 0){
            this.isVisible = false
        }else{
            this.isVisible = true
        }
    }

    async handleApprove(event){
        
        if(this.draftTimesheet.length == 0){
            this.toast('Nothing to Approve, Please Select at least 1 Timesheet', 'error', 'Approve Error!!')
            return
        }
        
        this.draftTimesheet.forEach(item => {
            item.ApprovalStatus = 'Fully Approved',
            item.Comment = 'This Timesheet Successfully Approved',
            item.ApproveBy = this.ApproverId
        })
        const countTimesheet = this.draftTimesheet.length

        const resultModal = await modalConfirmation.open({
            Content : 'Are You sure to Approve ('+countTimesheet+') Timesheets ?',
            Header : 'Approve Confirmation'
        })

        // console.log(resultModal);

        if(resultModal == 'Save'){
            await updateStatus({
                Timesheets : JSON.stringify(this.draftTimesheet)
            }).then((res)=>{
                if(res == '200'){
                    this.toast('Successfully Approved', 'success', 'Info')
                    this.draftTimesheet = []
                }
      
            }).then(()=>{

                refreshGraphQL(this.graphQlData)

            }).catch((error)=>{
                console.log(error)
            })
            
        }

        

        // console.log(JSON.stringify(this.draftTimesheet))
    }

    async handleReject(event){

        if(this.draftTimesheet.length == 0){
            this.toast('Nothing to Reject, Please Select at least 1 Timesheet', 'error', 'Reject Error!!')
            return
        }

        this.draftTimesheet.forEach(item =>{
            item.ApprovalStatus = 'Rejected',
            item.Comment = 'This Timesheet has been Rejected, Please Re-Submit',
            item.ApproveBy = this.ApproverId
        })
        let countTimesheet = this.draftTimesheet.length
        const resultModal = await modalConfirmation.open({
            Content : 'Are You sure to Reject ('+countTimesheet+') Timesheets ?',
            Header : 'Reject Confirmation'
        })

        if(resultModal=='Save'){
            await updateStatus({
            
                Timesheets : JSON.stringify(this.draftTimesheet)
    
            }).then((res)=>{
                
                if(res == '200'){
                    this.toast('Successfully Rejected', 'warning', 'Info')
                    this.draftTimesheet = []
                }
                
    
            }).then(()=>{
                refreshGraphQL(this.graphQlData)
                
            }).catch((error)=>{
                console.log(error)
            })
        }
      
        // console.log(JSON.stringify(this.draftTimesheet))
    }

    async handleEditLine(event){

        let singleTimesheet = []
        const timesheetId = event.target.dataset.id

        
        const resultComment = await modalEditLine.open({
            headerLabel: 'Add Comment',
            // timesheets: this.draftTimesheet
        })

        singleTimesheet.push({
            recordid : timesheetId,
            Comment : resultComment.split(';')[0],
            ApprovalStatus : resultComment.split(';')[1],
            ApproveBy : this.ApproverId
        })

        if(resultComment != 'cancel'){
            await updateStatus({

                Timesheets : JSON.stringify(singleTimesheet)

            }).then((res)=>{

                if(res == '200'){
                    this.toast('Updated Successfully','success','Success') 
                    refreshGraphQL(this.graphQlData)
                }
                
            }).then(()=>{
                singleTimesheet = []

            }).catch((e)=>{
                console.log(e)
            })

            
        }

    }

    loadMore(event){
        event.preventDefault();
        if(this.pageInfo.hasNextPage && this.pageInfo){
            // this.after = this.pageInfo.endCursor
            this.showRecord = this.showRecord + 5
        }else{
            this.after = null
        }
    }

    loadLess(event){
        event.preventDefault();
        if(this.totalCountRecord > 5 && this.pageInfo){
            this.showRecord = this.showRecord - 5
        }else{
            this.after = null
        }
    }

    navToRecord(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                actionName : 'view',
                objectApiName : event.target?.dataset.objectname,
                recordId : event.target?.dataset.id
            }
        });
    }

    get variables() {
        return {
          ApproverName: this.ApproverId,
          ApprovalStatus: this.selectedApprovalStatus,
          nextCursor : this.after,
          recordCount : this.showRecord,
          startDate : this.setStartDate,
          endDate : this.setEndDate
        };
      }
    
    get picklistStatus(){
        return [
            { label : 'Waiting for Approval', value : 'Waiting for Approval'},
            { label : 'Fully Approved', value : 'Fully Approved'},
            { label : 'Rejected', value : 'Rejected'},
        ]
    }
    
    @api
    async refreshData(){
        return refreshGraphQL(this.results)
    }

    toast(message, variant, title) {
        const callToast = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        })
        this.dispatchEvent(callToast);
    }


}
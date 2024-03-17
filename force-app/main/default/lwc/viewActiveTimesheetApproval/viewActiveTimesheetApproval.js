import { LightningElement, api, track, wire } from 'lwc';
import { gql, graphql,refreshGraphQL } from "lightning/uiGraphQLApi";
import ConvertApproverName from "@salesforce/apex/lwc_ApprovalTimesheetController.ApproverName"
import updateStatus from "@salesforce/apex/lwc_ApprovalTimesheetController.updateApprovalStatus"
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent'
import modalEditLine from 'c/modalCommentTimesheet';

export default class ViewActiveTimesheetApproval extends LightningElement {

    results
    errors
    @api recordId
    ApproverName
    ApproverId
    ApprovalStatus
    @track draftTimesheet = []
    @track isVisible

    connectedCallback(){
        ConvertApproverName({ recordPageId : this.recordId})
        .then((res)=>{
            this.ApproverName = res.split(';')[0];
            this.ApproverId = res.split(';')[1];
            this.ApprovalStatus = 'Waiting for Approval'
        })

        if(this.draftTimesheet.length > 0){
            this.isVisible = true
        }else{
            this.isVisible = false
        }
    }

    @wire(graphql, {
        query: gql`
            query timesheets($ApproverName : ID, $ApprovalStatus : Picklist){
                uiapi{
                    query{
                        Timesheet__c(
                            where : {
                                and : [
                                    {or:[
                                        {Timesheet_Approver__r:{Id:{eq : $ApproverName}}},
                                        {Timesheet_Approver_Optional__r:{Id:{eq : $ApproverName}}}
                                    ]},
                                    {Approval_Status__c:{eq : $ApprovalStatus}}
                                ]
                            }
                        ){
                            edges{
                                node{
                                    Id
                                    Name{
                                        value
                                    }
                                    Employee__r{
                                        Name{
                                            value
                                        }
                                        Employee_ID__c{
                                            value
                                        }
                                    }
                                    Project__r{
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
        }
        this.errors = errors;
        this.graphQlData = result
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
        if(this.draftTimesheet.length > 0){
            this.isVisible = false
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

        await updateStatus({
            Timesheets : JSON.stringify(this.draftTimesheet)
        }).then((res)=>{

            refreshGraphQL(this.graphQlData)
            this.toast('Successfully Approved', 'success', 'Info')

            if(this.draftTimesheet.length > 0){
                this.isVisible = true
            }else{
                this.isVisible = false
            }

        }).catch((error)=>{
            console.log(error)
        })
        

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
        await updateStatus({
            
            Timesheets : JSON.stringify(this.draftTimesheet)

        }).then((res)=>{

            refreshGraphQL(this.graphQlData)
            this.toast('Successfully Rejected', 'warning', 'Info')

            if(this.draftTimesheet.length > 0){
                this.isVisible = true
            }else{
                this.isVisible = false
            }

        }).catch((error)=>{
            console.log(error)
        })


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
                refreshGraphQL(this.graphQlData)
                this.toast('Updated Successfully','success','Success') 
            }).catch((e)=>{
                console.log(e)
            })
        }

        if(this.draftTimesheet.length > 0){
            this.isVisible = true
        }else{
            this.isVisible = false
        }
       

        // console.log(JSON.stringify(singleTimesheet));

        
    }

    get variables() {
        return {
          ApproverName: this.ApproverId,
          ApprovalStatus: this.ApprovalStatus,
        };
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
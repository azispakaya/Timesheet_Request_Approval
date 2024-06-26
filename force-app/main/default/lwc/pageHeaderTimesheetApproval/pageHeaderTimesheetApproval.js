/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:46:12
 * @modify date 2024-06-26 11:15:59
 * @desc [Controller for Header Information]
 */

import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from "lightning/uiGraphQLApi";
import employee from "@salesforce/apex/lwc_ApprovalTimesheetController.ApproverName"
import FORM_FACTOR from "@salesforce/client/formFactor"
import AvatarProfile from '@salesforce/resourceUrl/DefaultProfileUser';

export default class PageHeaderTimesheetApproval extends LightningElement {

    resultEmployees
    totalTimesheets
    errors
    @api recordId
    employeId
    desktopSupport
    mobileSupport
    
    get AvatarProfile(){
        return 'standard:people_score'
    }

    @wire(graphql, {
        query : gql`
            query approver($ApproverId : ID, $employeID : ID, $approvalStatus : Picklist){
                uiapi{
                    query{
                        Timesheet_Approval__c(where :{Id:{ eq : $ApproverId}}){
                            edges{
                                node{
                                    Id
                                    Name{
                                        value
                                    }
                                    Approver__r{
                                        Id
                                        Name{
                                            value
                                        }
                                        Employee_ID__c{
                                            value
                                        }
                                        Role__c{
                                            value
                                        }
                                        Department__c{
                                            value
                                        }
                                        Email__c{
                                            value
                                        }
                                        Mobile_Phone__c{
                                            value
                                        }
                                    }
                                }
                            }
                        }
                        Timesheet__c(
                            where:{
                                and:[
                                    {or:[
                                        {Timesheet_Approver__c:{eq : $employeID}},
                                        {Timesheet_Approver_Optional__c:{eq: $employeID}}
                                    ]},
                                    {Approval_Status__c:{eq: $approvalStatus}}
                                ]
                                
                            }
                        ){
                            totalCount
                        }
                    }
                }
            }
        `,
        variables: "$variables"
    })
    graphqlResult({data, error}){
        if(data){
             this.resultEmployees = data.uiapi.query.Timesheet_Approval__c.edges.map((edge)=> edge.node);
             this.totalTimesheets = data.uiapi.query.Timesheet__c.totalCount;
        }else{
            this.errors = error
        }
    }

    connectedCallback(){
        employee({recordPageId:this.recordId})
        .then((res)=>{
            this.employeId = res.split(';')[1];
        })

        if(FORM_FACTOR == 'Large'){
            this.desktopSupport = true
        }else{
            this.mobileSupport = true
        }
        
    }

    get variables(){

        return{
            ApproverId : this.recordId,
            employeID : this.employeId,
            approvalStatus : 'Waiting for Approval'
        }
    }

    
}
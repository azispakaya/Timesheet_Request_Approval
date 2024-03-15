import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from "lightning/uiGraphQLApi";

export default class PageHeaderTimesheetApproval extends LightningElement {

    results
    errors
    @api recordId

    @wire(graphql, {
        query : gql`
            query approver($ApproverId : ID){
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
                                    }
                                }
                            }
                        }
                    }
                }
            }
        `,
        variables: "$variables"
    })
    graphqlResult({data, error}){
        if(data){
             this.results = data.uiapi.query.Timesheet_Approval__c.edges.map((edge)=> edge.node);
        }else{
            this.errors = error
        }
    }

    get variables(){
        return{
            ApproverId : this.recordId
        }
    }
}
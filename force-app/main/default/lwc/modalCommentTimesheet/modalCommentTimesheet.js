/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-03-24 15:45:08
 * @modify date 2024-06-26 13:44:13
 * @desc [Layout for Confirmation modal for Approve or Reject]
 */

import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ModalCommentTimesheet extends LightningModal {
    @api headerLabel
    textComment 
    isValid

    HandlefieldChange(event){
        this.textComment = event.target.value
    }

    handleRevise(){

        this.checkValidityCommnet()
        if(this.isValid)
            this.close(this.textComment+';Need to Revise;Revised')

    }

    handleReject(){
        this.checkValidityCommnet()
        if(this.isValid)
            this.close(this.textComment+';Rejected;Rejected')
    }
    
    handleCancel(){
        this.close('cancel')
    }

    checkValidityCommnet(){
        let fieldComment = this.template.querySelector('lightning-textarea')
        let fieldValue = fieldComment.value
        
        if(!fieldValue){
            fieldComment.setCustomValidity('Comment is Required')
            this.isValid = false    
        }else{
            fieldComment.setCustomValidity('')
            this.isValid = true
        }
        fieldComment.reportValidity()
    }
}
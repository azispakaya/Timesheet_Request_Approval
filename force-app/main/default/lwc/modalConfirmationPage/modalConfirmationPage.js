import { api } from 'lwc';
import LightningModal from 'lightning/modal'

export default class ModalConfirmationPage extends LightningModal {

    @api Content
    @api Header

    handleSave(){
        this.close('Save')
    }

    handleCancel(){
        this.close('Cancel')
    }
}
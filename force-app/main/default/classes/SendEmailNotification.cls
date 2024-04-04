/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-04-04 14:26:40
 * @modify date 2024-04-04 14:26:40
 * @desc [description]
 */
public class SendEmailNotification {

    public static void SendEmailNotificationUtils(String Address, String Subject, String Body) {
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        String[] toAddress = new String[]{Address};
        email.setToAddresses(toAddress);
        email.setSubject(subject);
        email.setPlainTextBody(Body);

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        inspectResults(results);
    }

    public static Boolean inspectResults(Messaging.SendEmailResult[] sendEmailResults){
        Boolean sendResult = true;
        for (Messaging.SendEmailResult res : sendEmailResults) {
            if (res.isSuccess()) {
                System.debug('Email sent successfully');
            }
            else {
                sendResult = false;
                System.debug('The following errors occurred: ' + res.getErrors());                 
            }
        }
        return sendResult;
    }
}
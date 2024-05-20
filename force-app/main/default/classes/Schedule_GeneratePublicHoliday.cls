/**
 * @author [AcekBecek]
 * @email [nurazispakaya16@mail.com]
 * @create date 2024-05-20 20:06:31
 * @modify date 2024-05-20 20:06:31
 * @desc [Schedule for Generate Public Holiday]
 */

public class Schedule_GeneratePublicHoliday implements Schedulable {

    public void execute(SchedulableContext SC) {
        Batch_GeneratePublicHoliday batch = new Batch_GeneratePublicHoliday();
        Id BatchID = Database.executeBatch(batch, 10);
    }

}
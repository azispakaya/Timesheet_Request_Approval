public with sharing class TimesheetModel {
    public cls_timesheet[] timesheet;
	public class cls_timesheet {
		public String pic;	//961903
		public String project_name;	//Example Integrasi Project to sunfish
		public String spk;	//Example Integrasi Project to sunfish
		public String start_date;	//2021-04-21
		public String end_date;	//2021-04-21
		public String stime;	//2
		public String remark;	//Project SPK 80976 - Installation
        public String billable; //1
	}
	public static TimesheetModel parse(String json){
		return (TimesheetModel) System.JSON.deserialize(json, TimesheetModel.class);
	}
}
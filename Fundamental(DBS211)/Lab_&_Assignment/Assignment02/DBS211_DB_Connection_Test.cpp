/*********************************************
Name: Dongchan Oh    
ID : 128975190      
Date : 2020 - 07 - 29
Purpose : Assignment-2 DBS211
**********************************************/

#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <occi.h>
#include <iomanip>
#include <string> 

using oracle::occi::Environment;
using oracle::occi::Connection;
using namespace oracle::occi;
using namespace std;

struct Employee
{
	int employeeNumber;
	char lastName[50];
	char firstName[50];
	char email[100];
	char phone[50];
	char extension[10];
	char reportsTo[100];
	char jobTitle[50];
	char city[50];
};

/*****************************************
*********** Function prototype ***********
*****************************************/
int menu(void);
int findEmployee(Connection *conn, int employeeNumber, struct Employee* emp);
void displayEmployee(Connection *conn, struct Employee* emp);
void displayAllEmployees(Connection *conn);
//void displayAllOffices(Connection* conn);
void insertEmployee(Connection *conn, struct Employee emp);
void updateEmployee(Connection*conn, int employeeNumber);
void deleteEmployee(Connection*conn, int employeeNumber);
int getPostNum(int max, int min);	// Utility function to get a positive number from user prompt
void getUserInputString(int length, char* field);  // Utility function to get string from user prompt
  

/**************************************************
***************** main function *******************
***************************************************/
int main(void) {
	// OCCI Variables
	Environment* env = nullptr;
	Connection* conn = nullptr;

	// User Variables
	string str;
	string usr = "dbs211_202b24";	// User ID
	string pass = "18095995";	// User password
	string srv = "myoracle12c.senecacollege.ca:1521/oracle12c";	//Server
	int userPromptInput = 0;

	try {
		env = Environment::createEnvironment(Environment::DEFAULT);
		conn = env->createConnection(usr, pass, srv);
		cout << "Connection is Successful!" << endl;

		struct Employee emp = { 0, "", "" , "" , "" , "" , "" , "" , "" };	// Initialize emp
		// Select Menu
		int flag = 0;
		do {
			int menuSelect = menu();
			if (menuSelect == 0) {	// Exit
				cout << "Goodbye " << usr << endl;
				flag = 1;
			}
			else if (menuSelect == 1) {
				// Find Employee
				cout << "Enter employeenumber: ";
				int employeeNum = getPostNum(9999, 1);	// user Input for searching employee number
				int returnedValue = findEmployee(conn, employeeNum, &emp);	// call findEmployee function
				if (returnedValue != 0) {	// If the searching user exists in DB
					displayEmployee(conn, &emp);	// Display (single) user information
				}
				else {	// If the searching user does not exist in DB
					cout << "Employee " << employeeNum << " does not exist" << endl;
				}
			}
			else if (menuSelect == 2) {	// Employees Report
				displayAllEmployees(conn);
			}
			else if (menuSelect == 3) {	// Add Employee
				cout << "Employee Number: ";
				emp.employeeNumber = getPostNum(9999, 1);	// user Input for employee number
				cout << "Last Name: ";
				getUserInputString(50, emp.lastName);	// user Input for last name
				cout << "First Name: ";
				getUserInputString(50, emp.firstName);	// user Input for first name
				cout << "Email: ";
				getUserInputString(100, emp.email);	// user Input for email
				cout << "extension: ";
				getUserInputString(10, emp.extension);	// user Input for extension
				cout << "Job Title: ";
				getUserInputString(50, emp.jobTitle);	// user Input for job title
				cout << "City: ";
				getUserInputString(50, emp.city);	// user Input for city
				insertEmployee(conn, emp);
			}
			else if (menuSelect == 4) {	// Update Employee
				cout << "Enter employeenumber: ";
				int employeeNum = getPostNum(9999, 1);	// user Input for employee number
				updateEmployee(conn, employeeNum);	// call updateEmployee function
			}
			else if (menuSelect == 5) {
				//Remove Employee
				cout << "Enter employeenumber: ";
				int employeeNum = getPostNum(9999, 1);	// user Input for employee number
				deleteEmployee(conn, employeeNum);	// call deleteEmployee function
			}
			//else if (menuSelect == 6) {
			//	displayAllOffices(conn);
			//}
		} while (flag == 0);	// Loop until user input is zero(Exit program)

		env->terminateConnection(conn);
		Environment::terminateEnvironment(env);
	}
	catch (SQLException & sqlExcp) {
		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
	}
	return 0;
}


/*************************************
********** menu function *************
**************************************/
int menu(void)
{
	int inputVal;
	cout << "********************* HR Menu *********************" << endl;
	cout << "1) Find Employee" << endl;
	cout << "2) Employees Report" << endl;
	cout << "3) Add Employee" << endl;
	cout << "4) Update Employee" << endl;
	cout << "5) Remove Employee" << endl;
	cout << "0) Exit" << endl;
	cout << "Select a menu:> ";
	return inputVal = getPostNum(5, 0);
}


/*********************************************************
***************** findEmployee function *******************
**********************************************************/
int findEmployee(Connection* conn, int employeeNumber, struct Employee* emp) {
	int returnValue = 0;

	try {
		// Quary for joining tables
		Statement* stmtJoin = conn->createStatement("SELECT\n"
			"e.employeenumber, e.lastname, e.firstname, e.email, o.phone, e.extension, e.reportsTo, e2.firstname || ' ' || e2.lastname managerName, e.jobtitle, o.city\n"
			"FROM dbs211_employees e\n"
			"JOIN dbs211_offices o ON e.officecode = o.officecode\n"
			"LEFT JOIN dbs211_employees e2 ON e.reportsto = e2.employeenumber\n"
			"WHERE e.employeenumber = :1");
		stmtJoin->setNumber(1, employeeNumber);
		ResultSet* rsJoin = stmtJoin->executeQuery();

		if (rsJoin->next()) {	// if (a) result(s) exist(s), store data to structure
			emp->employeeNumber = rsJoin->getInt(1);
			strcpy(emp->lastName, rsJoin->getString(2).c_str());
			strcpy(emp->firstName, rsJoin->getString(3).c_str());
			strcpy(emp->email, rsJoin->getString(4).c_str());
			strcpy(emp->phone, rsJoin->getString(5).c_str());
			strcpy(emp->extension, rsJoin->getString(6).c_str());
			strcpy(emp->reportsTo, rsJoin->getString(8).c_str());
			strcpy(emp->jobTitle, rsJoin->getString(9).c_str());
			strcpy(emp->city, rsJoin->getString(10).c_str());
			returnValue = 1;	// change return value
		}
		conn->terminateStatement(stmtJoin);
		return returnValue;
	}
	catch (SQLException & sqlExcp) {
		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
		cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
	}
}


/************************************************************
***************** insertEmployee function *******************
*************************************************************/
void insertEmployee(Connection* conn, struct Employee emp) {
	int returnVal = findEmployee(conn, emp.employeeNumber, &emp);
	if (returnVal == 1) {	// if the employee already exists
		cout << "An employee with the same employee number exists." << endl;
	}
	else {	// if the employee does not exist
		int maxOfficeCode;
		try {
			Statement* stmtGetMaxOfficCode = conn->createStatement();
			ResultSet* rsGetMaxOfficCode = stmtGetMaxOfficCode->executeQuery("SELECT MAX(TO_NUMBER(officecode)) FROM dbs211_offices");

			if (!rsGetMaxOfficCode->next()) {	// if the query does not return any rows
				maxOfficeCode = 0;
			}
			else {	// if the query does return any rows
				maxOfficeCode = rsGetMaxOfficCode->getInt(1);	// store max officecode into a variable maxOfficeCode
			}
			conn->terminateStatement(stmtGetMaxOfficCode);
		}
		catch (SQLException & sqlExcp) {
			cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
			cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
		}

		bool isCityExist = false;
		int officeCode = 0;
		try {	// if the user input city does not exist in DB, allocate new office code
			Statement* stmtSearchCity = conn->createStatement("SELECT o.officecode FROM dbs211_offices o WHERE o.city = :1");
			stmtSearchCity->setString(1, emp.city);
			ResultSet* rsSearchCity = stmtSearchCity->executeQuery();
			if (!rsSearchCity->next()) {
				cout << "No city" << endl;
			}
			else {
				isCityExist = true;
				officeCode = rsSearchCity->getInt(1);
			}
			conn->terminateStatement(stmtSearchCity);
		}
		catch (SQLException & sqlExcp) {
			cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
			cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
		}

		// insert city that user inputs(i.e., Toronto)
		if (isCityExist == true) {
			try {
				Statement* stmtInsert = conn->createStatement();
				stmtInsert->setSQL("INSERT INTO dbs211_employees VALUES(:1, :2, :3, :4, :5, :6, NULL, :7)");
				stmtInsert->setNumber(1, emp.employeeNumber);
				stmtInsert->setString(2, emp.lastName);
				stmtInsert->setString(3, emp.firstName);
				stmtInsert->setString(4, emp.extension);
				stmtInsert->setString(5, emp.email);
				stmtInsert->setNumber(6, officeCode);
				stmtInsert->setString(7, emp.jobTitle);
				stmtInsert->executeUpdate();

				cout << "The new employee is added successfully." << endl;
				conn->terminateStatement(stmtInsert);
			}
			catch (SQLException & sqlExcp) {
				cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
				cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
			}
		}
		else {
			try {
				Statement* stmtInsert = conn->createStatement();
				stmtInsert->setSQL("INSERT INTO dbs211_offices VALUES(:1, :2, :3, :4, NULL, NULL, :5, :6, :7)");
				int input = maxOfficeCode + 1;
				stmtInsert->setNumber(1, input);
				stmtInsert->setString(2, emp.city);
				stmtInsert->setString(3, "+1 111 111 1111");
				stmtInsert->setString(4, "Downtown");
				stmtInsert->setString(5, "CANADA");
				stmtInsert->setString(6, "000000");
				stmtInsert->setString(7, "NA");
				stmtInsert->executeUpdate();

				stmtInsert->setSQL("INSERT INTO dbs211_employees VALUES(:1, :2, :3, :4, :5, :6, NULL, :7)");
				stmtInsert->setNumber(1, emp.employeeNumber);
				stmtInsert->setString(2, emp.lastName);
				stmtInsert->setString(3, emp.firstName);
				stmtInsert->setString(4, emp.extension);
				stmtInsert->setString(5, emp.email);
				stmtInsert->setNumber(6, input);
				stmtInsert->setString(7, emp.jobTitle);
				stmtInsert->executeUpdate();
				cout << "The new employee is added successfully." << endl;
				conn->terminateStatement(stmtInsert);
			}
			catch (SQLException & sqlExcp) {
				cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
				cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
			}
		}
	}
}



/***************************************************
*********** displayAllEmployees function ***********
****************************************************/
void displayAllEmployees(Connection* conn) {
	try {
		// Standard SQL Query (without user input) //
		Statement* stmtJoin = conn->createStatement();
		ResultSet* rsJoin = stmtJoin->executeQuery("SELECT e.employeenumber, e.firstname || ' ' || e.lastname employeeName, e.email, o.phone, e.extension, e2.firstname || ' ' || e2.lastname managerName FROM dbs211_employees e JOIN dbs211_offices o ON e.officecode = o.officecode LEFT JOIN dbs211_employees e2 ON e.reportsto = e2.employeenumber ORDER BY e.employeenumber");

		if (!rsJoin->next()) {	// if the query does not return any rows
			cout << "There is no employees¡¯ information to be displayed" << endl << endl;
		}
		else {	// if the query does return any rows
			cout.width(10);
			cout << "E";
			cout.width(20);
			cout << "Employee Name";
			cout.width(35);
			cout << "Email";
			cout.width(20);
			cout << "Phone";
			cout.width(10);
			cout << "Ext";
			cout.width(20);
			cout << "Manager" << endl;
			cout << "-------------------------------------------------------------------------------------------------------------------" << endl;

			do {
				int employeeNumber = rsJoin->getInt(1);
				string employeeName = rsJoin->getString(2);
				string email = rsJoin->getString(3);
				string phone = rsJoin->getString(4);
				string ext = rsJoin->getString(5);
				string manager = rsJoin->getString(6);

				cout.width(10);
				cout << employeeNumber;
				cout.width(20);
				cout << employeeName;
				cout.width(35);
				cout << email;
				cout.width(20);
				cout << phone;
				cout.width(10);
				cout << ext;
				cout.width(20);
				cout << manager << endl;
			} while (rsJoin->next());
			cout << endl;
		}
		conn->terminateStatement(stmtJoin);
	}
	catch (SQLException & sqlExcp) {
		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
		cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
	}
}


/************************************************************
***************** updateEmployee function *******************
*************************************************************/
void updateEmployee(Connection* conn, int employeeNumber) {
	struct Employee emp = { 0, "", "" , "" , "" , "" , "" , "" , "" };
	int returnVal = findEmployee(conn, employeeNumber, &emp);
	if (returnVal == 0) {
		cout << "Employee " << employeeNumber << " does not exist" << endl;
	}
	else {
		char newExtension[10];
		cout << "Input new extension: ";
		getUserInputString(10, newExtension);
		try {
			Statement* stmtUpdate = conn->createStatement();
			stmtUpdate->setSQL("UPDATE dbs211_employees SET extension = :1\n"
				"WHERE employeenumber = :2");
			stmtUpdate->setString(1, newExtension);
			stmtUpdate->setNumber(2, employeeNumber);
			stmtUpdate->executeUpdate();

			cout << "The employee is updated successfully." << endl;
			conn->terminateStatement(stmtUpdate);
		}
		catch (SQLException & sqlExcp) {
			cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
			cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
		}
	}
}


/************************************************************
***************** deleteEmployee function *******************
*************************************************************/
void deleteEmployee(Connection* conn, int employeeNumber) {
	struct Employee emp = { 0, "", "" , "" , "" , "" , "" , "" , "" };
	int returnVal = findEmployee(conn, employeeNumber, &emp);
	if (returnVal == 0) {
		cout << "The employee does not exist" << endl;
	}
	else {
		try {
			Statement* stmtDelete = conn->createStatement();
			stmtDelete->setSQL("DELETE FROM dbs211_employees WHERE employeenumber = :1");
			stmtDelete->setNumber(1, employeeNumber);
			stmtDelete->executeUpdate();
			cout << "The employee is deleted" << endl;
			conn->terminateStatement(stmtDelete);
		}
		catch (SQLException & sqlExcp) {
			cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
			cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
		}
	}
}


/**********************************************
*********** displayEmployee function **********
**********************************************/
void displayEmployee(Connection* conn, Employee* emp) {	// display "single" user
	cout << "employeeNumber = " << emp->employeeNumber << endl;
	cout << "lastName = " << emp->lastName << endl;
	cout << "firstName = " << emp->firstName << endl;
	cout << "email = " << emp->email << endl;
	cout << "phone = " << emp->phone << endl;
	cout << "extension = " << emp->extension <<endl;
	cout << "reportsTo = " << emp->reportsTo << endl;
	cout << "jobTitle = " << emp->jobTitle << endl;
	cout << "city = " << emp->city << endl << endl;
}


/*** Utility function to get a positive number less than max and greater than min from user prompt ***/
int getPostNum(int max, int min) {
	int value;
	int keepreading = 1;
	do {
		cin >> value;

		if (cin.fail()) {   // check for invalid character
			cerr << "Invalid Integer, try again: ";
			cin.clear();
			cin.ignore(2000, '\n');
		}
		else if (value < min || value > max) {
			cerr << "Invalid selection, try again: ";
			cin.ignore(2000, '\n');
		}
		else if (char(cin.get()) != '\n') {
			cerr << "Trailing characters.  Try Again." << endl;
			cin.ignore(2000, '\n');
		}
		else {
			keepreading = 0;
		}
	} while (keepreading == 1);
	return value;
}


/********** Utility function to get an employee number from user prompt **********/
void getUserInputString(int length, char* userInputString) {
	int keepreading = 1;
	char* userInput = nullptr;
	do {
		userInput = new char[length + 1];
		cin.get(userInput, length);
		if (cin.fail()) {
			cerr << "Invalid Input, try again: ";
			cin.clear();
			cin.ignore(2000, '\n');
			delete[] userInput;
			userInput = nullptr;
		}
		else if (userInput[0] == '\0' || char(cin.get()) != '\n') {	// check if the istream object failed while reading
			cerr << "Invalid Input, try again: ";
			cin.ignore(2000, '\n');
			delete[] userInput;
			userInput = nullptr;
		}
		else {
			keepreading = 0;
			strncpy(userInputString, userInput, length);
			userInputString[length] = '\0';
			delete[] userInput;
			userInput = nullptr;
		}
	} while (keepreading == 1);
}


//void displayAllOffices(Connection* conn) {
//	Statement* stmtJoin = conn->createStatement();
//	try {
//		ResultSet* rsJoin = stmtJoin->executeQuery("SELECT * FROM dbs211_offices");
//		if (!rsJoin->next()) {	// if the query does not return any rows
//			cout << "There is no employees¡¯ information to be displayed" << endl << endl;
//		}
//		else {
//			do {
//				string employeeNumber = rsJoin->getString(1);
//				string employeeName = rsJoin->getString(2);
//				string email = rsJoin->getString(3);
//				string phone = rsJoin->getString(4);
//				string ext = rsJoin->getString(5);
//				string manager = rsJoin->getString(6);
//
//				cout.width(10);
//				cout << employeeNumber;
//				cout.width(20);
//				cout << employeeName;
//				cout.width(35);
//				cout << email;
//				cout.width(20);
//				cout << phone;
//				cout.width(10);
//				cout << ext;
//				cout.width(20);
//				cout << manager << endl;
//			} while (rsJoin->next());
//			cout << endl;
//		}
//		conn->terminateStatement(stmtJoin);
//	}
//	catch (SQLException & sqlExcp) {
//		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
//		cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
//	}
//}

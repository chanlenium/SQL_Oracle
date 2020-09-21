/***********************
Name: Dongchan Oh
ID : 128975190
Date : 2020 - 07 - 16
Purpose : Assignment-1 DBS211
************************/

#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <occi.h>
#include <iomanip>

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

/********** Function prototype **********/
int menu(void);
int findEmployee(Connection *conn, int employeeNumber, struct Employee* emp);
void displayEmployee(Connection *conn, struct Employee* emp);
void displayAllEmployees(Connection *conn);
int getEmployeeNum(void);	// Utility function to get emloyeenumber from user prompt
int getPostNum(int);	// Utility function to get a positive number from user prompt


/********** main function **********/
int main(void) {
	// OCCI Variables
	Environment* env = nullptr;
	Connection* conn = nullptr;

	// User Variables
	string str;
	string usr = "dbs211_202b24";
	string pass = "18095995";
	string srv = "myoracle12c.senecacollege.ca:1521/oracle12c";
	int userPromptInput = 0;

	try{
		env = Environment::createEnvironment(Environment::DEFAULT);
		conn = env->createConnection(usr, pass, srv);
		cout << "Connection is Successful!" << endl;

		int flag = 0;
		do {
			int menuSelect = menu();
			if (menuSelect == 0) {
				// Exit
				cout << "Goodbye " << usr << endl;
				flag = 1;
			}
			else if (menuSelect == 1) {
				// Find Employee
				struct Employee emp = { 0, "", "" , "" , "" , "" , "" , "" , "" };
				cout << "Enter employeenumber: ";
				int employeeNum = getEmployeeNum();
				int returnedValue = findEmployee(conn, employeeNum, &emp);
				if (returnedValue != 0) {
					displayEmployee(conn, &emp);
				}
				else {
					cout << "Employee " << employeeNum << " does not exist" << endl;
				}
			}
			else if (menuSelect == 2) {
				// Employees Report
				displayAllEmployees(conn);
			}
			else if (menuSelect == 3) {
				// Add Employee
			}
			else if (menuSelect == 4) {
				// Update Employee
			}
			else if (menuSelect == 5) {
				// Remove Employee
			}
		} while (flag == 0);	// Loop until user input is zero(Exit program)

		env->terminateConnection(conn);
		Environment::terminateEnvironment(env);
	}
	catch (SQLException & sqlExcp) {
		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
	}
	return 0;
}


/********** findEmployee function **********/
int findEmployee(Connection* conn, int employeeNumber, struct Employee* emp) {
	int returnValue = 0;

	try {
		// Quary for joining tables
		Statement* stmtJoin = conn->createStatement("SELECT e.employeenumber, e.lastname, e.firstname, e.email, o.phone, e.extension, e.reportsTo, e2.firstname || ' ' || e2.lastname managerName, e.jobtitle, o.city FROM dbs211_employees e JOIN dbs211_offices o ON e.officecode = o.officecode LEFT JOIN dbs211_employees e2 ON e.reportsto = e2.employeenumber WHERE e.employeenumber = :1");
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

/********** displayAllEmployees function **********/
void displayAllEmployees(Connection* conn) {
	// Standard SQL Query (without user input) //
	Statement* stmtJoin = conn->createStatement();
	try{
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


/********** displayEmployee function **********/
void displayEmployee(Connection* conn, Employee* emp) {
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


/********** menu function **********/
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

	return inputVal = getPostNum(5);
}

/********** Utility function to get a positive number less than max from user prompt **********/
int getPostNum(int max) {
	int value;
	int keepreading;

	keepreading = 1;
	do {
		cout << "Enter a positive integer (<= " << max << ") : ";
		cin >> value;

		if (cin.fail()) {   // check for invalid character
			cerr << "Invalid character.  Try Again." << endl;
			cin.clear();
			cin.ignore(2000, '\n');
		}
		else if (value < 0 || value > max) {
			cerr << value << " is outside the range [1," <<
				max << ']' << endl;
			cerr << "Invalid input.  Try Again." << endl;
			cin.ignore(2000, '\n');
			// you may choose to omit this branch
		}
		else if (char(cin.get()) != '\n') {
			cerr << "Trailing characters.  Try Again." << endl;
			cin.ignore(2000, '\n');
		}
		else
			keepreading = 0;
	} while (keepreading == 1);
	return value;
}

/********** Utility function to get an employee number from user prompt **********/
int getEmployeeNum(void) {
	int value;
	int keepreading;

	keepreading = 1;
	do {
		cin >> value;

		if (cin.fail()) {   // check for invalid character
			cerr << "Invalid Integer, try again: ";
			cin.clear();
			cin.ignore(2000, '\n');
		}
		else if (value < 0) {
			cerr << "Invalid selection, try again: ";
			cin.ignore(2000, '\n');
		}
		else if (char(cin.get()) != '\n') {
			cerr << "Trailing characters.  Try Again." << endl;
			cin.ignore(2000, '\n');
		}
		else
			keepreading = 0;
	} while (keepreading == 1);
	return value;
}

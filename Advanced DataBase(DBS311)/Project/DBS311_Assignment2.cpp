/*********************************************
Name: Dongchan Oh / Ayumi Ueda / Krima Patel
ID : 128975190
Date : 2020 - 11 - 16
Purpose : Assignment-2 DBS311
**********************************************/

#define _CRT_SECURE_NO_WARNINGS
#include <iostream>
#include <occi.h>
#include <iomanip>

using oracle::occi::Environment;
using oracle::occi::Connection;
using namespace oracle::occi;
using namespace std;

struct ShoppingCart
{
	int product_id = 0;
	double price = 0;
	int quantity = 0;
};

/*****************************************
*********** Function prototype ***********
*****************************************/
int menu(void);
int customerLogin(Connection* conn, int customerId);
int addToCart(Connection* conn, struct ShoppingCart cart[]);
double findProduct(Connection* conn, int product_id);
void displayProducts(struct ShoppingCart cart[], int productCount);
int checkout(Connection* conn, struct ShoppingCart cart[], int customerId, int productCount);
int getPostNum(int max, int min);	// Utility function to get a positive number from user prompt
bool yesNo();	// Utility function to get Yes/No from user prompt

/**************************************************
***************** main function *******************
***************************************************/
int main(void) {
	// OCCI Variables
	Environment* env = nullptr;
	Connection* conn = nullptr;

	// User Variables
	string str;
	string usr = "dbs311_203d29";	// User ID
	string pass = "30801106";	// User password
	string srv = "myoracle12c.senecacollege.ca:1521/oracle12c";	//Server

	try {
		env = Environment::createEnvironment(Environment::DEFAULT);
		conn = env->createConnection(usr, pass, srv);
		cout << "Connection is Successful!" << endl;

		// Initialize ShoppingCart
		struct ShoppingCart cart[5] = { {0, 0, 0} , {0, 0, 0} , {0, 0, 0} , {0, 0, 0} , {0, 0, 0} };	
		
		// Select Menu
		int flag = 0;
		do {
			int isCustFound = 0;
			do {
				int menuSelect = menu();
				if (menuSelect == 0) {	// Exit
					cout << "Good bye!...\n";
					flag = 1;
					isCustFound = 1;
				}
				else if (menuSelect == 1) {
					// Ask the user to enter customer ID to Login
					cout << "Enter the customer ID: ";
					int inputCustID = getPostNum(10000, 1);	// user Input for searching customer number

					isCustFound = customerLogin(conn, inputCustID);						// call customerLogin function	
					if (isCustFound) {													// when the inputCustID is valid
						int numOfItems = addToCart(conn, cart);							// call addToCart function
						displayProducts(cart, numOfItems);								// call displayProducts function
						int newOrderId = checkout(conn, cart, inputCustID, numOfItems);	// call checkout function
						if (newOrderId == 0) {											// When the order is cancelled
							cout << "The order is cancelled\n";
							isCustFound = 0;
						}
						else {
							cout << "The order is successfully completed.\n";
							isCustFound = 0;
						}
					}
					else {																// when the inputCustID is invalid
						cout << "The customer does not exist." << endl;
					}
				}
			} while (isCustFound == 0);
		} while (flag == 0);															// Loop until user input is zero(Exit program)
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
	cout << "********************* Main Menu by Oh/Ueda/Patel *********************" << endl;
	cout << "1) Login" << endl;
	cout << "0) Exit" << endl;
	cout << "Enter an option (0-1):> ";
	return inputVal = getPostNum(1, 0);
}


/*********************************************************
***************** customerLogin function *****************
**********************************************************/
int customerLogin(Connection* conn, int customerId) {
	int returnValue = 0;
	try {
		Statement* stmt = conn->createStatement();
		stmt->setSQL("BEGIN find_customer(:1, :2); END;");
		stmt->setNumber(1, customerId);
		int isFound = 0;
		stmt->registerOutParam(2, Type::OCCINUMBER, sizeof(isFound));
		stmt->executeUpdate();
		returnValue = stmt->getNumber(2);
		return returnValue;
	}
	catch (SQLException & sqlExcp) {
		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
		cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
	}
}


/*****************************************************
***************** addToCart function *****************
******************************************************/
int addToCart(Connection* conn, struct ShoppingCart cart[]) {
	int addMore = 1;
	int inputProdId;
	int numOfItems = 0;
	do {
		cout << "Enter the product ID: ";
		inputProdId = getPostNum(100000, 1);
		double price = findProduct(conn, inputProdId);

		if (price == 0) {
			cout << "The product does not exist. Try again.. \n";
		}
		else {
			cart[numOfItems].product_id = inputProdId;

			cout << "Product price: " << price << endl;
			cart[numOfItems].price = price;

			cout << "Enter the product Quantity : ";
			int prodQuantity;
			prodQuantity = getPostNum(100, 1);
			cart[numOfItems].quantity = prodQuantity;

			cout << "Product price : " << cart[numOfItems].price << endl;

			cout << "Enter 1 to add more products to 0 to checkout: ";
			addMore = getPostNum(1, 0);
			if (addMore == 0) {	// No more add
				return ++numOfItems;
			}
			else {
				numOfItems++;
			}
		}
	} while (addMore == 1);
}


/*******************************************************
***************** findProduct function *****************
********************************************************/
double findProduct(Connection* conn, int product_id) {
	try {
		Statement* stmt = conn->createStatement();
		stmt->setSQL("BEGIN find_product(:1, :2); END;");
		stmt->setNumber(1, product_id);
		double price;
		stmt->registerOutParam(2, Type::OCCIDOUBLE, sizeof(price));
		stmt->executeUpdate();
		price = stmt->getDouble(2);
		return price;
	}
	catch (SQLException & sqlExcp) {
		cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
		cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
	}
}


/****************************************************
***************** checkout function *****************
*****************************************************/
int checkout(Connection* conn, struct ShoppingCart cart[], int customerId, int productCount) {
	cout << "Would you like to checkout? (Y/y or N/n) ";
	bool isCheckout = yesNo();
	if (isCheckout) {	// checkout
		try {
			Statement* stmt = conn->createStatement();
			stmt->setSQL("BEGIN add_order(:1, :2); END;");
			stmt->setNumber(1, customerId);
			int newOrderID;
			stmt->registerOutParam(2, Type::OCCINUMBER, sizeof(newOrderID));
			stmt->executeUpdate();
			newOrderID = stmt->getNumber(2);

			for (int i = 0; i < productCount; i++) {
				try{
					Statement* stmtAddOrderItems = conn->createStatement();
					stmtAddOrderItems->setSQL("BEGIN add_order_item(:1, :2, :3, :4, :5); END;");
					stmtAddOrderItems->setNumber(1, newOrderID);
					stmtAddOrderItems->setNumber(2, i+1);
					stmtAddOrderItems->setNumber(3, cart[i].product_id);
					stmtAddOrderItems->setNumber(4, cart[i].quantity);
					stmtAddOrderItems->setNumber(5, cart[i].price);
					stmtAddOrderItems->executeUpdate();
				}catch (SQLException & sqlExcp) {
					cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
					cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
				}
			}
			return newOrderID;
		}
		catch (SQLException & sqlExcp) {
			cout << sqlExcp.getErrorCode() << ": " << sqlExcp.getMessage();
			cout << "There is an error in your quiry statement. Refer error code." << endl << endl;
		}
	}
	else {
		return 0;
	}
}


/***********************************************************
***************** displayProducts function *****************
***********************************************************/
void displayProducts(struct ShoppingCart cart[], int productCount) {
	cout << "------- Ordered Products -------\n";
	double total = 0;
	for (int i = 0; i < productCount; i++) {
		cout << "---Item " << (i+1) << endl;
		cout << "Product ID: " << cart[i].product_id << endl;
		cout << "Price: " << cart[i].price << endl;
		cout << "Quantity: " << cart[i].quantity << endl;
		total = total + (cart[i].price * cart[i].quantity);
	}
	cout << "--------------------------------\n";
	cout << "Total: " << total << endl;
}


/*** Utility function to get a positive number less than max and greater than min from user prompt ***/
int getPostNum(int max, int min) {
	int value;
	int keepreading = 1;
	do {
		cin >> value;

		if (cin.fail()) {   // check for invalid character
			if (max == 1 && min == 0)
				cerr << "You entered a wrong value. Enter and option (0-1): ";
			else
				cerr << "You entered a wrong value. Enter a positive number (" << min << "-" << max << "): ";
			cin.clear();
			cin.ignore(2000, '\n');
		}
		else if (value < min || value > max) {
			if (max == 1 && min == 0)
				cerr << "You entered a wrong value. Enter and option (0-1): ";
			else
				cerr << "You entered a wrong value. Enter a positive number (" << min << "-" << max << "): ";
			cin.ignore(2000, '\n');
		}
		else if (char(cin.get()) != '\n') {
			if (max == 1 && min == 0)
				cerr << "You entered a wrong value. Enter and option (0-1): ";
			else
				cerr << "You entered a wrong value. Enter a positive number (" << min << "-" << max << "): ";
			cin.ignore(2000, '\n');
		}
		else {
			keepreading = 0;
		}
	} while (keepreading == 1);
	return value;
}

/*** Utility function to get a Yes(Y/y) or No(N/n) from user prompt ***/
bool yesNo() {
	char inputVal;
	bool returnVal = false, run = true;
	do {
		cin >> inputVal;
		if (cin.fail() || char(cin.get()) != '\n') {
			cerr << "Invalid response, only (Y)es or (N)o are acceptable, retry: ";
			cin.clear();
			cin.ignore(2000, '\n');
		}
		else {
			run = false;
			if (inputVal == 'N' || inputVal == 'n') {
				returnVal = false;
			}
			else if (inputVal == 'Y' || inputVal == 'y') {
				returnVal = true;
			}
			else {
				cerr << "Invalid response, only (Y)es or (N)o are acceptable, retry: ";
				cin.clear();
				cin.ignore(2000, '\n');
			}
		}
	} while (run);
	return returnVal;
}
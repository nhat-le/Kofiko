//------------------------------------------------------------------------------
// Keil Software, Inc.
// 
// Project: 	I2C EXAMPLE PROGRAM (BIT BANGED) FOR MCB520 MCU
//
// Filename: 	MCB520_I2C_Example_Bit_Banged.c
// Version: 	1.0.0
// Description:	This file contains example code to print over the serial
//				port of the MCB520 MCU and Evaultion Board (EVAL-MCB520QS).
//				This example will test the I2C function of the MCB520.
//				This will be done by writing and reading from
//				a serial A/D & D/A (P8591).
//				
//				This example will bit bang two general I/O ports for I2C
//
//				The example work with communicate at: 9600, 8, N, 1.
//
//				This code was tested using the mon-51 connected through COM-1
//				of the eval board.
//				CPU Frequency: 33.00 MHz
//
// Copyright 2000 - Keil Software, Inc.
// All rights reserved.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Header files
//------------------------------------------------------------------------------
#include <REG320.H>							// Header file for the MCB520 MCU
#include <STDIO.H>							// Standard I/O header file

sbit  P1_0 	= P1^0;							// Define the individual bit
sbit  P1_1 	= P1^1;							// Define the individual bit

//------------------------------------------------------------------------------
// Value Definitions
//------------------------------------------------------------------------------
#define 	TRUE			0x01			// Value representing TRUE
#define		FALSE			0x00			// Value representing FALSE
#define 	ON				0x01			// Value representing ON
#define		OFF				0x00			// Value representing OFF
#define 	HIGH			0x01			// Value representing ON
#define		LOW				0x00			// Value representing OFF

#define  	DELAY_WAIT		5000			// Value for delay time 

//------------------------------------------------------------------------------
// I/O Port Defines
//------------------------------------------------------------------------------
#define  	SDATA			P1_0			// Serial data
#define  	SCLK			P1_1			// Serial clock

//------------------------------------------------------------------------------
// I2C Peripheral Function Prototypes
//------------------------------------------------------------------------------
											// Reads the ADC value for a given channel
unsigned char read_adc_channel(unsigned char channel_number);
void write_dac (unsigned char voltage_out);	// Writes a byte to the DAC

//------------------------------------------------------------------------------
// I2C Functions - Bit Banged
//------------------------------------------------------------------------------
void i2c_start (void);						//	Sends I2C Start Trasfer
void i2c_stop (void);						//	Sends I2C Stop Trasfer
void i2c_write (unsigned char input_data);	//	Writes data over the I2C bus
unsigned char i2c_read (void);				//	Reads data from the I2C bus

//------------------------------------------------------------------------------
// Support Function Prototypes
//------------------------------------------------------------------------------
void initialize_system (void);				// Initializes MCU (RS-232)
void delay_time (unsigned int time_end);    // To pause execution for pre-determined time

//------------------------------------------------------------------------------
// MAIN FUNCTION 
//------------------------------------------------------------------------------
void main (void)
{
	unsigned char voltage_out;

	initialize_system();

	printf("\n\rKeil Software, Inc.\n\r");	// Display starup message
	printf("MCB520 MCU I�C Example Test Program\n\r");
	printf("Version 1.0.0\n\r");
	printf("Copyright 2000 - Keil Software, Inc.\n\r");
	printf("All rights reserved.\n\n\r");

	printf("P8591 Test Program....Reading from ADC channel 0, Writing to DAC!\n\r");


	while (TRUE)
	{
		for (voltage_out = 0; voltage_out < 0xFF; voltage_out++)
		{

			write_dac(voltage_out);			// Write voltage value to DAC

			delay_time(DELAY_WAIT);

											// Read voltage (ADC 0) and display results
   			printf("DAC output: %3bu     ADC Channel 0: %3bu\n\r", voltage_out, read_adc_channel(0x00));
		}
	}
}

//------------------------------------------------------------------------------
// I2C Peripheral Function Prototypes
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure:	write_dac
// Inputs:		voltage_out
// Outputs:		none
// Description:	Writes a byte to the DAC
//------------------------------------------------------------------------------
void write_dac (unsigned char voltage_out)	
{
  	i2c_start();                  			// Send I2C Start Transfer
   	i2c_write(0x90);              			// Send identifier I2C address - Write
   	i2c_write(0x40);			 			// Send control byte to device
   	i2c_write(voltage_out);            		// Send voltage to DAC
   	i2c_stop();                   			// Send I2C Stop Transfer
}

//------------------------------------------------------------------------------
// Procedure:	read_adc_channel
// Inputs:		channel
// Outputs:		none
// Description:	Reads the ADC value for a given channel
//------------------------------------------------------------------------------
unsigned char read_adc_channel(unsigned char channel_number)
{
   	unsigned char data_in;

  	i2c_start();                  			// Send I2C Start Transfer
   	i2c_write(0x90);  						// Send identifier I2C address - Write
   	i2c_write(0x40 | channel_number);		// Send control byte to device (last 2 bits is the channel)
   	i2c_stop();                   			// Send I2C Stop Transfer

   	i2c_start();                  			// Send I2C Start Transfer
   	i2c_write(0x91);              			// Send identifier I2C address - Read
	data_in = i2c_read();					// Read the channel number

   	return data_in;                 
}

//------------------------------------------------------------------------------
// I2C Functions - Bit Banged
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// 	Routine:	i2c_start
//	Inputs:		none
//	Outputs:	none
//	Purpose:	Sends I2C Start Trasfer - State "B"
//------------------------------------------------------------------------------
void i2c_start (void)
{
	SDATA = HIGH;							// Set data line high
	delay_time(10);
	SCLK = HIGH;							// Set clock line high
	delay_time(1);
	SDATA = LOW;							// Set data line low (START SIGNAL)
	SCLK = LOW;								// Set clock line low
}

//------------------------------------------------------------------------------
// 	Routine:	i2c_stop
//	Inputs:		none
//	Outputs:	none
//	Purpose:	Sends I2C Stop Trasfer - State "C"
//------------------------------------------------------------------------------
void i2c_stop (void)
{
	unsigned char input_var;

	SCLK = LOW;								// Set clock line low
	SDATA = LOW;							// Set data line low
	SCLK = HIGH;							// Set clock line high
	delay_time(1);
	SDATA = HIGH;							// Set data line high (STOP SIGNAL)
	input_var = SDATA;						// Put port pin into HiZ
}

//------------------------------------------------------------------------------
// 	Routine:	i2c_write
//	Inputs:		output byte
//	Outputs:	none
//	Purpose:	Writes data over the I2C bus
//------------------------------------------------------------------------------
void i2c_write (unsigned char output_data)
{
	unsigned char index;

	for(index = 0; index < 8; index++)  	// Send 8 bits to the I2C Bus
	{
                                 			// Output the data bit to the I2C Bus
		SDATA = ((output_data & 0x80) ? 1 : 0);
      	output_data  <<= 1;            		// Shift the byte by one bit
		SCLK = HIGH;   		        		// Clock the data into the I2C Bus
		delay_time(1);
		SCLK = LOW;					
	}

	index = SDATA;							// Put data pin into read mode
	SCLK = HIGH;   		        			// Clock the ACK from the I2C Bus
	delay_time(1);
	SCLK = LOW;					
}

//------------------------------------------------------------------------------
// 	Routine:	i2c_read
//	Inputs:		none
//	Outputs:	input byte
//	Purpose:	Reads data from the I2C bus
//------------------------------------------------------------------------------
unsigned char i2c_read (void)
{
	unsigned char index, input_data;

   	index = SDATA;							// Put data pin into read mode

	input_data = 0x00;
	for(index = 0; index < 8; index++)  	// Send 8 bits to the I2C Bus
	{
		input_data <<= 1;					// Shift the byte by one bit
		SCLK = HIGH;           				// Clock the data into the I2C Bus
      	input_data |= SDATA; 		   		// Input the data from the I2C Bus
		delay_time(1);
		SCLK = LOW;					
	}

   return input_data;
}

//------------------------------------------------------------------------------
// SUPPORT FUNCTIONS
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure:	initialize_system
// Inputs:		none
// Outputs:		none
// Description:	Initializes embedded system MCU LPC764
//------------------------------------------------------------------------------
void initialize_system (void)
{
// Initialize the serial port (9600, 8, N, 1) 
	PCON |= 0x80;							// Set bit 7 of the PCON register (SMOD = 1)  
	SCON0 = 0x50;							// 0101,0000 (Mode 1 and RxD enable)			
	TMOD |= 0x20;							// Timer #1 in autoreload 8 bit mode
	TH1 = 0xCA;								// Baud rate is determined by
											// Timer #1 overflow rate
	TR1 = 1;								// Turn on Timer 1
	TI = 1;									// Set UART to send first char
}

////////////////////////////////////////////////////////////////////////////////
// 	Routine:	delay_time
//	Inputs:		counter value to stop delaying
//	Outputs:	none
//	Purpose:	To pause execution for pre-determined time
////////////////////////////////////////////////////////////////////////////////
void delay_time (unsigned int time_end)
{
	unsigned int index;
	for (index = 0; index < time_end; index++);
}



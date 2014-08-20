#include <stdio.h>
#include "mex.h"
#include <math.h>
#include "cbw.h"
#include <mmsystem.h>

const int Pow2[15] = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192, 16384};
const int Pow2Rev[15] = {16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1};

int BoardNum=0;
const int EYE_X_PORT = 0; // hard wired for a faster implementation, but can always be acquired using GetAnalog command
const int EYE_Y_PORT = 1;

void fnSleep(double fWaitSecHighPerc) {

	LARGE_INTEGER prevTime;
	LARGE_INTEGER curTime;
	LARGE_INTEGER freqValue;
	double timeDifference;

	if (fWaitSecHighPerc <= 0)
		return;

	QueryPerformanceFrequency(&freqValue);
	QueryPerformanceCounter(&prevTime);

	while (1)
	{
		QueryPerformanceCounter(&curTime);
		timeDifference = curTime.QuadPart - prevTime.QuadPart;
		if (timeDifference / freqValue.QuadPart >= fWaitSecHighPerc )
			break;
	}     
}
void fnPrintUsage()
{
	mexPrintf("Usage:\n");
	mexPrintf("fnDAQREDBox(command, param)\n");
	mexPrintf("\n");
	mexPrintf("Commands are: \n");
	mexPrintf("Init    [initializes ports, must call before any other function] \n");
	mexPrintf("SetBit(BitNumber [0,23], BitValue [0,1]) \n");
	
	mexPrintf("DO(PortNumber [0,3], BitValue [0,1]) \n");
	
	mexPrintf("TTL(BitNumber [0,23], \n");
	mexPrintf("afValues = GetAnalog(aiChannels) \n");
		
	mexPrintf("\n");
	mexPrintf("\n");
	mexPrintf("More specific commands that are relevant for the to behavior machine:\n");
	mexPrintf("\n");
	mexPrintf("StrobeWord(Number 0..2^15-1),     [sends a 15 bit word, output bits are hard wired] \n");
	mexPrintf("\n");
}

void fnGetPortTypeAndFirstBit(int PortNumber,  int &PortType, int &FirstBit)
{
	switch (PortNumber) {
			 case 0:
				 PortType = FIRSTPORTA;
				 FirstBit = 0;
				 break;
			 case 1:
				 PortType = FIRSTPORTB;
				 FirstBit = 8;
				 break;
			 case 2:
				 PortType = FIRSTPORTCL;
				 FirstBit = 16;
				 break;
			 case 3:
				 PortType = FIRSTPORTCH;
				 FirstBit = 20;
				 break;
	}
}


void mexFunction( int nlhs, mxArray *plhs[], 
				 int nrhs, const mxArray *prhs[] ) 
{

	int ULStat,UDStat;

	if (nrhs < 1) {
		fnPrintUsage();
		return;
	}
	

	int StringLength = int(mxGetNumberOfElements(prhs[0])) + 1;
	char* Command = (char*)mxCalloc(StringLength, sizeof(char));

	if (mxGetString(prhs[0], Command, StringLength) != 0){
		mexErrMsgTxt("\nError extracting the command.\n");
		return;
	}

	if   (strcmp(Command, "StrobeWord") == 0) {
		/* get a user value to write to the port */
		int Number;
		if (mxIsDouble(prhs[1]))
			Number = int(*(double*)mxGetData(prhs[1]));
		else if (mxIsSingle(prhs[1]))
			Number = int(*(float*)mxGetData(prhs[1]));
		else if (mxIsUint8(prhs[1]))
			Number = int(*(char*)mxGetData(prhs[1]));
		else Number = 0;

		unsigned char LowByte = Number & 255;
		unsigned char HighByte = (Number >> 8) & 127; // Set strobe to zero

		ULStat = cbDOut(BoardNum, FIRSTPORTA, LowByte);
		ULStat = cbDOut(BoardNum, FIRSTPORTB, HighByte);
		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, 15, 1); // Trigger strobe

		//Plexon Manual says Pulse width must be greater or eq 250 usec.
        fnSleep(250 * 1e-6);

		//ULStat = cbDBitOut (BoardNum, FIRSTPORTA, 15, 0); 

		ULStat = cbDOut(BoardNum, FIRSTPORTA, 0);
		ULStat = cbDOut(BoardNum, FIRSTPORTB, 0);

		int dim[1] = {1};
		plhs[0] = mxCreateNumericArray(1, dim, mxDOUBLE_CLASS, mxREAL);
		double *Out = (double*)mxGetPr(plhs[0]);
		*Out = ULStat == NOERRORS;

 		return;
	} else if (strcmp(Command, "GetAnalog") == 0) {

		const int *dim = mxGetDimensions(prhs[1]);
		double *Channels = (double*)mxGetData(prhs[1]);
		
		plhs[0] = mxCreateNumericArray(2, dim, mxDOUBLE_CLASS, mxREAL);
		int Gain = BIP5VOLTS;
		double *MatlabData= (double*)mxGetPr(plhs[0]);

		int NumElements = dim[0] > dim[1] ? dim[0] : dim[1];
		WORD Data;

		for (int iIter = 0; iIter< NumElements;iIter++) {
			int Channel = int(Channels[iIter]);
			// assume +- 5V
			UDStat = cbAIn (BoardNum, Channel, Gain, &Data);
			//ASSERT(UDStat == NOERRORS);
			MatlabData[iIter] = double(Data);
		}

	} else if (strcmp(Command, "Init") == 0) {

		BoardNum = int(*(double*)mxGetData(prhs[1]));

		float    RevLevel = (float)CURRENTREVNUM;
		ULStat = cbDeclareRevision(&RevLevel);  
		int ULStat1,ULStat2,ULStat3,ULStat4,ULStat5;
		//cbErrHandling (PRINTALL, DONTSTOP);
		
		cbErrHandling (DONTPRINT, DONTSTOP);
        // Setup all digital ports to be "OUT"
		ULStat1 = cbDConfigPort (BoardNum, FIRSTPORTA, DIGITALOUT);
		//assert(ULStat == NOERRORS);
		ULStat2 = cbDConfigPort (BoardNum, FIRSTPORTB, DIGITALOUT);
		//assert(ULStat == NOERRORS);
		ULStat3 = cbDConfigPort (BoardNum, FIRSTPORTCL, DIGITALOUT);
		//assert(ULStat == NOERRORS);
		ULStat4 = cbDConfigPort (BoardNum, FIRSTPORTCH, DIGITALOUT);
		//assert(ULStat == NOERRORS);
		// Zero out all lines
		for (int Bit=0;Bit<=23;Bit++)  {
			ULStat5 = cbDBitOut(BoardNum, FIRSTPORTA, Bit, 0);
			if (ULStat5 != NOERRORS)
				break;
		}

		int dim[1] = {1};
		plhs[0] = mxCreateNumericArray(1, dim, mxDOUBLE_CLASS, mxREAL);
		double *Out = (double*)mxGetPr(plhs[0]);
		*Out = (ULStat1 != NOERRORS || ULStat2 != NOERRORS || ULStat3 != NOERRORS || ULStat4 != NOERRORS || ULStat5 != NOERRORS);

	} else if (strcmp(Command, "SetBit") == 0) {
		/* get a user value to write to the port */
		int BitNumber = int(*(double*)mxGetData(prhs[1]));
		bool BitValue = int(*(double*)mxGetData(prhs[2])) > 0;
        int BitNumber2=BitNumber-25;
        
        if (BitNumber<25)
    		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, BitNumber, BitValue);
        else
            {ULStat = cbDBitOut (BoardNum, AUXPORT, BitNumber2, BitValue);}
            
                
		
        int dim[1] = {1};
		plhs[0] = mxCreateNumericArray(1, dim, mxDOUBLE_CLASS, mxREAL);
		double *Out = (double*)mxGetPr(plhs[0]);
		*Out = ULStat == NOERRORS;
		return;
		
	} else if (strcmp(Command, "DO") == 0) {
		/* get a user value to write to a DO port */
		int PortNumber = int(*(double*)mxGetData(prhs[1]));
		int DataValue = int(*(double*)mxGetData(prhs[2]));
		/* ULStat = cbDBitOut (BoardNum, FIRSTPORTA, BitNumber, BitValue); */
		ULStat = cbDOut(BoardNum, AUXPORT, DataValue);
		int dim[1] = {1};
		plhs[0] = mxCreateNumericArray(1, dim, mxDOUBLE_CLASS, mxREAL);
		double *Out = (double*)mxGetPr(plhs[0]);
		*Out = ULStat == NOERRORS;
		return;

	} else if (strcmp(Command, "TTL") == 0) {
		/* get a user value to write to the port. TTL Pulse is roughly 5 micro sec. Non blocking operation.... */
		int BitNumber = int(*(double*)mxGetData(prhs[1]));
        int BitNumber2=BitNumber-25;

		double fWidthSec = *(double*)mxGetData(prhs[2]);
        
        if (BitNumber<25)
        {
    		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, BitNumber, 1);
            fnSleep(fWidthSec); 
            ULStat = cbDBitOut (BoardNum, FIRSTPORTA, BitNumber, 0);
        }
        else
        {
            ULStat = cbDBitOut (BoardNum, AUXPORT, BitNumber2, 1);
            fnSleep(fWidthSec); 
            ULStat = cbDBitOut (BoardNum, AUXPORT, BitNumber2, 0);
        }
        
        int dim[1] = {1};
		plhs[0] = mxCreateNumericArray(1, dim, mxDOUBLE_CLASS, mxREAL);
		double *Out = (double*)mxGetPr(plhs[0]);
		*Out = ULStat == NOERRORS;
		return;
        
	} else if (strcmp(Command, "SetByte") == 0) {
		  int PortNumber = int(*(double*)mxGetData(prhs[1]));
		  unsigned char DataByte= (unsigned char)(*(double*)mxGetData(prhs[2]));	

		  int PortType, FirstBit;
		  fnGetPortTypeAndFirstBit(PortNumber, PortType, FirstBit);

		  ULStat = cbDOut(BoardNum, PortType, DataByte);
		int dim[1] = {1};
		plhs[0] = mxCreateNumericArray(1, dim, mxDOUBLE_CLASS, mxREAL);
		double *Out = (double*)mxGetPr(plhs[0]);
		*Out = ULStat == NOERRORS;
	} else if (strcmp(Command, "DelayedTrigger") == 0) {
		// Used to shut down the head stage amplifier just before stimulation trigger....
		int GatePort = int(*(double*)mxGetData(prhs[1]));
		int TriggerPort = int(*(double*)mxGetData(prhs[2]));
		double TriggerDelayMS = *(double*)mxGetData(prhs[3]);
		double GatePeriodMS = *(double*)mxGetData(prhs[4]);
		double FirstPulseLengthMS = *(double*)mxGetData(prhs[5]);
		double SecondPulseLengthMS = *(double*)mxGetData(prhs[6]);
		double InterPulseIntervalMS = *(double*)mxGetData(prhs[7]);
		
		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, GatePort, 1); // Shut down head stage
		fnSleep(TriggerDelayMS/1000.0); // Usually, 1ms for safety in BAK amplifier

		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, TriggerPort, 1); // First Pulse
		fnSleep(FirstPulseLengthMS/1000.0); // Usually, 1ms for safety in BAK amplifier
		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, TriggerPort, 0); // First Pulse off
		fnSleep(InterPulseIntervalMS/1000.0);  
		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, TriggerPort, 1); // Second Pulse on
		fnSleep(SecondPulseLengthMS/1000.0);  
		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, TriggerPort, 0); // Second Pulse off
		fnSleep((GatePeriodMS-(TriggerDelayMS+FirstPulseLengthMS+SecondPulseLengthMS+InterPulseIntervalMS))/1000.0); // Usually, 1ms for safety in BAK amplifier
		ULStat = cbDBitOut (BoardNum, FIRSTPORTA, GatePort, 0); // Head stage is back on
	} else if (strcmp(Command, "WaveFormOut") == 0) {
	 int  I;
    int BoardNum = 0;
    int NumChan = 2;
    int ULStat = 0;
    int LowChan, HighChan;
    int Options;
    int Gain = BIP5VOLTS;
    WORD ADData[2048*2];
    long Count, Rate;
    float    RevLevel = (float)CURRENTREVNUM;

  /* Declare UL Revision Level */
   ULStat = cbDeclareRevision(&RevLevel);

    /* Initiate error handling
        Parameters:
            PRINTALL :all warnings and errors encountered will be printed
            DONTSTOP :program will continue even if error occurs.
                     Note that STOPALL and STOPFATAL are only effective in 
                     Windows applications, not Console applications. 
   */
   cbAOut( BoardNum, 0, BIP5VOLTS,0);
   /*
	   
   for (int j=0;j<10;j++) {
	   for (int k=0;k<2048;k++) {
		   cbAOut( BoardNum, 0, BIP5VOLTS,k);
	   }
	   for (int k=2048;k>=0;k--) {
		   cbAOut( BoardNum, 0, BIP5VOLTS,k);
	   }

   }
*/
    /* load the output array with values */
   for (I = 0; I < 2048*2; I++) {
	   ADData[I] = (I>2048) ? 2048-I:I;
   }
 
    /* send the output values to the D/A range using cbAOutScan() */
    /* Parameters:
            BoardNum    :the number used by CB.CFG to describe this board
            LowChan     :the lower channel of the scan
            HighChan    :the upper channel of the scan
            Count       :the number of D/A values to send
            Rate        :send rate in values/second
            Gain        :the gain of the D/A
            ADData[]    :array of values to send to the scanned channels
            Options     :data send options  */
    Count = 1;  /* for all boards other than SBX-DD04,
                                        Count = the number of channels */
	int NumPoints = 2048*2;
    Rate = 128;
    Options = 0;
    ULStat = cbAOutScan (BoardNum, 0, 0, NumPoints, &Rate, Gain, ADData,Options);

	} else  {
		fnPrintUsage();
	}

}


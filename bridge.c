#include "./bridge.h"
#include <stdio.h>
#include <stdlib.h>

//needed for open
// FT_HANDLE ftHandle;// Handle of the FTDI device
// FT_STATUS ftStatus;// Result of each D2XX call

/*------------------------Populates device information
Notes:
    Call before 
*/
DWORD dev_createInfo(void) {
    // create the device information list
    DWORD numDevs;
    FT_STATUS ftStatus = FT_CreateDeviceInfoList(&numDevs);
    if (ftStatus == FT_OK) {
        printf("Number of devices is %d\n",numDevs);
        return numDevs;
        }
    else {
        printf("FT_CreateDeviceInfoList failed");
        printf("Exiting the program....\n");
        exit(0);
    }
}


/*// create the device information list

Note:

    Please note that Linux, Mac OS X and Windows CE do not support
    location IDs. As such, the Location ID parameter in the structure
    will be empty under these operating systems
    
    ftHandle=Null >>> indicates that a handle has not yet been created or open
*/

FT_DEVICE_LIST_INFO_NODE* dev_getInfo(void) { 
    DWORD numDevs = dev_createInfo();      
    if (numDevs > 0) {
        // allocate storage for list based on numDevs
        FT_DEVICE_LIST_INFO_NODE* devInfo =
            malloc(sizeof(FT_DEVICE_LIST_INFO_NODE)*numDevs);
        // get the device information list
        FT_STATUS ftStatus = FT_GetDeviceInfoList(devInfo,&numDevs); 
        if (ftStatus == FT_OK) {
            for (int i = 0; i < numDevs; i++) {
                printf("Dev %d:\n",i);
                printf("  Flags=0x%x\n",devInfo[i].Flags);
                printf("  Type=0x%x\n",devInfo[i].Type);
                printf("  ID=0x%x\n",devInfo[i].ID);
                printf("  LocId=0x%x\n",devInfo[i].LocId);
                printf("  SerialNumber=%s\n",devInfo[i].SerialNumber);
                printf("  Description=%s\n",devInfo[i].Description);
                printf("  ftHandle=0x%p\n",devInfo[i].ftHandle);
            }
        }
        return devInfo;
    }
    return NULL;
}
//------------------------------------Device Initialization && termination

FT_HANDLE* dev_open(void) {
    FT_HANDLE* ftHandle = malloc(sizeof(FT_HANDLE));// Handle of the FTDI device
    FT_STATUS ftStatus;// Result of each D2XX call

    //----Open by serial number
    ftStatus = FT_OpenEx("FT4J3FQ2", FT_OPEN_BY_SERIAL_NUMBER, ftHandle);
    if (ftStatus == FT_OK) {// Check if Open was successful
        return ftHandle;
    }
    else {
        printf("Can't open FT4J3FQ2 device! \n");
        printf("Exiting the program....\n");
        exit(0);
    }
}


//Not finished
int dev_close(void) {
    //free data
    // free(devInfo);
    // free(ftHandle);
    // FT_Close(ftHandle0);
    // printf("Returning %d\n", retCode);
    // return retCode;
}

//------------------------------------
// int dev_init(void){
    
    // //----Configuring the Device

    // // Reset the FT232H
    // ftStatus |= FT_ResetDevice(ftHandle);
    // // Purge USB receive buffer ... Get the number of bytes in the FT232H receive buffer and then read them
    // ftStatus |= FT_GetQueueStatus(ftHandle, &dwNumInputBuffer);
    // if((ftStatus == FT_OK) && (dwNumInputBuffer > 0)){
    //     FT_Read(ftHandle, &InputBuffer, dwNumInputBuffer, &dwNumBytesRead);  
    // }

    // ftStatus |= FT_SetUSBParameters(ftHandle, 65536, 65535);// Set USB request transfer sizes
    // ftStatus |= FT_SetChars(ftHandle, false, 0, false, 0);// Disable event/error characters
    // ftStatus |= FT_SetTimeouts(ftHandle, 5000, 5000);// Set rd/wrtimeouts to 5 sec
    // ftStatus |= FT_SetLatencyTimer(ftHandle, 16);// Latency timer at default 16ms
    // ftStatus |= FT_SetBitMode(ftHandle, 0x0, 0x00); // Reset mode to setting in EEPROM
    // ftStatus |= FT_SetBitMode(ftHandle, 0x0, 0x02);// Enable MPSSE mode

    // // Inform the user if any errors were encountered
    // if(ftStatus != FT_OK){
    //     printf("failure to initialize FT232H device! \n");
    //     getchar();
    //     return 1;
    // }
// }

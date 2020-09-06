/*
	To build use the following gcc statement 
	(assuming you have the d2xx library in the /usr/local/lib directory).
	gcc -o read main.c -L. -lftd2xx -Wl,-rpath,/usr/local/lib
*/


#include "./bridge.h"





int main(void){
	FT_DEVICE_LIST_INFO_NODE* devinfo = dev_getInfo();
	dev_open();

	dev_close;
	exit: 
		free(devinfo);
}
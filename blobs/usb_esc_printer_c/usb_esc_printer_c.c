#include "usb_esc_printer_c.h"
 
FFI_PLUGIN_EXPORT int sendPrintReq(unsigned char *data, int length, LPTSTR ztPrinterName) {
    DOC_INFO_1 docInfo;
    DWORD bytesWritten;
    HANDLE hPrinter;
    unsigned char* buffer;

    // Dynamically allocate memory for the data
    buffer = (unsigned char*)malloc(length);
    if (buffer == NULL) {
        fprintf(stderr, "Failed to allocate memory for data\n");
        return -1;
    }

    // Copy the data to the newly allocated buffer
    memcpy(buffer, data, length);
    
    // Open a handle to the default printer
    if (!OpenPrinter(ztPrinterName, &hPrinter, NULL)) {
        fprintf(stderr, "Failed to open the default printer\n");
        return -1;
    }     

    // Fill in the details of the print job
    docInfo.pDocName = L"POS MOSYS";
    docInfo.pOutputFile = NULL;
    docInfo.pDatatype = L"RAW"; // Send raw data to the printer

    // Start a new document
    if (StartDocPrinter(hPrinter, 1, (LPBYTE)&docInfo) == 0) {
        fprintf(stderr, "Failed to start document\n");
        ClosePrinter(hPrinter);
        return -1;
    }

    // Start a new page
    if (!StartPagePrinter(hPrinter)) {
        fprintf(stderr, "Failed to start page\n");
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return -1;
    }
 
    if (!WritePrinter(hPrinter, buffer, length, &bytesWritten)) {
        fprintf(stderr, "Failed to write to printer\n");
        EndPagePrinter(hPrinter);
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return -1;
    }
 
    // End the page and document
    EndPagePrinter(hPrinter);
    EndDocPrinter(hPrinter);

    // Close the printer handle
    ClosePrinter(hPrinter);
     // Free the allocated memory
    free(buffer);
    return 0;
}
 

#include <stdio.h>
#include <stdarg.h>
#include <arch/zx/esxdos.h>
#include <string.h>

char ssid[80];
char pass[80];
int i;
int file;

int main(int argc, char **argv)
{
    printf("IWConfig by nihirash v.0.1\nWireless interface configurator\n");
    if (argc < 3) {
        printf(".iwconfig SSID PASSWD\n");
        return 0;
    }
    for (int i=0;i<80;i++) {
        ssid[i] = pass[i] = 0;
    }

    strcpy(ssid, argv[1]);
    strcpy(pass, argv[2]);
    file = esx_f_open("/sys/config/iw.cfg", ESX_MODE_WRITE | ESX_MODE_OPEN_CREAT_TRUNC);
    esx_f_write(file, ssid, 80);
    esx_f_write(file, pass, 80);
    esx_f_close(file);    
    return 0;
}
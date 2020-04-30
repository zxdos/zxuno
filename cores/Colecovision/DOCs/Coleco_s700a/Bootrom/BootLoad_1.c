#include "coleco.h"
#include <stdio.h>
#include <string.h>
#include <intrz80.h>
#include <intz80.h>

#include "getput1.h"

#include "pff.h"

// UP  0x0001; RIGHT 0x0002; DOWN 0x0004 LEFT 0x0008  RFIRE 0x8000 LFIRE 0x4000
#define _UP    0x0001
#define _DOWN  0x0004
#define _LEFT  0x0008
#define _RIGHT 0x0002
#define _LFIRE 0x4000
#define _RFIRE 0x8000

//extern const sound_t snd_table[];

extern void set_color(unsigned char);
extern void load_ascii(void); 
extern void sound_off(void);
extern void set_mode1(void);
extern void fill_vram(unsigned char);
extern void screen_on(void);
extern void print_at(unsigned char, unsigned char, char *);
extern void enable_nmi(void);
extern void disable_nmi(void);
extern void set_snd_table();
extern void vdp_init(void);
extern unsigned int read_joy(unsigned char); 
//extern void disable_nmi(void);
     
//void nmi(void) {}

void die (FRESULT rc)
{
    print_at(12,18,"Error           ");
	for (;;) ;
}

BYTE  buff[270]; // ? T80SOC error reading if buff > ~300?
 char xp[]=">>>";
   
void main(void)
{     
  	FATFS  fatfs;			/* File system object */
	DIR  dir;				/* Directory object */
	FILINFO  fno;			/* File information object */
	WORD  bw, br, i;
	
	BYTE  rc,k,l;
        unsigned char *cp;	
       
        BYTE snum,cpos;
        WORD  w,dly=3000;
        char * sp;
        
        
        BYTE fn[15];
        char cart_name[25];
        char * cartp;
        

        
        vdp_init();  
	set_mode1();
	disable_nmi();
        fill_vram(0x0);
        set_color(0xf4);
	load_ascii();
	screen_on();
	
	
        print_at(6,3,"CART LIST");
        print_at(6,4,"---------");
        
       
        rc = pf_mount(&fatfs);
	if (rc) die(rc);
	
	
	rc = pf_open("MENU.TXT");
	if (rc) die(rc);

	for (;;) {
	  rc = pf_read(buff, sizeof(buff), &br);	/* Read a chunk of file */
	  if (rc || !br) break;			/* Error or end of file */
	  
	  for(l=0;l<10;l++) {
	   put_at(4,l+5,&buff[l*27],16);
	  }
	}
	  cpos=9;snum=4;
	  print_at(1,cpos,xp);
	  
	// UP  0x0001; RIGHT 0002; DOWN 0x0004 LEFT 0x0008
        for(;;){
        w=read_joy(0);
 	      	
	if ((w & _DOWN) && (cpos < 14)) {
	
	   print_at(1,cpos,"   "); cpos++;
	   print_at(1,cpos,xp);snum++;
	   } 
	else if ((w & _UP) && (cpos>5)) {
	
	   print_at(1,cpos,"   "); cpos--;
	   print_at(1,cpos,xp);snum--;
	   } 
	
	if (w & (_RFIRE|_LFIRE)) break;
	for(dly=0;dly<3000;) { dly++;}
	}

        strncpy(fn,&buff[snum*27+17],8);
        fn[8]=0;
        sp=strchr(fn,' ');
        *sp='\0';
        strcat(fn,".rom");
        
        
        /*
	rc=pf_lseek(snum*27+17); 	
	rc = pf_read(fn, 10, &br);
	fn[8]= '.';
	fn[9]= 'r';
	fn[10]='o';
	fn[11]='m';
	fn[12]=0;
	 rc=pf_lseek(0);
	 */
	
	//print_at(4,20,fn);
	
	
	
        print_at(4,18,"Loading");
        print_at(12,18,fn);
        
        strcpy(cart_name,"CART/");       
	cartp=strcat(cart_name,fn);
	rc = pf_open(cartp);
	if (rc) die(rc);
        
        // rc = pf_open("cart/galaxian.rom");
	//if (rc) die(rc);
	
	cp = (unsigned char *)0x8000; //cartram ptr;
	for (;;) {
		rc = pf_read(cp, 32768, &br);	/* Read a chunk of file */
		if (rc || !br) break;		/* Error or end of file */

	}
	if (rc) die(rc);
	
	//print_at(5,15,"Loaded OK");
	
	_opc(0xc3);
	_opc(0x6e);
	_opc(00);
	
}
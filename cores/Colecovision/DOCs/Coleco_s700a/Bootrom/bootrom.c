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
//extern void set_snd_table();
extern void vdp_init(void);
extern unsigned int read_joy(unsigned char); 
//extern void disable_nmi(void);
     
//void nmi(void) {}

void die (FRESULT rc)
{
unsigned int dly;
    print_at(12,18,"Error......Reset");
    for(dly=0;dly<50000;) { dly++;rc=rc;}
    _opc(0xc3);_opc(0);_opc(0);	
}

BYTE  buff[27]; // ? T80SOC error reading if buff > ~300?
 char xp[]="=>";

   
void main(void)
{     
  	FATFS  fatfs;			/* File system object */
	DIR  dir;				/* Directory object */
	FILINFO  fno;			/* File information object */
	WORD  bw, br, i;
	
	BYTE  rc,k,l;
        unsigned char *cp;	
       
        BYTE snum,cpos;
        WORD  w,dly;
        char *sp,*s;
        
        
        BYTE fn[15];
        char cart_name[25];
        char * cartp;
        BYTE page,rcount,select;
        
 //char restart[]={0x3e, 0x04, 
 //                0xd3, 0x24,
 //                0xc3, 0x00, 0x00}; 
                 
    
        
        
// Init UART T16450 (do not init here)

//        output(0x21,0x00);
//        output(0x23,0x80);
//        output(0x20,0x23); // baud 38400
//        output(0x21,0x00);
//        output(0x23,0x03);
//        output(0x24,0x0b);	
       
        vdp_init();  
	set_mode1();
	disable_nmi();
        fill_vram(0x0);
        set_color(0xf4);
	load_ascii();
	screen_on();
	
	 output(0x24,0x0b); // unlock cart_rom
       
        rc = pf_mount(&fatfs);
	if (rc) die(rc);
	
	
	rc = pf_open("MENU.TXT");
	if (rc) die(rc);

        page = 0;
        select = 0;
      
       do {
        cls();
       // print_at(10,1,"CART LIST");
       // print_at(10,2,"---------");
        print_at(3,1,"L-Fire:Load  R-Fire:Restart");
        print_at(3,3,"   U/D:Select   L/R:Page");
        
        print_at(1,20,"<ESC>Reset <U/D>Sel <L/R>Page");
        print_at(1,22,"<Q>* <W># <Z>L-Fire <X>R-Fire");
         
        rcount = 0;  
	for (;;) {
		rc = pf_read(buff, 27, &br);	/* Read a line of file */
		if (rc || !br) break;			/* Error or end of file */
		rcount++;
		
                s = strchr(buff,';');
                *s='\0'; // terminate the cart name		
                print_at(4,rcount+4,buff);  
                
                if (rcount == 10) { break;}            
	}

	  cpos=5; snum=0;
	  
	  print_at(2,cpos,xp);
	  
	// UP  0x0001; RIGHT 0002; DOWN 0x0004 LEFT 0x0008
        for(;;){
       
        //do {
        //      w=read_joy(0);
 	//      for(dly=0;dly<1000;) { dly++;}
 	//      w1=read_joy(0);
 	//    } while (w!=w1);
         
 	  w=read_joy(0);
 	      	
	  if ((w & _DOWN) && (cpos < rcount+4)) {
	
	    print_at(2,cpos,"  "); cpos++;
	    print_at(2,cpos,xp);snum++;
	   } 
	  else if ((w & _UP) && (cpos>5)) {
	    print_at(2,cpos,"  "); cpos--;
	    print_at(2,cpos,xp);snum--;
	    } 
	  else if (w & _LEFT) {
	    if (page > 0) page--; 
	    select=0;
	    rc = pf_lseek(page*270);
	    break;    
	  }
	  
	  else if (w & _RIGHT) {
	    page++; 
	    select=0;
	    rc = pf_lseek(page*270); 
	    break;
	  }
	  
	  if (w & (_RFIRE|_LFIRE)) { 
	    select=1;
	    break;
	  }
	for(dly=0;dly<2800;) { dly++;}
	}
      } while (select==0);
      
        if (w ==_RFIRE)  goto LOAD;
      
        rc = pf_lseek(page*270+snum*27+17);
        rc = pf_read(buff, 13, &br);
        
        sp=strchr(buff,'\r');
        if (sp) *sp='\0';
        sp=strchr(buff,' ');
        if (sp) *sp='\0';
        strcpy(fn,buff);
        strcat(fn,".rom");       
	
        print_at(4,18,"Loading");
        print_at(12,18,fn);
        
        strcpy(cart_name,"Coleco/");       
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

LOAD:
        cp=(unsigned char *)0x7100;
        
        *cp++=0x3e;
         *cp++=0x04;
          *cp++=0xd3;
           *cp++=0x24;
            *cp++=0xc3;
             *cp++=0x00;
              *cp++=0x00;
           _opc(0xc3);
           _opc(0x00);
           _opc(0x71);    

	//output(0x24,0x04);
	// Disable write cart ram using T16450 OUT1_n (inverted logic)
//	_opc(0x3e);  //ld a,4
//	_opc(0x04);  
//	_opc(0xd3);  //out (24h),a
//	_opc(0x24); 
	// init original stack ptr
//	_opc(0x31); 
//	_opc(0xb9);
//	_opc(0x73);
	// jump to bios (cont'd)
//	_opc(0xc3); 
//	_opc(0x6e);
//	_opc(0x00);
	
}
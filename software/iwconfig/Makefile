all: iwconfig 

iwconfig: iwconfig.c
	zcc +zx -vn -startup=30 -clib=new iwconfig.c -SO3 -o iwconfig -subtype=dot -create-app

clean:
	rm *.bin *.def IWCONFIG
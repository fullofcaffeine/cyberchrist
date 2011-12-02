
#ifdef IS_UNIX
#X=YES
#else
#X=NO
#endif

### CYBERCHRIST ###

PROJECT = cyberchrist
HX = haxe -main CyberChrist -cp src -cp ../panda
OUT = bin

all: build

neko: cyberchrist/*.hx
	$(HX) -neko $(OUT)/$(PROJECT).n

neko-exe: neko
	haxelib run xcross $(OUT)/$(PROJECT).n
	
hxcpp: cyberchrist/*.hx
	$(HX) -cpp out --remap neko:cpp
	mv out/App $(OUT)/$(PROJECT)

build: neko

clean:
	rm -f $(OUT)/$(PROJECT).n
	rm -f $(OUT)/$(PROJECT)
	rm -rf out

PHONY: all build clean

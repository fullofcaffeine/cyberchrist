
#ifdef IS_UNIX
#X=YES
#else
#X=NO
#endif

### CYBERCHRIST ###

PROJECT = cyberchrist
HX = haxe -main CyberChrist -cp src -cp ../panda
SRC = src/*.hx src/cyberchrist/*.hx
OUT = ./

all: build

app: $(SRC)
	haxe -js test/src/js/cyberchrist.js cyberchrist.App \
		-cp src -cp ../hx.html5 -cp ../google \
		-D noEmbedJS \
		#-D CYBERCHRIST_DEBUG

neko: $(SRC)
	$(HX) -neko $(OUT)/$(PROJECT).n

#neko-exe: neko
#	haxelib run xcross $(OUT)/$(PROJECT).n
	
cpp: $(SRC)
	$(HX) -cpp out --remap neko:cpp
	mv out/CyberChrist ./$(PROJECT)

build: app neko

test: build
	(cd test;neko ./../cyberchrist.n)

clean:
	rm -f $(OUT)/$(PROJECT).n
	rm -f $(OUT)/$(PROJECT)
	rm -rf out

PHONY: all build clean

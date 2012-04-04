
### CYBERCHRIST BLOG ENGINE ###

PROJECT = cyberchrist
HX = haxe -main CyberChrist -cp src -cp ../panda \
	-cp /home/t0ng/data/projects/hxmpp
SRC = src/*.hx src/cyberchrist/*.hx
OUT = ./

all: build

neko: $(SRC)
	$(HX) -neko $(OUT)/$(PROJECT).n

#cpp: $(SRC)
	#$(HX) -cpp out --remap neko:cpp
	#mv out/CyberChrist ./$(PROJECT)

build: neko

test: build
	(cd test;neko ./../cyberchrist.n)

clean:
	rm -f $(OUT)/$(PROJECT).n
	rm -f $(OUT)/$(PROJECT)
	rm -rf out

PHONY: all build clean

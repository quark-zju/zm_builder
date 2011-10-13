.PHONY: all clean cleanall

all: output.pdf

clean:
	-rm -rf build/

cleanall: clean
	-rm output.pdf

output.pdf: build/output.pdf
	cp $^ $@

build/output.pdf: ../zm_builder.rb src
	PAGE_FOOTER='Sample' ../zm_builder.rb ./src/

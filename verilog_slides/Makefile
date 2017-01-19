
.PHONY: all
all: Verilog_Primer_Slides.pdf

%.pdf: %.tex
	pdflatex -shell-escape $^

.PHONY: clean
clean:
	rm -f *.aux *.log *.nav *.out *.pdf *.snm *.toc

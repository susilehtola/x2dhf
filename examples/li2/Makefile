
PROG = x2dhf
XHF = ../../tests/xhf 

all: li2
	$(MAKE) clean

li2: li2.data
	test  -L $(PROG)  || ln -s ../../src/$(PROG) .
	test -f $@.lst || ( cp $@.pun gaussian.pun; cp $@.out gaussian.out; $(XHF) $@ $@-1 | tee $@.lst )

clean:
	rm -f *.dat *.orb *.coul *.exch stop_x2dhf $(PROG) gaussian.* 2> /dev/null

stop:
	$(XHF) stop

#


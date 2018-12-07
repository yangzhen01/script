all: help
#all: addin delin


.PHONY clean:
clean:
	-@sudo rm -rf $(PWD)/vm_overall.txt

.PHONY run:
run:
	-@sudo $(PWD)/test

.PHONY help:
help:
	-@echo " "
	-@echo " "
	-@echo "[*] make run "
	-@echo "		   - Run script & generate vm_overall.txt"
	-@echo "[*] make clean "
	-@echo "		   - Clear previous vm_overall.txt "
	-@echo " "


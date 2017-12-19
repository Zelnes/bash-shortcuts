# This utility comes from this site :
# http://www.humbug.in/2010/utility-to-send-commands-or-data-to-other-terminals-ttypts/

target=ttyecho

all:
	@make $(target)
	@echo "$(target) compiled !"

# Must be run with sudo privilege
install: all
	@sudo chown root:root $(target)
	@sudo chmod u+s $(target)
	@sudo rm -f /usr/bin/$(target)
	@sudo ln -s `realpath $(target)` /usr/bin/$(target)
	@echo "$(target) installed !"
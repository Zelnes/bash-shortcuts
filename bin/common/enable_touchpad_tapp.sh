#!/bin/bash

id=$(xinput list | awk -F'[=[:blank:]]+' '/Synaptics/{print $6}')
prop=$(xinput list-props ${id} | sed -n -r 's/.*Tapping Enabled \(([0-9]+).*/\1/p')
xinput set-prop ${id} ${prop} 1

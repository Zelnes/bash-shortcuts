#!/bin/bash

id=$(xinput list | sed -n -r 's/.*TouchPad.*id=([0-9]+).*/\1/p')
prop=$(xinput list-props ${id} | sed -n -r 's/.*Tapping Enabled \(([0-9]+).*/\1/p')
xinput set-prop ${id} ${prop} 1

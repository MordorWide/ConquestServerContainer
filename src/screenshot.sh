#!/usr/bin/env bash
DISPLAY=:0 sudo xwd -root -display :0 | convert xwd:- png:-
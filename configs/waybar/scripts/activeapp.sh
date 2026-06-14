#!/bin/bash

hyprctl activewindow -j | jq -r '.class + "    " + .title'

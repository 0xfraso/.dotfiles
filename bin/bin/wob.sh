#!/bin/env bash

WOBSOCK=$XDG_RUNTIME_DIR/wob.sock

rm -f $WOBSOCK && mkfifo $WOBSOCK && tail -f $WOBSOCK | wob

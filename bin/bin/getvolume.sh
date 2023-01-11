#!/bin/bash

VOLUME=$(pulsemixer --get-volume | cut -d ' ' -f1)

echo $VOLUME

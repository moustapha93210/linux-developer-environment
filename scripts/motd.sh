#!/bin/bash

echo "===========================
      METEO DU JOUR
===========================" > /etc/motd

echo

bash /home/modo/weather.sh >> /etc/motd

echo

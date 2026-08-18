#! /bin/bash

# Variables
API_KEY="${OPENWEATHER_API_KEY}"
CITY="Paris"
DATE=$(date +"%Y-%m-%d")


echo "Météo du $DATE"

echo

#Récupérer la météo
curl -s "https://api.openweathermap.org/data/2.5/weather?q=${CITY}&appid=${API_KEY}&units=metric" | jq -r '"Ville : \(.name)
Temperature : \(.main.temp)°C 
Humidite : \(.main.humidity)% 
Conditions : \(.weather[0].description)"'

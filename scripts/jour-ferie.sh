#! /bin/bash

API_URL="https://calendrier.api.gouv.fr/jours-feries/metropole.json"

# --- Date du jour ---
today=$(date +"%Y-%m-%d")
#today=2025-12-25
current_year=$(date +"%Y")
#current_year=2036

# --- Détection des dates anormales ---
year_minus_20=$(( $(date +"%Y") - 20 ))
year_plus_5=$(( $(date +"%Y") + 5 ))

if [ "$current_year" -lt "$year_minus_20" ] || [ "$current_year" -gt "$year_plus_5" ]; then
    echo "impossible de récupérer les jours inférieurs à 20ans ou supérieurs à 5ans"
    exit 1
fi

# --- Récupération des données de l'API ---
json=$(curl -s -f "$API_URL")
if [ $? -ne 0 ] || [ -z "$json" ]; then
    echo "Erreur : impossible de récupérer les données des jours fériés."
    exit 1
fi

# --- Extraction des jours après aujourd’hui ---
next_holiday=$(
    echo "$json" \
    | jq --arg today "$today" '
        to_entries
        | map(select(.key > $today))
        | sort_by(.key)
        | .[0]
    '
)

# Si aucun jour après aujourd’hui
if [ "$next_holiday" == "null" ] || [ -z "$next_holiday" ]; then
    next_year=$((current_year + 1))

    next_holiday=$(
        echo "$json" \
        | jq --arg year "$next_year" '
            to_entries
            | map(select(.key | startswith($year + "-")))
            | sort_by(.key)
            | .[0]
        '
    )
fi

# Vérification finale
if [ "$next_holiday" == "null" ] || [ -z "$next_holiday" ]; then    echo "Erreur : impossible de déterminer le prochain jour férié."
    exit 1
fi

# --- Affichage final ---
date_ferie=$(echo "$next_holiday" | jq -r '.key')
nom_ferie=$(echo "$next_holiday" | jq -r '.value')

echo "Prochain jour férié : $nom_ferie ($date_ferie)"

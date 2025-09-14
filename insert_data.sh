#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Truncate tables before inserting
$PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY;"

# Read CSV file, skip header
while IFS=',' read -r year round winner opponent winner_goals opponent_goals
do
  # Skip empty lines
  if [[ -z $year ]]; then
    continue
  fi

  # Escape single quotes for SQL
  winner_esc=$(echo "$winner" | sed "s/'/''/g")
  opponent_esc=$(echo "$opponent" | sed "s/'/''/g")
  round_esc=$(echo "$round" | sed "s/'/''/g")

  # Insert teams if they don't exist
  $PSQL "INSERT INTO teams(name) VALUES('$winner_esc') ON CONFLICT(name) DO NOTHING;"
  $PSQL "INSERT INTO teams(name) VALUES('$opponent_esc') ON CONFLICT(name) DO NOTHING;"

  # Get team IDs
  WIN_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$winner_esc';")
  OPP_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$opponent_esc';")

  # Insert game data
  $PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
         VALUES($year, '$round_esc', $WIN_ID, $OPP_ID, $winner_goals, $opponent_goals);"

done < <(tail -n +2 games.csv)

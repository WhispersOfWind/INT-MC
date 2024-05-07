#!/bin/bash
# This script reads the counter value from all switches and ports and saves it to a file
# Usage: ./read_counter.sh

counter_name=egressPortCounter # The name of the counter
file_name=results/counter_output.txt # The name of the file
CLI_PATH=/usr/local/bin/simple_switch_CLI # The path of simple_switch_CLI command

while true; do # Loop forever
  date=$(date "+%s") # Get the current date and time in seconds since 1970-01-01 00:00:00 UTC
  line="$date :" # Start a new line with the date
  for port in $(seq 9090 9113); do # Loop for every switch port
    for index in 1 2 3 4 5 6 7 8; do # Loop for every port
      #value=$(echo counter_read $counter_name $index | $CLI_PATH --thrift-port $port | grep $counter_name | tr '=' ' ' | tr ')' ' ' | awk '{print $4}') # Get the counter packets value
      value=$(echo counter_read $counter_name $index | $CLI_PATH --thrift-port $port | grep $counter_name | tr '=' ' ' | tr ')' ',' | awk '{print $6}') # Get the counter bytes value

#when awk'{print $6}' , this program will read counter'bytes	

      if [[ $value == Invalid* ]]; then # If the value is an error message
        value=0 # Replace it with 0
      fi
      line="$line $value" # Append the value to the line
    done
  done
 # echo $line # Print the line to the screen
  echo $line >> $file_name # Append the line to the file
  sleep 30 # Wait for 5 seconds
done


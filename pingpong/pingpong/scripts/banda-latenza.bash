#!/bin/bash

set -e

if [[ $# != 2 ]] ; then printf "Error during the declaretion of TCP and UDP\n"; exit 1; fi

declare -a protocols=("tcp" "udp");

for indexProtocol in "${protocols[@]}"
do
    declare t1=$(head -n 1 ../data/"${indexProtocol}"_throughput.dat | cut -d ' ' -f3)
    declare t2=$(tail -n 1 ../data/"${indexProtocol}"_throughput.dat | cut -d ' ' -f3)
    declare Message_size_min=$(head -n 1 ../data/"${indexProtocol}"_throughput.dat | cut -d ' ' -f1)
    declare Message_size_max=$(tail -n 1 ../data/"${indexProtocol}"_throughput.dat | cut -d ' ' -f1)

    echo "${indexProtocol}"

    echo Message_size_max / Message_size_min: "$Message_size_max" "$Message_size_min"
    echo t1 / t2: "$t1" "$t2"


declare exponent

	if [[ $Message_size_min == *"e+"* ]]; then
		exponent=$(echo $Message_size_min | cut -d '+' -f2)	
		Message_size_min=$(echo $Message_size_min | cut -d 'e' -f1)
		Message_size_min=$(echo "$Message_size_min*(10^$exponent)" | bc)
	fi

	if [[ $Message_size_max == *"e+"* ]]; then
		exponent=$(echo $Message_size_max | cut -d '+' -f2)	
		Message_size_max=$(echo $T| cut -d 'e' -f1)
		Message_size_max=$(echo "$Message_size_max*(10^$exponent)" | bc)
	fi

	if [[ $t1 == *"e+"* ]]; then
		exponent=$(echo $t1 | cut -d '+' -f2)	
		t1=$(echo $t1 | cut -d 'e' -f1)
		t1=$(echo "$t1*(10^$exponent)" | bc)
	fi

	if [[ $t2 == *"e+"* ]]; then
		exponent=$(echo $t2 | cut -d '+' -f2)	
		t2=$(echo $t2 | cut -d 'e' -f1)
		t2=$(echo "$t2*(10^$exponent)" | bc)
	fi


    declare min_delay=$(echo "scale=10; $Message_size_min/$t1" | bc)
    declare max_delay=$(echo "scale=10; $Message_size_max/$t2" | bc)

    echo delay min / delay max: "$min_delay" "$max_delay"

    declare latency=$(echo "scale=10; ((($min_delay*$Message_size_max)-($max_delay*$Message_size_min))/($Message_size_max-$Message_size_min))"| bc)
    declare bandwidth=$(echo "scale=5; (($Message_size_max-$Message_size_min)/($max_delay-$min_delay))"| bc)
    
    gnuplot <<-eNDgNUPLOTcOMMAND
        set term png size 700, 500 
        set output "../data/${indexProtocol}_banda_latenza.png"
        set logscale y 10
        set logscale x 2
        set xlabel "msg size (B)"
        set ylabel "throughput (KB/s)"
        lbf(x) = x / ($latency + x / $bandwidth)
        plot "../data/${indexProtocol}_throughput.dat" using 1:3 title "${indexProtocol} ping-pong Throughput" \
            with linespoints, \
        lbf(x) title "Latency-Bandwidth model with L=${latency} and B=${bandwidth}" \
            with linespoints
        clear
eNDgNUPLOTcOMMAND

done

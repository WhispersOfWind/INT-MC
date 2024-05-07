mx h10 iperf -s -p 55560 -u  &

mx h6 iperf -s -p 55556 -u &

mx h4 iperf -s -p 55554 -u &

mx h2 iperf -c 10.0.14.10 -u -b 5M -t 1000 -p 55560 &

mx h9 iperf -c 10.0.8.6 -u -b 5M -t 1000 -p 55556 &

mx h8 iperf -c 10.0.4.4   -u -b 5M -t 1000 -p 55554 

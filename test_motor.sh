#!/bin/bash
echo "0.0" | nc 127.0.0.1 5555
sleep 1
echo "0.1" | nc 127.0.0.1 5555
sleep 2
echo "0.0" | nc 127.0.0.1 5555

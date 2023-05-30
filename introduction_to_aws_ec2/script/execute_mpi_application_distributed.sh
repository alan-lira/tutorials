#!/bin/bash

# MIT License

# Copyright (c) 2023 Alan Lira

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Begin
number_of_provided_arguments=$#

required_arguments_array=("Master's Config File (Path)" "Workers' Config File (Path)" "MPI Application Source File (Path)" "Number of MPI Processes to Use (Integer)")
number_of_required_arguments=${#required_arguments_array[@]}

optional_arguments_array=()
number_of_optional_arguments=${#optional_arguments_array[@]}

if [ $number_of_provided_arguments -lt $number_of_required_arguments ]; then
    if [ $number_of_required_arguments -gt 0 ]; then
        echo -e "Required Arguments ($number_of_required_arguments):"
        for i in $(seq 0 $(($number_of_required_arguments-1))); do
            echo "$(($i+1))) ${required_arguments_array[$i]}"
        done
    fi
    if [ $number_of_optional_arguments -gt 0 ]; then
        echo -e "\nOptional Arguments ($number_of_optional_arguments):"
        for i in $(seq 0 $(($number_of_optional_arguments-1))); do
            echo "$(($i+$number_of_required_arguments+1))) ${optional_arguments_array[$i]}"
        done
    fi
    sleep 5
    exit 1
fi

master_settings_file=${1}
workers_settings_file=${2}
mpi_application_path=${3}
mpi_num_processes=${4}

# Load the Master's info (Private Key, Username, and Public IPv4).
readarray -t master_array < $master_settings_file
read -ra master_info_array <<< "$master_array"
master_key=${master_info_array[0]}
master_username=${master_info_array[1]}
master_ip=${master_info_array[2]}

# Load the Workers' info (Private Key, Username, and Public IPv4).
readarray -t workers_array < $workers_settings_file

echo "[Step 7]"
sleep 2

# Step 7 (Locally Executed):
# - Copy the MPI application file.

# for Master...
ssh -i $master_key $master_username@$master_ip "mkdir -p application"
scp -i $master_key -r $mpi_application_path $master_username@$master_ip:~/$mpi_application_path

# for Workers...
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_key=${worker_info_array[0]}
    worker_username=${worker_info_array[1]}
    worker_ip=${worker_info_array[2]}
    ssh -i $worker_key $worker_username@$worker_ip "mkdir -p application"
    scp -i $worker_key -r $mpi_application_path $worker_username@$worker_ip:~/$mpi_application_path
done

echo "[Step 8]"
sleep 2

# Step 8 (Remotely Executed on All Nodes):
# - Compile the MPI application file.

mpi_application_filename=$(basename -- "$mpi_application_path")
extension="${filename##*.}"
compiled_mpi_application_filename="application/${mpi_application_filename%.*}"

# on Master...
ssh -i $master_key $master_username@$master_ip "mpicc $mpi_application_path -o $compiled_mpi_application_filename"

# on Workers...
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_key=${worker_info_array[0]}
    worker_username=${worker_info_array[1]}
    worker_ip=${worker_info_array[2]}
    ssh -i $worker_key $worker_username@$worker_ip "mpicc $mpi_application_path -o $compiled_mpi_application_filename"
done

echo "[Step 9]"
sleep 2

# Step 9 (Remotely Executed on Master Node):
# - Launch the MPI application.

echo "Launching the MPI application '$mpi_application_filename'..."
sleep 3

# on Master...
ssh -i $master_key $master_username@$master_ip "mpiexec -np $mpi_num_processes -hostfile hostfile ./$compiled_mpi_application_filename"

exit


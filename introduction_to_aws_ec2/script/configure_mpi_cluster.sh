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

required_arguments_array=("Master's Config File (Path)" "Workers' Config File (Path)")
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

# Load the Master's info (Private Key, Username, and Public IPv4).
readarray -t master_array < $master_settings_file
read -ra master_info_array <<< "$master_array"
master_key=${master_info_array[0]}
master_username=${master_info_array[1]}
master_ip=${master_info_array[2]}

# Load the Workers' info (Private Key, Username, and Public IPv4).
readarray -t workers_array < $workers_settings_file

echo "Configuring the MPI cluster..."
sleep 3

# Step 0.1 (Locally Executed)
# - Store the remote host's public key into the 'know_hosts' file.

# for Master...
ssh-keyscan -H $master_ip >> ~/.ssh/known_hosts

# for Workers...
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_ip=${worker_info_array[2]}
    ssh-keyscan -H $worker_ip >> ~/.ssh/known_hosts
done

# Step 0.2 (Locally Executed)
# - Change the remote host's AWS private key permissions for read-only.

# for Master...
chmod 400 $master_key

# for Workers...
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_key=${worker_info_array[0]}
    chmod 400 $worker_key
done

echo "[Step 1]"
sleep 2

# Step 1 (Remotely Executed on All Nodes):
# - Include the 'private-key' file content to the 'id_rsa' file (.ssh/id_rsa).
# - Change 'id_rsa' octal permissions to 600, i.e., only changeable by the user.

# on Master...
ssh -i $master_key $master_username@$master_ip "echo '$(cat $master_key)' > .ssh/id_rsa; chmod 600 .ssh/id_rsa"

# on Workers...
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_key=${worker_info_array[0]}
    worker_username=${worker_info_array[1]}
    worker_ip=${worker_info_array[2]}
    ssh -i $worker_key $worker_username@$worker_ip "echo '$(cat $worker_key)' > .ssh/id_rsa; chmod 600 .ssh/id_rsa"
done

echo "[Step 2]"
sleep 2

# Step 2 (Remotely Executed on All Nodes):
# - Update the 'available packages' list.
# - Install 'OpenSSH'.
# - Install 'OpenMPI'.

# on Master...
ssh -i $master_key $master_username@$master_ip "sudo apt-get update && sudo apt-get install openssh-server openssh-client && sudo apt-get install libopenmpi-dev -y && mpiexec --version"

# on Workers...
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_key=${worker_info_array[0]}
    worker_username=${worker_info_array[1]}
    worker_ip=${worker_info_array[2]}
    ssh -i $worker_key $worker_username@$worker_ip "sudo apt-get update && sudo apt-get install openssh-server openssh-client && sudo apt-get install libopenmpi-dev -y && mpiexec --version"
done

echo "[Step 3]"
sleep 2

# Step 3 (Remotely Executed on Master Node):
# - Generate Master's Public/Private RSA key pair.

# on Master...
ssh -i $master_key $master_username@$master_ip "sudo ssh-keygen -q -t rsa -N '' -f .ssh/id_rsa <<<y 2>&1>/dev/null"

echo "[Step 4]"
sleep 2

# Step 4 (Remotely Executed on All Nodes):
# - Include Master's Public RSA key into all nodes' 'authorized_keys' file (.ssh/authorized_keys).

# on Master...
ssh -i $master_key $master_username@$master_ip "echo $(ssh -i $master_key $master_username@$master_ip "cat .ssh/id_rsa.pub") | sudo tee -a .ssh/authorized_keys"

# on Workers...
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_key=${worker_info_array[0]}
    worker_username=${worker_info_array[1]}
    worker_ip=${worker_info_array[2]}
    ssh -i $worker_key $worker_username@$worker_ip "echo $(ssh -i $master_key $master_username@$master_ip "cat .ssh/id_rsa.pub") | sudo tee -a .ssh/authorized_keys"
done

echo "[Step 5]"
sleep 2

# Step 5 (Remotely Executed on Master Node):
# - Include all Workers' Public SSH Key into Master's 'known_hosts' file (.ssh/known_hosts).

# on Master...
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_key=${worker_info_array[0]}
    worker_username=${worker_info_array[1]}
    worker_ip=${worker_info_array[2]}
    ssh -i $master_key $master_username@$master_ip "echo '$(ssh -i $worker_key $worker_username@$worker_ip "ssh-keyscan -H $worker_ip | grep -o '^[^#]*'")' | sudo tee -a .ssh/known_hosts"
done

echo "[Step 6]"
sleep 2

# Step 6 (Remotely Executed on Master Node):
# - Generate the 'hostfile' file, including all workers IPv4 addresses and number of MPI processes per IP.

# on Master...
ssh -i $master_key $master_username@$master_ip "touch hostfile"
for worker in "${workers_array[@]}"; do
    read -ra worker_info_array <<< "$worker"
    worker_key=${worker_info_array[0]}
    worker_username=${worker_info_array[1]}
    worker_ip=${worker_info_array[2]}
    worker_num_cpu_cores=$(ssh -i $worker_key $worker_username@$worker_ip "grep 'cpu cores' /proc/cpuinfo | awk '{print \$4;}' | uniq")
    ssh -i $master_key $master_username@$master_ip "echo '$worker_ip slots=$worker_num_cpu_cores' | sudo tee -a hostfile"
done

exit


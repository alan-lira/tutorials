# Introduction to AWS EC2

This tutorial provides essential knowledge for starter users of Amazon Web Services (AWS), particularly for the Elastic Compute Cloud (EC2) service. Upon completing this tutorial, you will be able to:
- Understand the concepts of Key Pairs and Security Groups;
- Understand the EC2 instances life cycle;
- Understand the differences between reboot, stop, hibernate, and terminate actions;
- Understand the spot instance interruptions;
- Configure an MPI cluster using EC2 instances;
- Execute MPI and OpenMP applications on the previously configured cluster.
## Presentation

Please refer to the 'presentation/introduction_to_aws_ec2.pdf' file to learn the basic aspects of AWS EC2 and to follow the step-by-step guide to manually configure an MPI cluster and execute MPI and OpenMP applications on EC2.

## Automated Step-by-Step

Consider using the scripts in the 'script' folder to reproduce the steps presented in the presentation with less effort. The usage is as follows (make sure you covered all the assumptions in the presentation):

#### Configure the cluster [steps 1 to 6]:

```bash
  bash script/configure_mpi_cluster.sh \
  config/master config/workers
```
The expected arguments are:

    1. Master's config file (Path)
    2. Workers' config file (Path)

Note: replace, accordingly to your environment, the 'key_name', 'username', and 'public_ipv4' fields in the 'master' and 'workers' config files before launching the above script.

#### Executing an MPI Application (Distributed) [steps 7 to 9]:

```bash
  bash script/execute_mpi_application_distributed.sh \
  config/master config/workers application/hello_mpi.c 2
```
The expected arguments are:

    1. Master's config file (Path)
    2. Workers' config file (Path)
    3. MPI application source file (Path)
    4. Number of MPI processes to use (Integer)

#### Executing an OpenMP Application (Locally on Master) [steps 10 to 12]:

```bash
  bash script/execute_openmp_application_locally_on_master.sh \
  config/master application/hello_openmp.c 5
```
The expected arguments are:

    1. Master's config file (Path)
    2. OpenMP application source file (Path)
    3. Number of OpenMP threads to use (Integer)

#### Executing an MPI + OpenMP Application (Distributed) [steps 13 to 15]:

```bash
  bash script/execute_mpi_openmp_application_distributed.sh \
  config/master config/workers application/hello_mpi_openmp.c 2 5
```
The expected arguments are:

    1. Master's config file (Path)
    2. Workers' config file (Path)
    3. MPI + OpenMP application source file (Path)
    4. Number of MPI processes to use (Integer)
    5. Number of OpenMP threads to use (Integer)

## Final Step

Make sure you terminated all the allocated resources!

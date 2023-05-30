#include <mpi.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    int iam = 0, np = 1;

    // Initialize the MPI environment.
    MPI_Init(NULL, NULL);

    // Get the number of processes.
    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    // Get the rank of the process.
    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    // Get the name of the processor.
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);

    // Begin the parallel region.
    #pragma omp parallel default(shared) private(iam, np)
    {
        // Print off a hello world message.
        np = omp_get_num_threads();
        iam = omp_get_thread_num();
        printf("Hello world from thread %d out of %d from process %d out of %d on %s\n",
               iam, np, world_rank, world_size, processor_name);
    }

    // Finalize the MPI environment.
    MPI_Finalize();

    // Exit.
    exit(0);
}

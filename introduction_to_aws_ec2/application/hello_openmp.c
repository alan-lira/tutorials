#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    // Begin the parallel region.
    #pragma omp parallel
    {
        // Print off a hello world message.
        printf("Hello world from thread %d\n", omp_get_thread_num());
    }

    // Exit.
    exit(0);
}

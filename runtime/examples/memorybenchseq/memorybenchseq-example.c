#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <tapasco.h>
#include <unistd.h>

#define SZ 256
#define RUNS 25
#define KID 1000

typedef struct config {
    unsigned nybble:4;
} config;


static tapasco_ctx_t *ctx;
static tapasco_devctx_t *dev;

static void check(int const result) {
  if (!result) {
    fprintf(stderr, "fatal error: %s\n", strerror(errno));
    tapasco_destroy_device(ctx, dev);
    tapasco_deinit(ctx);
    exit(errno);
  }
}

static void check_tapasco(tapasco_res_t const result) {
  if (result != TAPASCO_SUCCESS) {
    fprintf(stderr, "fpga fatal error: %s\n", tapasco_strerror(result));
    tapasco_destroy_device(ctx, dev);
    tapasco_deinit(ctx);
    exit(result);
  }
}


int main(int argc, char **argv) {
  int errs = 0;

  // initialize threadpool
  check_tapasco(tapasco_init(&ctx));
  check_tapasco(tapasco_create_device(ctx, 0, &dev, 0));
  
  // check arraysum instance count
  printf("instance count: %zd\n", tapasco_device_kernel_pe_count(dev, KID));
  assert(tapasco_device_kernel_pe_count(dev, KID));

  // init whole array to subsequent numbers
  int *arr = (int *)malloc(SZ * RUNS * sizeof(int));
  check(arr != NULL);
  init_array(arr, SZ * RUNS);

  for (int run = 0; run < RUNS; ++run) {
    int const golden = arraysum(&arr[run * SZ]);
    printf("Golden output for run %d: %d\n", run, golden);
    // allocate mem on device and copy array part
    tapasco_handle_t h;
    check_tapasco(tapasco_device_alloc(dev, &h, SZ * sizeof(int),
                                       TAPASCO_DEVICE_ALLOC_FLAGS_NONE));
    printf("h = 0x%08lx\n", (unsigned long)h);
    check_tapasco(tapasco_device_copy_to(dev, &arr[SZ * run], h,
                                         SZ * sizeof(int),
                                         TAPASCO_DEVICE_COPY_BLOCKING));

    // get a job id and set argument to handle
    tapasco_job_id_t j_id;
    tapasco_device_acquire_job_id(dev, &j_id, KID,
                                  TAPASCO_DEVICE_ACQUIRE_JOB_ID_BLOCKING);
    check(j_id > 0);
    check_tapasco(tapasco_device_job_set_arg(dev, j_id, 0, sizeof(h), &h));

    // shoot me to the moon!
    check_tapasco(tapasco_device_job_launch(
        dev, j_id, TAPASCO_DEVICE_JOB_LAUNCH_BLOCKING));

    // get the result
    int32_t r = 0;
    check_tapasco(tapasco_device_job_get_return(dev, j_id, sizeof(r), &r));
    printf("FPGA output for run %d: %d\n", run, r);
    printf("\nRUN %d %s\n", run, r == golden ? "OK" : "NOT OK");
    tapasco_device_free(dev, h, SZ * sizeof(int),
                        TAPASCO_DEVICE_ALLOC_FLAGS_NONE);
    tapasco_device_release_job_id(dev, j_id);
  }

  if (!errs)
    printf("SUCCESS\n");
  else
    fprintf(stderr, "FAILURE\n");

  tapasco_destroy_device(ctx, dev);
  tapasco_deinit(ctx);
  free(arr);
  return errs;
}

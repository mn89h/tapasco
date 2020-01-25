
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <tapasco.h>
#include <unistd.h>
#include <pthread.h>

#define SZ 256
#define RUNS 10

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

static void init_array(int *arr, size_t sz) {
  for (size_t i = 0; i < sz; ++i)
    arr[i] = i;
}

static int arraysum(int *arr) {
  int sum = 0;
  for (size_t i = 0; i < SZ; i++) {
    sum += arr[i];
  }
  return sum;
}

void *exec_as(void *id) {
  int *c;
  c = (int*)id;
  if(c)
    printf("Starting thread number: %d\n", *c);

  int errs = 0;
          
  // init whole array to subsequent numbers
  int *arr = (int *)malloc(SZ * RUNS * sizeof(int));
  check(arr != NULL);
  init_array(arr, SZ * RUNS);

  for (int run = 0; run < RUNS; ++run) {
    int const golden = arraysum(&arr[run * SZ]);
    printf("T%d: Golden output for run %d: %d\n", *c, run, golden);
    // allocate mem on device and copy array part
    tapasco_handle_t h;
    check_tapasco(tapasco_device_alloc(dev, &h, SZ * sizeof(int),
                                       TAPASCO_DEVICE_ALLOC_FLAGS_NONE));
    printf("T%d: h = 0x%08lx\n", *c, (unsigned long)h);
    check_tapasco(tapasco_device_copy_to(dev, &arr[SZ * run], h,
                                         SZ * sizeof(int),
                                         TAPASCO_DEVICE_COPY_BLOCKING));

    // get a job id and set argument to handle
    tapasco_job_id_t j_id;
    tapasco_device_acquire_job_id(dev, &j_id, 10,
                                  TAPASCO_DEVICE_ACQUIRE_JOB_ID_BLOCKING);
    check(j_id > 0);
    check_tapasco(tapasco_device_job_set_arg(dev, j_id, 0, sizeof(h), &h));

    // shoot me to the moon!
    check_tapasco(tapasco_device_job_launch(
        dev, j_id, TAPASCO_DEVICE_JOB_LAUNCH_BLOCKING));

    // get the result
    int32_t r = 0;
    check_tapasco(tapasco_device_job_get_return(dev, j_id, sizeof(r), &r));
    printf("T%d: FPGA output for run %d: %d\n", *c, run, r);
    printf("\nT%d: RUN %d %s\n", *c, run, r == golden ? "OK" : "NOT OK");
    tapasco_device_free(dev, h, SZ * sizeof(int),
                        TAPASCO_DEVICE_ALLOC_FLAGS_NONE);
    tapasco_device_release_job_id(dev, j_id);
  }

  if (!errs)
    printf("SUCCESS\n");
  else
    fprintf(stderr, "FAILURE\n");

  free(arr);

  /* the function must return something - NULL will do */
  return NULL;

}

int main(int argc, char **argv) {
  int errs = 0;
  int i = 0;
  int *index = NULL;

  // initialize threadpool
  check_tapasco(tapasco_init(&ctx));
  check_tapasco(tapasco_create_device(ctx, 0, &dev, 0));

  // check arraysum instance count
  size_t pecount = tapasco_device_kernel_pe_count(dev, 10);
  printf("instance count: %zd\n", pecount);
  assert(pecount);

  // allocate threads
  index = calloc (pecount, sizeof (int));
  for(i = 0; i < pecount; i++) {
    index[i] = i;
  }
  pthread_t *ptr;

  ptr = malloc(sizeof(pthread_t)*pecount);

  // initialize threads
  for(i = 0; i < pecount; i++) {
    if(pthread_create(&ptr[i], NULL, exec_as, (void*)&index[i])) {
      fprintf(stderr, "Error creating thread\n");
      return 1;
    }
  }
  for(i = 0; i < pecount; i++)
    pthread_join(ptr[i], NULL);

  tapasco_destroy_device(ctx, dev);
  tapasco_deinit(ctx);
  return errs;
}

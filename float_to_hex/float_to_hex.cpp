
#include <cstdint>
#include <cstdio>
#include <cstdlib>


union {
  float     f;
  int32_t   i;
  uint32_t  u;
} convert32;

union {
  double    f;
  int64_t   i;
  uint64_t  u;
} convert64;



int multiply_signed_32(int a, int b) {
  convert64.u = (uint64_t)a;
  convert64.u *= 4266746795;
  convert32.u = convert64.u >> 32;
  return convert32.i;
}


void test_multiply(int a, int b) {
  int actual = multiply_signed_32(a,b);
  int expected = a * b;
  if (actual!=expected) {
    printf("%d x %d:  expected=%d, actual=%d\n",a,b,expected,actual);
    exit(1);
  }
};

void loop_test() {
  for (int i = 0; i < 100; i++) {
    test_multiply(rand(), -28220501);
    test_multiply(-rand(), -28220501);
  }
}



int main(void) {


  convert32.f = (float) 0.5;
  printf("(float)0.5 in hex: %#010x\n",convert32.i);


  convert64.i = 0x3FE45F3060000000;
  convert32.f = (float) convert64.f;
  printf("(float)%f, in hex:  %#010x\n",(float)convert64.f, convert32.i);
  

  loop_test();

  return 0;
}

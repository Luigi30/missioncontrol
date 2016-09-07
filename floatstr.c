#include <tos.h>
#include <stdio.h>
#include <math.h>

void hexfloat2str(char *buf, unsigned char *fchr){
	float f;
	memcpy(&f, fchr, sizeof(float));
    sprintf(buf, "%.2f", f);
}

int main(){
	drop_to_asm();
}

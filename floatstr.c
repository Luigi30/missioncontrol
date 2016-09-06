#include <tos.h>
#include <stdio.h>
#include <math.h>

void hexfloat2str(char *buf, unsigned char *fchr){
	unsigned char fstr[16];
	unsigned int num;
	float f;

	sprintf(fstr, "%x%x%x%x", fchr[0], fchr[1], fchr[2], fchr[3]);
        sscanf(fstr, "%x", &num);
        f = *((float*)&num);

        sprintf(buf, "%.2f", f);
}

int main(){
	drop_to_asm();
}

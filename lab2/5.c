#include <stdio.h>

int main() {
    unsigned long n = 3363522457;
    int sum = 0;
    while(n > 0) {
        sum += n % 10;
        n /= 10;
    }
    printf("%d\n", sum);
    return 0;
}
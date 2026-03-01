#include <stdio.h>
#include <stdlib.h>

extern void* array_create(unsigned long n);
extern unsigned long array_get_len(void* arr);
extern unsigned long array_get(void* arr, unsigned long i);
extern void array_set(void* arr, unsigned long i, unsigned long v);
extern void array_free(void);
extern int array_push_back(void* arr, unsigned long v);
extern unsigned long array_pop_front(void* arr);
extern void array_remove_evens(void* arr);
extern unsigned long array_count_ending_with_1(void* arr);

void print_array(void* arr) {
    if (!arr) return;
    unsigned long len = array_get_len(arr);
    printf("Массив [%lu]: ", len);
    for (unsigned long i = 0; i < len; i++) {
        printf("%lu ", array_get(arr, i));
    }
    printf("\n");
}

int main() {
    void* arr = NULL;
    int cmd;
    unsigned long val;

    printf("1:Создать 2:Добавить 3:УдалитьПервый 4:УдалитьЧетные 5:Счет1 6:Показать 0:Выход\n");

    while (1) {
        printf("> ");
        if (scanf("%d", &cmd) != 1 || cmd == 0) break;

        switch (cmd) {
            case 1:
                printf("N: "); scanf("%lu", &val);
                if (arr) array_free();
                arr = array_create(val);
                break;
            case 2:
                if (arr) { printf("V: "); scanf("%lu", &val); array_push_back(arr, val); }
                break;
            case 3:
                if (arr) printf("Удалено: %lu\n", array_pop_front(arr));
                break;
            case 4:
                if (arr) array_remove_evens(arr);
                break;
            case 5:
                if (arr) printf("Кол-во на 1: %lu\n", array_count_ending_with_1(arr));
                break;
            case 6:
                print_array(arr);
                break;
        }
    }

    if (arr) array_free();
    return 0;
}
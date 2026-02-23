#include <stdio.h>
#include <stdlib.h> 

int main(int argc, char *argv[]) {
    // 1. Проверяем количество аргументов (ровно 4)
    if (argc != 4) {
        printf("Ошибка: нужно ввести 3 числа (a, b, c)\n");
        return 1;
    }

    // 2. Извлекаем аргументы и переводим их в числа типа long
    // argv[1] - это 'a', argv[2] - это 'b', argv[3] - это 'c'
    long a = atol(argv[1]);
    long b = atol(argv[2]);
    long c = atol(argv[3]);

    // Проверка на деление на ноль, как и в ассемблере
    if (c == 0) {
        printf("Ошибка: деление на ноль\n");
        return 1;
    }

    // 3. Расчет значения арифметического выражения: ((((a-c)*b)/c)*a)
    long result = ((((a - c) * b) / c) * a);

    // 4. Вывод результата на экран
    printf("%ld\n", result);

    return 0;
}
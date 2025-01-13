from typing import List

def task_1(array: List[int], target: int) -> List[int]:
    """
    Find two numbers in the list that sum to the target.
    """
    seen = {}
    for num in array:
        complement = target - num
        if complement in seen:
            return [complement, num]
        seen[num] = True
    return []

def task_2(number: int) -> int:
    """
    Reverse the digits of an integer without using string operations.
    """
    reversed_number = 0
    while number > 0:
        digit = number % 10
        reversed_number = reversed_number * 10 + digit
        number //= 10
    return reversed_number

def task_3(array: List[int]) -> int:
    """
    Find the first number that appears more than once in the list.
    """
    for i in range(len(array)):
        index = abs(array[i]) - 1
        if array[index] < 0:
            return abs(array[i])
        array[index] = -array[index]
    return -1

def task_4(string: str) -> int:
    """
    Convert a Roman numeral string to an integer.
    """
    roman_to_int = {
        'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000
    }
    total = 0
    prev_value = 0
    for char in reversed(string):
        current_value = roman_to_int[char]
        if current_value < prev_value:
            total -= current_value
        else:
            total += current_value
        prev_value = current_value
    return total

def task_5(array: List[int]) -> int:
    """
    Find the smallest number in the list without using the min function.
    """
    smallest = float('inf')
    for num in array:
        if num < smallest:
            smallest = num
    return smallest

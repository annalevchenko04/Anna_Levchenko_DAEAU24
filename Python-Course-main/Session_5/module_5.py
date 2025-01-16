import os
from pathlib import Path
from random import choice, seed
from typing import List, Union
from collections import Counter
import requests
from requests.exceptions import RequestException

# Define paths
S5_PATH = Path(os.path.realpath(__file__)).parent

PATH_TO_NAMES = S5_PATH / "names.txt"
PATH_TO_SURNAMES = S5_PATH / "last_names.txt"
PATH_TO_OUTPUT = S5_PATH / "sorted_names_and_surnames.txt"
PATH_TO_TEXT = S5_PATH / "random_text.txt"
PATH_TO_STOP_WORDS = S5_PATH / "stop_words.txt"

def task_1():
    seed(1)  # Seed for reproducibility
    try:
        # Read and sort names
        with open(PATH_TO_NAMES, 'r') as names_file:
            names = sorted(name.strip().lower() for name in names_file)

        # Read surnames
        with open(PATH_TO_SURNAMES, 'r') as surnames_file:
            surnames = [surname.strip().lower() for surname in surnames_file]

        # Assign random surnames to names
        with open(PATH_TO_OUTPUT, 'w') as output_file:
            for name in names:
                full_name = f"{name} {choice(surnames)}"
                output_file.write(full_name + '\n')
    except FileNotFoundError as e:
        print(f"Error: {e}")

def task_2(top_k: int):
    try:
        # Read random text
        with open(PATH_TO_TEXT, 'r') as text_file:
            text = text_file.read().lower()

        # Read stop words
        with open(PATH_TO_STOP_WORDS, 'r') as stop_words_file:
            stop_words = set(word.strip().lower() for word in stop_words_file)

        # Tokenize text and remove stop words
        words = [word for word in text.split() if word.isalpha() and word not in stop_words]

        # Count word frequencies
        word_counts = Counter(words)

        # Return top_k words and frequencies
        return word_counts.most_common(top_k)
    except FileNotFoundError as e:
        print(f"Error: {e}")


def task_3(url: str):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response
    except RequestException as e:
        raise RequestException(f"Request failed: {e}")

def task_4(data: List[Union[int, str, float]]):
    total = 0
    for item in data:
        try:
            total += float(item)
        except ValueError:
            raise TypeError(f"Cannot convert {item} to float.")
    return total

def task_5():
    try:
        a, b = input("Enter two numbers separated by a space: ").split()
        a, b = float(a), float(b)

        if b == 0:
            print("Can't divide by zero")
        else:
            print(a / b)
    except ValueError:
        print("Entered value is wrong")

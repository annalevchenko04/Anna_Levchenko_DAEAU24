import os
import random
import re
from collections import Counter
from requests.exceptions import RequestException
import requests

def task_1():
    # Define file paths
    names_file = 'names.txt'
    last_names_file = 'last_names.txt'
    output_file = 'sorted_names_and_surnames.txt'

    # Read and process names
    with open(names_file, 'r', encoding='utf-8') as nf:
        names = sorted(name.strip().lower() for name in nf.readlines())

    # Read last names
    with open(last_names_file, 'r', encoding='utf-8') as lnf:
        last_names = [ln.strip().lower() for ln in lnf.readlines()]

    # Combine names and last names
    full_names = [f"{name} {random.choice(last_names)}" for name in names]

    # Write to output file
    with open(output_file, 'w', encoding='utf-8') as of:
        of.write("\n".join(full_names))

def task_2(top_k):
    # Define file paths
    text_file = 'random_text.txt'
    stop_words_file = 'stop_words.txt'

    # Read stop words
    with open(stop_words_file, 'r', encoding='utf-8') as swf:
        stop_words = set(sw.strip().lower() for sw in swf.readlines())

    # Read and clean text
    with open(text_file, 'r', encoding='utf-8') as tf:
        text = tf.read().lower()
        words = re.findall(r'[a-z]+', text)
        filtered_words = [word for word in words if word not in stop_words]

    # Count word frequencies
    word_counts = Counter(filtered_words)

    # Get top_k words
    return word_counts.most_common(top_k)

def task_3(url):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response
    except RequestException as e:
        raise RequestException from e

def task_4(data):
    total = 0
    for item in data:
        try:
            total += float(item)
        except (TypeError, ValueError):
            raise TypeError(f"Cannot convert {item} to float.")
    return total

def task_5():
    try:
        a, b = input().split()
        a, b = float(a), float(b)
        if b == 0:
            print("Can't divide by zero")
        else:
            print(f"{a / b:.3f}")
    except ValueError:
        print("Entered value is wrong")

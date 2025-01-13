# from collections import defaultdict as dd
# from itertools import product
from collections import defaultdict
from itertools import product
from typing import Any, Dict, List, Tuple

def task_1(data_1: Dict[str, int], data_2: Dict[str, int]) -> Dict[str, int]:
    """Combine two dictionaries, adding values for common keys."""
    result = data_1.copy()
    for key, value in data_2.items():
        result[key] = result.get(key, 0) + value
    return result

def task_2() -> Dict[int, int]:
    """Return a dictionary where keys are 1-15 and values are their squares."""
    return {x: x**2 for x in range(1, 16)}

def task_3(data: Dict[Any, List[str]]) -> List[str]:
    """Create and display all combinations of letters from a dictionary."""
    combinations = product(*data.values())
    return ["".join(combo) for combo in combinations]

def task_4(data: Dict[str, int]) -> List[str]:
    """Find the keys of the highest 3 values in a dictionary."""
    return [key for key, _ in sorted(data.items(), key=lambda item: item[1], reverse=True)[:3]]

def task_5(data: List[Tuple[Any, Any]]) -> Dict[str, List[int]]:
    """Group a sequence of key-value pairs into a dictionary of lists."""
    result = defaultdict(list)
    for key, value in data:
        result[key].append(value)
    return dict(result)

def task_6(data: List[Any]) -> List[Any]:
    """Delete repeated elements from a list, preserving order."""
    seen = set()
    result = []
    for item in data:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result

def task_7(words: List[str]) -> str:
    """Find the longest common prefix among strings in a list."""
    if not words:
        return ""
    prefix = words[0]
    for word in words[1:]:
        while not word.startswith(prefix):
            prefix = prefix[:-1]
            if not prefix:
                return ""
    return prefix

def task_8(haystack: str, needle: str) -> int:
    """Return the index of the first occurrence of needle in haystack, or -1 if not found."""
    if needle == "":
        return 0
    return haystack.find(needle)

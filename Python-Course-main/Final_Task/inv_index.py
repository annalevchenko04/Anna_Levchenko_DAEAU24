import re
import sys
import json
from argparse import ArgumentParser, ArgumentTypeError, FileType
from io import TextIOWrapper
from typing import Dict, List

DEFAULT_PATH_TO_STORE_INVERTED_INDEX = "index.json"
STOPWORDS = {"a", "and", "around", "every", "for", "from", "in", "is", "it", "not", "on", "one", "the", "to", "under"}


class EncodedFileType(FileType):
    """File encoder"""

    def __call__(self, string):
        if string == "-":
            if "r" in self._mode:
                stdin = TextIOWrapper(sys.stdin.buffer, encoding=self._encoding)
                return stdin
            if "w" in self._mode:
                stdout = TextIOWrapper(sys.stdout.buffer, encoding=self._encoding)
                return stdout
            msg = 'argument "-" with mode %r' % self._mode
            raise ValueError(msg)

        try:
            return open(string, self._mode, self._bufsize, self._encoding, self._errors)
        except OSError as exception:
            args = {"filename": string, "error": exception}
            message = "can't open '%(filename)s': %(error)s"
            raise ArgumentTypeError(message % args)

    def print_encoder(self):
        print(self._encoding)


class InvertedIndex:
    def __init__(self, words_ids: Dict[str, list]):
        self.words_ids = words_ids

    def query(self, words: List[str]) -> List[int]:
        """Return the list of relevant documents for the given query"""
        result = None
        for word in words:
            if word in self.words_ids:
                if result is None:
                    result = self.words_ids[word]
                else:
                    result &= self.words_ids[word]
            else:
                return []  # If one word is missing, no docs match
        return sorted(result) if result else []

    def dump(self, filepath: str) -> None:
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(self.words_ids, f)

    @classmethod
    def load(cls, filepath: str):
        with open(filepath, "r", encoding="utf-8") as f:
            words_ids = json.load(f)
        # Convert lists back to sets for fast intersection during query
        words_ids = {word: set(doc_ids) for word, doc_ids in words_ids.items()}
        return cls(words_ids)


def load_documents(filepath: str) -> Dict[int, str]:
    """
    Load documents from a file, assuming each line is a document.
    :param filepath: Path to the document file.
    :return: Dictionary with document ID and content.
    """
    documents = {}
    doc_id = None
    content = []
    # Adjust the pattern to match a number followed by at least one whitespace character (spaces or tabs)
    pattern = re.compile(r"^\d+\s+")

    with open(filepath, "r", encoding="utf-8") as file:
        for line in file:
            # Check if the line starts with a number followed by spaces or tabs
            if pattern.match(line):
                # If there was a previous document, save it
                if doc_id is not None:
                    documents[doc_id] = " ".join(content).strip()

                # Extract the document ID (the number at the start of the line)
                doc_id = int(line.split()[0])  # Split by whitespace and take the first part (the ID)

                # Start the new document content with the rest of the line after the ID and whitespace
                content = [line.split(maxsplit=1)[1].strip()] if len(line.split(maxsplit=1)) > 1 else []
            else:
                # Otherwise, continue adding lines to the current document content
                content.append(line.strip())

        # Add the last document after finishing the loop
        if doc_id is not None:
            documents[doc_id] = " ".join(content).strip()

    return documents


def build_inverted_index(documents: Dict[int, str]) -> InvertedIndex:
    """
    Build the inverted index from the given documents.
    :param documents: Dictionary of document ID to text.
    :return: InvertedIndex instance.
    """
    inverted_index = {}
    for doc_id, text in documents.items():
        words = text.lower().split()
        filtered_words = [word for word in words if word not in STOPWORDS]
        for word in filtered_words:
            if word not in inverted_index:
                inverted_index[word] = list()
            inverted_index[word].append(doc_id)
    return InvertedIndex(inverted_index)


def callback_build(arguments) -> None:
    process_build(arguments.dataset, arguments.output)


def process_build(dataset, output) -> None:
    documents = load_documents(dataset)
    inverted_index = build_inverted_index(documents)
    inverted_index.dump(output)


def callback_query(arguments) -> None:
    process_query(arguments.query, arguments.index)


def process_query(queries, index) -> None:
    inverted_index = InvertedIndex.load(index)
    for query in queries:
        if isinstance(query, str):
            query = query.strip().split()
        doc_indexes = inverted_index.query(query)
        print(" ".join(map(str, doc_indexes)))


def setup_subparsers(parser) -> None:
    subparser = parser.add_subparsers(dest="command")
    build_parser = subparser.add_parser("build", help="Build the inverted index")
    build_parser.add_argument(
        "-d", "--dataset", required=True, help="Path to the document dataset"
    )
    build_parser.add_argument(
        "-o",
        "--output",
        default=DEFAULT_PATH_TO_STORE_INVERTED_INDEX,
        help="Path to save the inverted index (default: %(default)s)",
    )
    build_parser.set_defaults(callback=callback_build)

    query_parser = subparser.add_parser("query", help="Query the inverted index")
    query_parser.add_argument(
        "--index",
        default=DEFAULT_PATH_TO_STORE_INVERTED_INDEX,
        help="Path to the inverted index file (default: %(default)s)",
    )
    query_file_group = query_parser.add_mutually_exclusive_group(required=True)
    query_file_group.add_argument(
        "-q",
        "--query",
        dest="query",
        action="append",
        nargs="+",
        help="List of queries to process",
    )
    query_file_group.add_argument(
        "--query_from_file",
        dest="query",
        type=EncodedFileType("r", encoding="utf-8"),
        help="File containing queries",
    )
    query_parser.set_defaults(callback=callback_query)


def main():
    parser = ArgumentParser(description="Inverted Index CLI")
    setup_subparsers(parser)
    arguments = parser.parse_args()
    arguments.callback(arguments)


if __name__ == "__main__":
    main()

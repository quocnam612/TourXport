import json
import os


def _save_json(data, directory: str, filename: str):
    os.makedirs(directory, exist_ok=True)

    filepath = os.path.join(directory, filename)
    with open(filepath, "w", encoding="utf-8") as json_file:
        json.dump(data, json_file, indent=4, ensure_ascii=False)
    print(f"Data successfully saved to {filepath}")


def save_to_json(data, filename: str):
    data_dir = os.path.join(os.path.dirname(__file__), "..", "..", "data")
    _save_json(data, data_dir, filename)


def save_to_output_json(data, filename: str):
    output_dir = os.path.join(os.path.dirname(__file__), "..", "..", "data", "output")
    _save_json(data, output_dir, filename)


def save_to_data_json(data, filename: str, subdir: str = "places"):
    data_dir = os.path.join(os.path.dirname(__file__), "..", "..", "data", subdir)
    _save_json(data, data_dir, filename)

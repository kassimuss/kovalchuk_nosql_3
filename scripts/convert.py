import csv
import os

RAW_DIR = "data/raw"
OUT_DIR = "data/import"

os.makedirs(OUT_DIR, exist_ok=True)

with open(f"{RAW_DIR}/movies.dat", encoding="latin-1") as f_in, \
     open(f"{OUT_DIR}/movies.csv", "w", newline="", encoding="utf-8") as f_out:
    writer = csv.writer(f_out)
    writer.writerow(["movieId", "title", "genres"])

    for line in f_in:
        parts = line.strip().split("::")
        writer.writerow(parts)

with open(f"{RAW_DIR}/ratings.dat", encoding="latin-1") as f_in, \
     open(f"{OUT_DIR}/ratings.csv", "w", newline="", encoding="utf-8") as f_out:
    writer = csv.writer(f_out)
    writer.writerow(["userId", "movieId", "rating", "timestamp"])

    for line in f_in:
        parts = line.strip().split("::")
        writer.writerow(parts)

with open(f"{RAW_DIR}/users.dat", encoding="latin-1") as f_in, \
     open(f"{OUT_DIR}/users.csv", "w", newline="", encoding="utf-8") as f_out:
    writer = csv.writer(f_out)
    writer.writerow(["userId", "gender", "age", "occupation"])

    for line in f_in:
        parts = line.strip().split("::")
        writer.writerow(parts[:4])

print("CSV файли створено в data/import")
# TravelTide - Customer Segmentation

This project segments TravelTide customers into behavioral groups so the
marketing team can send each group a personalized reward.

## Table of contents

1. [Project overview](#project-overview)
2. [Repository structure](#repository-structure)
3. [Setup](#setup)
4. [Getting the raw data](#getting-the-raw-data)
5. [Running the notebooks](#running-the-notebooks-in-order)
6. [Output](#output)
7. [Notes and troubleshooting](#notes-and-troubleshooting)

## Project overview

TravelTide is an online travel booking platform. The goal of this project is to
understand how its customers behave and to split them into clear segments. Each
segment then receives a fitting reward, for example a discount for deal seekers
or a perk for loyal frequent travelers.

The analysis works on "power users": users who started at least one session on
or after `2023-01-05` and who have more than 7 sessions in total. Everyone else
is out of scope.

The end to end pipeline is:

1. Pull the raw tables (`users`, `sessions`, `flights`, `hotels`) from the
   TravelTide Postgres database, keeping only the power users and their rows.
2. Clean and explore the data (EDA).
3. Build one row per user with behavioral features (number of sessions, trips,
   flights, hotels, booking discount rate, average seats, average nights,
   weekend trip ratio, total flight cost, total hotel cost, and more).
4. Analyze the features and assign rule based segments.
5. Cluster the users that no rule covered with K-Means.
6. Write the final segment per user.

The segments produced are:

- Rule based: `Only Flight`, `Only Hotel`, `Family travelers`,
  `Discount buyer`, `Youngs`, `Retired`, `High Spenders`, `Indecisive`,
  `Long Stayers`.
- From clustering (K-Means on the users left as `Not assigned`):
  `Frequent Travelers`, `Budget Travelers`, `Comfort Travelers`.

## Repository structure

```
TravelTideSep/
├── data/
│   ├── data_raw/            # raw CSVs exported from the database
│   │   ├── users.csv
│   │   ├── sessions.csv
│   │   ├── flights.csv
│   │   ├── hotels.csv
│   │   └── sql_queries.sql  # SQL used to export the raw data
│   ├── data_preprocessed/   # cleaned data + per-user features
│   └── final_groups.csv     # final output: user_id -> group
├── final_results/           # copies of the final output
├── 01_EDA.ipynb
├── 02_user_features.ipynb
├── 03_user_features_analysis.ipynb
├── 04_Clustering.ipynb
└── .gitignore
```

Note: all `.csv` files are ignored by git (see `.gitignore`), and the `data`
folders are kept with empty `.gitkeep` files. This means the data is not in the
repository, so you have to regenerate it yourself by following the steps below.

## Setup

Prerequisites:

- Python 3.12 or newer
- `git`
- A Postgres client to pull the data: `psql`, DBeaver, or the Neon web SQL
  editor

Steps:

```bash
# 1. Clone the repository
git clone <repo-url>
cd TravelTideSep

# 2. Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate

# 3. Install the dependencies
pip install pandas numpy matplotlib seaborn scikit-learn airports jupyter ipykernel

# 4. (Optional) register a Jupyter kernel for this project
python -m ipykernel install --user --name traveltide
```

The libraries used by the notebooks are: `pandas`, `numpy`, `matplotlib`,
`seaborn`, `scikit-learn` and `airports` (used to map airport IATA codes to
states). Versions used while developing: pandas 3.0.5, numpy 2.5.3,
matplotlib 3.11.2, seaborn 0.13.2, scikit-learn 1.9.1, airports 0.1.2.

## Getting the raw data

The raw data lives in a Postgres database (Neon). Use this connection string:

```
postgres://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/TravelTide
```

If your client requires SSL, append `?sslmode=require` to the string.

All the SQL needed for the export is in `data/data_raw/sql_queries.sql`. The
file contains four queries (one per table) that keep only the power users and
their related rows. Run each query and export its result to the matching CSV
inside `data/data_raw/`.

Option A: `psql` with `\copy` (the query runs on the server, the CSV is written
on your machine):

```bash
export DB_URL="postgres://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/TravelTide"

# users  (first query in sql_queries.sql, "user table filter")
psql "$DB_URL" -c "\copy (QUERY_USERS) TO 'data/data_raw/users.csv' WITH (FORMAT csv, HEADER)"
# sessions (second query, "session table")
psql "$DB_URL" -c "\copy (QUERY_SESSIONS) TO 'data/data_raw/sessions.csv' WITH (FORMAT csv, HEADER)"
# flights (third query, "flights table")
psql "$DB_URL" -c "\copy (QUERY_FLIGHTS) TO 'data/data_raw/flights.csv' WITH (FORMAT csv, HEADER)"
# hotels (fourth query, "hotels table")
psql "$DB_URL" -c "\copy (QUERY_HOTELS) TO 'data/data_raw/hotels.csv' WITH (FORMAT csv, HEADER)"
```

Copy the body of each query from `sql_queries.sql` in place of `QUERY_*`.

Option B: any GUI (DBeaver, pgAdmin, or the Neon SQL editor): open
`data/data_raw/sql_queries.sql`, run the four queries one by one, and export
each result set to CSV **with a header row**, saving into `data/data_raw/`.

After this step you should have:

```
data/data_raw/users.csv
data/data_raw/sessions.csv
data/data_raw/flights.csv
data/data_raw/hotels.csv
```

## Running the notebooks, in order

Start Jupyter from the project root so that all the relative paths used in the
notebooks resolve correctly:

```bash
jupyter notebook
```

Then run the notebooks in this exact order:

1. `01_EDA.ipynb` - Explores the raw data and cleans it. Reads the raw CSVs and
   writes `data/data_preprocessed/users_preprocessed.csv`,
   `sessions_preprocessed.csv`, `hotels_preprocessed.csv` and
   `flights_preprocessed.csv`.
2. `02_user_features.ipynb` - Builds the per-user feature table. Writes
   `data/data_preprocessed/user_features.csv`.
3. `03_user_features_analysis.ipynb` - Analyzes the features and assigns the
   rule based segments. Writes
   `data/data_preprocessed/user_features_grouped1.csv`.
4. `04_Clustering.ipynb` - Runs K-Means on the users still marked
   `Not assigned`, merges them back, and writes the final result
   `data/final_groups.csv`.

Each notebook depends on the output of the previous one, so do not skip or
reorder them.

## Output

The final deliverable is `data/final_groups.csv` with two columns:

| column  | description                              |
|---------|------------------------------------------|
| user_id | the customer id                          |
| group   | the segment the customer was assigned to |

Example:

```
user_id,group
106907,Indecisive
118043,High Spenders
```

## Notes and troubleshooting

- All paths inside the notebooks are relative to the project root. Always run
  Jupyter from the repository root.
- In `01_EDA.ipynb` the users table is read as `data_raw/users.csv`. If that
  fails, point the read to `data/data_raw/users.csv`.
- `.csv` files are intentionally ignored by git, so the data has to be
  regenerated with the SQL export and the notebooks. The empty `.gitkeep` files
  only keep the folder structure in the repository.
- The Postgres database can be paused when idle (Neon). If the connection
  fails, open the Neon dashboard once to wake it, then retry.
- Some flights or hotels rows have no matching trip in the sessions table
  (cancellations, negative nights, and duplicate rows). The notebooks handle
  these during cleaning, so run them as provided.

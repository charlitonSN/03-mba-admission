# -*- coding: utf-8 -*-
"""
Converte todos os arquivos CSV desta pasta em tabelas de um banco SQLite.
Uso: python gerar_banco.py
"""
import glob
import os
import re
import sqlite3
import unicodedata

import pandas as pd

DB_NAME = "mba-admission.db"


def slug_table_name(filename):
    name = os.path.splitext(os.path.basename(filename))[0]
    name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode("ascii")
    name = re.sub(r"[^0-9a-zA-Z]+", "_", name).strip("_").lower()
    return name or "tabela"


def detect_separator(path):
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        first_line = f.readline()
    return ";" if first_line.count(";") > first_line.count(",") else ","


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    csv_files = sorted(glob.glob(os.path.join(here, "*.csv")))

    if not csv_files:
        print("Nenhum arquivo .csv encontrado nesta pasta. Baixe o dataset (veja README.md) antes de rodar este script.")
        return

    db_path = os.path.join(here, DB_NAME)
    conn = sqlite3.connect(db_path)

    for csv_path in csv_files:
        table = slug_table_name(csv_path)
        sep = detect_separator(csv_path)
        try:
            df = pd.read_csv(csv_path, sep=sep, encoding="utf-8", low_memory=False)
        except UnicodeDecodeError:
            df = pd.read_csv(csv_path, sep=sep, encoding="latin1", low_memory=False)
        df.to_sql(table, conn, if_exists="replace", index=False)
        print(f"Tabela '{table}' criada a partir de {os.path.basename(csv_path)} ({len(df)} linhas, {len(df.columns)} colunas)")

    conn.close()
    print(f"\nBanco gerado em: {db_path}")


if __name__ == "__main__":
    main()

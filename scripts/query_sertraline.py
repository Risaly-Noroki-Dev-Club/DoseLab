#!/usr/bin/env python3
"""
Experimental query: 盐酸舍曲林片 (Sertraline Hydrochloride)

Queries openFDA drug/ndc and drug/label endpoints, extracts structured
medication data, and saves results to data/ directory.

Usage:
    python3 scripts/query_sertraline.py
"""

import json
import os
import sys
import textwrap

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fda_query import (
    query, search_ndc, search_label, save_envelope,
)

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")


def extract_pk_from_label(label: dict) -> dict:
    """Pull PK-relevant text and structured fields from a label record."""
    fields = {
        "clinical_pharmacology": label.get("clinical_pharmacology", []),
        "pharmacokinetics": label.get("pharmacokinetics", []),
        "pharmacodynamics": label.get("pharmacodynamics", []),
        "dosage_and_administration": label.get("dosage_and_administration", []),
        "indications_and_usage": label.get("indications_and_usage", []),
        "active_ingredient": label.get("active_ingredient", []),
        "warnings": label.get("warnings", []),
        "mechanism_of_action": label.get("mechanism_of_action", []),
    }
    openfda = label.get("openfda", {})
    return {
        "brand_name": openfda.get("brand_name", []),
        "generic_name": openfda.get("generic_name", []),
        "manufacturer_name": openfda.get("manufacturer_name", []),
        "substance_name": openfda.get("substance_name", []),
        "route": openfda.get("route", []),
        "rxcui": openfda.get("rxcui", []),
        "spl_set_id": openfda.get("spl_set_id", []),
        "label_id": label.get("id"),
        "effective_time": label.get("effective_time"),
        "version": label.get("version"),
        "text_sections": {k: v for k, v in fields.items() if v},
    }


def print_env_status(label, env):
    total = env.get("meta", {}).get("results", {}).get("total", "?")
    print(f"  [{env['status']}] {label}: total={total}")


def main():
    os.makedirs(DATA_DIR, exist_ok=True)
    search_term = "Zoloft"

    # --- Step 1: NDC search ---
    print(f"=== Querying NDC for '{search_term}' ===")
    ndc_env = search_ndc(search_term, limit=20)
    save_envelope(ndc_env, os.path.join(DATA_DIR, "sertraline_ndc.json"))
    print_env_status("NDC search", ndc_env)
    print(f"  Saved to data/sertraline_ndc.json")

    # --- Step 2: Get all NDC for the original Zoloft SPL set ---
    spl_set_id = "fe9e8b7d-61ea-409d-84aa-3ebd79a046b5"  # Zoloft original
    print(f"\n=== Querying all NDC for SPL set {spl_set_id} ===")
    ndc_all = query("drug/ndc.json",
                    f'openfda.spl_set_id:"{spl_set_id}"',
                    limit=100)
    save_envelope(ndc_all, os.path.join(DATA_DIR, "sertraline_ndc_all_strengths.json"))
    if ndc_all["status"] == "fresh":
        total_pkg = sum(len(r.get("packaging", [])) for r in ndc_all.get("results", []))
        print(f"  Products: {len(ndc_all['results'])}, unique packages: {total_pkg}")
    else:
        print(f"  Error: {ndc_all.get('error', 'unknown')}")
    print(f"  Saved to data/sertraline_ndc_all_strengths.json")

    # --- Step 3: Label search ---
    print(f"\n=== Querying Label for '{search_term}' ===")
    label_env = search_label(search_term, limit=3)
    save_envelope(label_env, os.path.join(DATA_DIR, "sertraline_label.json"))
    print_env_status("Label search", label_env)
    print(f"  Saved to data/sertraline_label.json")

    # --- Step 4: Extract PK summary from best label ---
    print("\n=== Extracted PK Summary ===")
    labels = label_env.get("results", [])
    if labels:
        pk = extract_pk_from_label(labels[0])
        save_envelope(pk, os.path.join(DATA_DIR, "sertraline_pk_extracted.json"))
        print(f"  Brand: {pk['brand_name']}")
        print(f"  Generic: {pk['generic_name']}")
        print(f"  Label version: {pk['version']} (effective {pk['effective_time']})")

        for section_name, texts in pk["text_sections"].items():
            print(f"\n  --- {section_name} ---")
            preview = texts[0] if texts else ""
            wrapped = textwrap.fill(preview[:400], width=80, subsequent_indent="    ")
            print(f"    {wrapped}")
            if len(preview) > 400:
                print(f"    ... (truncated, full text in data/sertraline_pk_extracted.json)")

        print(f"\n  Saved to data/sertraline_pk_extracted.json")

    print("\n=== Done ===")


if __name__ == "__main__":
    main()

# Declaration Module

This folder contains the **Custom Declaration** module of the CDMS.

## File
- `cdms_declaration_ready.sql` — Full PostgreSQL script for the declaration module

## How To Run
1. Create a database called `custom_declaration` in pgAdmin
2. Open Query Tool under that database
3. Paste the entire script and press **F5**

## What Gets Created
- 12 tables inside the `dc` schema
- 5 triggers (auto duty, auto payment, port check, auto clearance, audit)
- 25+ indexes (B-Tree, Composite, Partial, BRIN, GIN, Hash)
- 3 regular views + 1 materialized view
- 4 security roles
- Sample data with 4 shipments and 6 items

## Schema
`dc` (short for Declaration Custom)

## Roles
| Role | Access |
|------|--------|
| `declaration_admin` | Full access |
| `declaration_officer` | Manage shipments and documents |
| `declaration_finance` | Manage payments |
| `declaration_viewer` | Read only |

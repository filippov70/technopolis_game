#!/bin/bash
pg_dump -U game -F p -n game -f game.sql

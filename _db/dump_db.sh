#!/bin/bash
pg_dump -U game -W game -c -F c -n game -v -f game.dump

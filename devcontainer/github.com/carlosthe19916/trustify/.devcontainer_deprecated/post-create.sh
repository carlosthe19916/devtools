#!/bin/bash

echo "alias start:dev='cargo run --bin trustd db migrate && cargo run --bin trustd api'" >> ~/.bashrc
echo "alias psql:postgres='env PGPASSWORD=trustify psql -U postgres -d postgres -h trustify-db -p 5432'" >> ~/.bashrc

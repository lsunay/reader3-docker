#!/bin/bash
set -e

# If pyproject.toml exists, install dependencies
if [ -f pyproject.toml ]; then
    echo "Installing dependencies with uv..."
    uv sync
fi

# Preprocess books: scan /app/books for all .epub files and process them with reader3.py
# Create _data folders under /app/books (dynamic output_dir: /app/books/book_name_data)
echo "Preprocessing books in /app/books..."
if [ -d "/app/books" ] && [ "$(ls -A /app/books/*.epub 2>/dev/null)" ]; then
  for epub in /app/books/*.epub; do
    if [ -f "$epub" ]; then
      # Set output_dir to the epub’s name: /app/books/book_name_data
      output_dir="/app/books/$(basename "$epub" .epub)_data"
      # If the _data directory exists and contains book.pkl, skip processing
      if [ -d "$output_dir" ] && [ -f "$output_dir/book.pkl" ]; then
        echo "Skipping $epub (already processed: $output_dir)"
      else
        echo "Processing $epub"
        uv run python3 reader3.py "$epub" "$output_dir"
      fi
    fi
  done
else
  echo "No EPUB files found in /app/books. Skipping preprocessing."
fi

# Execute the supplied command
exec "$@"

#!/bin/sh

for file in $(ls content); do
    pandoc -s "content/${file}" -o "markdown/${file}.md"
done

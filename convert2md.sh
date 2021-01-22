#!/bin/sh

for file in $(ls content); do
    pandoc --metadata title="${file}" --toc --standalone --mathjax -t html -s "content/${file}" -t html -o "html/${file}.html"
done

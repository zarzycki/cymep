#!/bin/bash

for FILE in ./*.pdf; do
  pdfcrop "${FILE}" "${FILE}"
done

mkdir -p cropped/
mv *pdf cropped/


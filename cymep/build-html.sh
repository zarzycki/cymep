#!/bin/bash

# Take the config string as an argument
config_string=$1
if [ -z "$config_string" ]; then
    echo "Please provide a config string (e.g., cam7_configs_NATL)"
    exit 1
fi

# Check for required dependency
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick 'magick' not found. Install it and try again."
    exit 1
fi

# Create top level output directory
output_dir="gallery_${config_string}"
echo "Clean up old directory"
rm -rfv "${output_dir}"
rm -rfv "${output_dir}.zip"
mkdir -p "${output_dir}"

# Create subdirectories matching the CyMeP structure
mkdir -p "${output_dir}/line"
mkdir -p "${output_dir}/spatial"
mkdir -p "${output_dir}/tables"
mkdir -p "${output_dir}/taylor"

DPI=200

# Convert PDFs to PNGs (both full size and thumbnails)
find fig/ -name "*$config_string*.pdf" | while read pdf_file; do
    # Get the directory name and base filename
    dir_name=$(dirname "$pdf_file" | sed 's|fig/||')
    base_name=$(basename "$pdf_file" .pdf)

    # Create full-size PNG
    magick -density $DPI "$pdf_file" -trim +repage "${output_dir}/${dir_name}/${base_name}.png"

    # Create thumbnail version
    magick -density $DPI "$pdf_file" -trim +repage -resize 300x300 "${output_dir}/${dir_name}/${base_name}_thumb.png"
done

# Create base HTML file with header
cat > "${output_dir}/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Results Gallery - ${config_string}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 40px;
        }
        .row {
            margin-bottom: 40px;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .row-title {
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        .gallery {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
            justify-items: center;
        }
        .image-container {
            text-align: center;
            width: 100%;
        }
        .thumbnail {
            max-width: 250px;
            height: auto;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 5px;
            background-color: white;
            transition: transform 0.2s;
        }
        .thumbnail:hover {
            transform: scale(1.05);
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        .description {
            margin: 8px 0;
            color: #666;
            font-size: 0.9em;
            word-wrap: break-word;
        }
        a {
            text-decoration: none;
            color: inherit;
        }
    </style>
</head>
<body>
    <h1>Results Gallery - ${config_string}</h1>
EOF

# First create the verification section combining tables and taylor
echo "<div class='row'>" >> "${output_dir}/index.html"
echo "<h2 class='row-title'>Verification Metrics</h2>" >> "${output_dir}/index.html"
echo "<div class='gallery'>" >> "${output_dir}/index.html"

# Add tables first
find "${output_dir}/tables" -name "*$config_string*.png" | grep -v "_thumb.png" | sort | while read png_file; do
    base_name=$(basename "$png_file" .png)
    echo "<div class='image-container'>" >> "${output_dir}/index.html"
    echo "<a href='tables/${base_name}.png'>" >> "${output_dir}/index.html"
    echo "<img class='thumbnail' src='tables/${base_name}_thumb.png' alt='${base_name}'>" >> "${output_dir}/index.html"
    echo "<div class='description'>${base_name}</div>" >> "${output_dir}/index.html"
    echo "</a>" >> "${output_dir}/index.html"
    echo "</div>" >> "${output_dir}/index.html"
done

# Then add taylor
find "${output_dir}/taylor" -name "*$config_string*.png" | grep -v "_thumb.png" | sort | while read png_file; do
    base_name=$(basename "$png_file" .png)
    echo "<div class='image-container'>" >> "${output_dir}/index.html"
    echo "<a href='taylor/${base_name}.png'>" >> "${output_dir}/index.html"
    echo "<img class='thumbnail' src='taylor/${base_name}_thumb.png' alt='${base_name}'>" >> "${output_dir}/index.html"
    echo "<div class='description'>${base_name}</div>" >> "${output_dir}/index.html"
    echo "</a>" >> "${output_dir}/index.html"
    echo "</div>" >> "${output_dir}/index.html"
done

echo "</div></div>" >> "${output_dir}/index.html"

# Add Spatial section
echo "<div class='row'>" >> "${output_dir}/index.html"
echo "<h2 class='row-title'>Spatial</h2>" >> "${output_dir}/index.html"
echo "<div class='gallery'>" >> "${output_dir}/index.html"

find "${output_dir}/spatial" -name "*$config_string*.png" | grep -v "_thumb.png" | sort | while read png_file; do
    base_name=$(basename "$png_file" .png)
    echo "<div class='image-container'>" >> "${output_dir}/index.html"
    echo "<a href='spatial/${base_name}.png'>" >> "${output_dir}/index.html"
    echo "<img class='thumbnail' src='spatial/${base_name}_thumb.png' alt='${base_name}'>" >> "${output_dir}/index.html"
    echo "<div class='description'>${base_name}</div>" >> "${output_dir}/index.html"
    echo "</a>" >> "${output_dir}/index.html"
    echo "</div>" >> "${output_dir}/index.html"
done

echo "</div></div>" >> "${output_dir}/index.html"

# Add Line section
echo "<div class='row'>" >> "${output_dir}/index.html"
echo "<h2 class='row-title'>Line</h2>" >> "${output_dir}/index.html"
echo "<div class='gallery'>" >> "${output_dir}/index.html"

find "${output_dir}/line" -name "*$config_string*.png" | grep -v "_thumb.png" | sort | while read png_file; do
    base_name=$(basename "$png_file" .png)
    echo "<div class='image-container'>" >> "${output_dir}/index.html"
    echo "<a href='line/${base_name}.png'>" >> "${output_dir}/index.html"
    echo "<img class='thumbnail' src='line/${base_name}_thumb.png' alt='${base_name}'>" >> "${output_dir}/index.html"
    echo "<div class='description'>${base_name}</div>" >> "${output_dir}/index.html"
    echo "</a>" >> "${output_dir}/index.html"
    echo "</div>" >> "${output_dir}/index.html"
done

echo "</div></div>" >> "${output_dir}/index.html"

# Close HTML file
echo "</body></html>" >> "${output_dir}/index.html"

# Create zip file
zip -r "${output_dir}.zip" "${output_dir}"

# Done!
echo "Gallery created in ${output_dir}/"
echo "Zip file created as ${output_dir}.zip"
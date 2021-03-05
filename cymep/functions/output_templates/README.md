### Output Templates

These files are used to generate the CMEC html landing page and output description JSON.

If new outputs are added to CyMeP, a description should be added to the template output_desc.json. Figures are organized by folder structure under the key "fig". CSV files are found under "csv-files" and divided by "mean" and "metric" versions. The NetCDF file is under "netcdf-files". An additional "statistics" section holds information for generating descriptions for the metrics in the CSV files. If the new outputs are located in different folders or have a different structure than existing outputs, additional code will likely be needed in ../write_cmec.py as well.

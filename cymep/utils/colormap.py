import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import pandas as pd 


# Create your palette
cmap2 = pd.DataFrame(sns.diverging_palette(10,240,sep=38,n=128))

print(cmap2)

#for color in cmap2:
#  for value in color:
#    value *= 255

cmap2.to_csv('colormap.csv')
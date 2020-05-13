import pandas as pd
import numpy as np
from matplotlib import pyplot as plt

a = pd.read_csv("../metrics_rean_configs_NATL_spatial_corr.csv")
#b = pd.read_csv("metrics_rean_configs_user_temporal_scorr.csv")
#b = b.dropna(axis=1)
#merged = a.merge(b, on='Model')
#merged.to_csv("output.csv", index=False)


df = a.set_index("Model", drop = True)

print(df)

#Round to two digits to print nicely
vals = np.around(df.values, 2)
#Normalize data to [0, 1] range for color mapping below
normal = (df - df.min()) / (df.max() - df.min())
normal = normal + (0.5-normal)*0.3
print(normal)

fig = plt.figure()
ax = fig.add_subplot(111)
ax.axis('off')
the_table=ax.table(cellText=vals, rowLabels=df.index, colLabels=df.columns, 
                   loc='center', cellLoc='center', cellColours=plt.cm.RdYlGn(normal),animated=True)
fig.savefig("table.png")
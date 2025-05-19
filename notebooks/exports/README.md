# Notebook Exports

This directory contains exported data, figures, and models from Jupyter notebooks.

## Purpose

The exports directory serves as a bridge between notebook exploration and the main application:

1. **Data Exports**: CSV and JSON files with processed data
2. **Visualizations**: Saved charts and plots from analysis
3. **Models**: Trained machine learning models for later use
4. **Reports**: Generated reports and summaries

## Usage

To export data from a notebook to this directory:

```python
# Save a DataFrame
df.to_csv('/notebooks/exports/my_data.csv')

# Save a figure
plt.savefig('/notebooks/exports/my_figure.png')

# Save a model
import joblib
joblib.dump(model, '/notebooks/exports/my_model.joblib')
```

To use these exports in other project components:

```python
# In the ML service
import pandas as pd
import joblib

# Load data
df = pd.read_csv('/app/notebooks/exports/my_data.csv')

# Load a model
model = joblib.load('/app/notebooks/exports/my_model.joblib')
```

## Best Practices

1. **Use descriptive filenames** with dates for versioning
2. **Include metadata** in your exports (column descriptions, model parameters)
3. **Document your exports** in your notebooks
4. **Clean up old exports** that are no longer needed

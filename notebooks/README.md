# CodexContinue Notebooks

This directory contains Jupyter notebooks for data exploration, model development, and research for the CodexContinue project.

## Usage

These notebooks can be accessed through the Jupyter Lab instance that runs as part of the development container.
When the development container is running, Jupyter Lab is available at:

http://localhost:8888

You can also use the provided script to launch Jupyter Lab:

```bash
./scripts/launch-jupyter.sh
```

## Contents

- `demo.ipynb`: A demo notebook that demonstrates basic functionality and connectivity
- `data_analysis.ipynb`: A comprehensive data analysis notebook with visualization and ML examples
- Add more notebooks as they are created

## Tips

- All notebooks have access to the same Python environment as the ML service
- You can access project code and modules from the notebooks by importing from the project's Python modules
- Notebooks are a great way to prototype functionality before incorporating it into the main codebase

## Running Code from Notebooks

To import project modules from notebooks, add the project root to your Python path:

```python
import sys
import os

# Add the project root to Python path
project_root = '/app'
if project_root not in sys.path:
    sys.path.append(project_root)

# Now you can import project modules
# For example:
# from ml import some_module
```

## Exporting Results

You can export results from your notebooks to the `exports` directory, which is accessible from both inside the container and on your local machine:

```python
# Save a DataFrame to CSV
df.to_csv('/notebooks/exports/my_results.csv')

# Save a figure
plt.savefig('/notebooks/exports/my_figure.png')
```

## Troubleshooting

If you encounter issues with the Jupyter environment:

1. Verify the Jupyter container is running:
   ```bash
   ./scripts/verify-jupyter.sh
   ```

2. Restart the Jupyter container:
   ```bash
   docker compose restart jupyter
   ```

3. Check the container logs:
   ```bash
   docker logs codexcontinue-jupyter
   ```

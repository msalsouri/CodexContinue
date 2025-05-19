#!/usr/bin/env python3
# create_data_analysis_notebook.py - Create a simple data analysis notebook for JupyterLab

notebook = {
    "cells": [
        {
            "cell_type": "markdown",
            "metadata": {},
            "source": ["# CodexContinue Data Analysis\n", "\n", "This notebook demonstrates how to analyze and visualize data from the CodexContinue project."]
        },
        {
            "cell_type": "code",
            "execution_count": None,
            "metadata": {},
            "outputs": [],
            "source": [
                "# Import required libraries\n",
                "import numpy as np\n",
                "import pandas as pd\n",
                "import matplotlib.pyplot as plt\n",
                "import seaborn as sns\n",
                "import plotly.express as px\n",
                "import sys\n",
                "import os\n",
                "\n",
                "# Set up plotting styles\n",
                "%matplotlib inline\n",
                "plt.style.use('seaborn-v0_8-whitegrid')\n",
                "sns.set_style(\"whitegrid\")\n",
                "plt.rcParams['figure.figsize'] = (12, 8)\n",
                "plt.rcParams['font.size'] = 12\n",
                "\n",
                "print(\"Libraries imported successfully!\")"
            ]
        },
        {
            "cell_type": "markdown",
            "metadata": {},
            "source": ["## Connect to Project Environment\n", "\n", "Let's ensure we have access to the CodexContinue project modules:"]
        },
        {
            "cell_type": "code",
            "execution_count": None,
            "metadata": {},
            "outputs": [],
            "source": [
                "# Add the project root to Python path to access project modules\n",
                "project_root = '/app'\n",
                "if project_root not in sys.path:\n",
                "    sys.path.append(project_root)\n",
                "\n",
                "# List available modules in the project\n",
                "print(\"Available directories in the project:\")\n",
                "for item in os.listdir(project_root):\n",
                "    if os.path.isdir(os.path.join(project_root, item)) and not item.startswith('.'):\n",
                "        print(f\"- {item}\")"
            ]
        },
        {
            "cell_type": "markdown",
            "metadata": {},
            "source": ["## Simulated Data Generation\n", "\n", "For demonstration purposes, we'll generate simulated data that represents user interactions with the CodexContinue system. In a real scenario, you would load this data from a database or API."]
        },
        {
            "cell_type": "code",
            "execution_count": None,
            "metadata": {},
            "outputs": [],
            "source": [
                "# Create a timestamp range for our simulated data\n",
                "import datetime as dt\n",
                "\n",
                "# Generate dates for the past 30 days\n",
                "end_date = dt.datetime.now()\n",
                "start_date = end_date - dt.timedelta(days=30)\n",
                "dates = pd.date_range(start=start_date, end=end_date, freq='H')\n",
                "\n",
                "# Create simulated user activity data\n",
                "np.random.seed(42)  # For reproducibility\n",
                "\n",
                "# Generate random user IDs (100 users)\n",
                "user_ids = [f\"user_{i:03d}\" for i in range(1, 101)]\n",
                "\n",
                "# Create a DataFrame with simulated user activities\n",
                "n_samples = 5000\n",
                "data = {\n",
                "    'timestamp': np.random.choice(dates, n_samples),\n",
                "    'user_id': np.random.choice(user_ids, n_samples),\n",
                "    'action': np.random.choice(['query', 'document_view', 'code_generation', 'code_execution', 'system_config'], n_samples, \n",
                "                            p=[0.4, 0.2, 0.2, 0.15, 0.05]),\n",
                "    'duration_seconds': np.random.exponential(scale=60, size=n_samples),\n",
                "    'success': np.random.choice([True, False], n_samples, p=[0.9, 0.1])\n",
                "}\n",
                "\n",
                "# Create the DataFrame\n",
                "activity_df = pd.DataFrame(data)\n",
                "activity_df['date'] = activity_df['timestamp'].dt.date\n",
                "\n",
                "# Display the first few rows\n",
                "activity_df.head()"
            ]
        },
        {
            "cell_type": "markdown",
            "metadata": {},
            "source": ["## Data Overview and Basic Statistics\n", "\n", "Let's explore the dataset to understand its structure and basic statistics:"]
        }
    ],
    "metadata": {
        "kernelspec": {
            "display_name": "Python 3",
            "language": "python",
            "name": "python3"
        },
        "language_info": {
            "codemirror_mode": {
                "name": "ipython",
                "version": 3
            },
            "file_extension": ".py",
            "mimetype": "text/x-python",
            "name": "python",
            "nbconvert_exporter": "python",
            "pygments_lexer": "ipython3",
            "version": "3.10.0"
        }
    },
    "nbformat": 4,
    "nbformat_minor": 4
}

import json
import sys

with open("data_analysis.ipynb", "w") as f:
    json.dump(notebook, f, indent=2)

print("Created data_analysis.ipynb")

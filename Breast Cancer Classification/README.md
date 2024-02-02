# Breast Cancer Classification Project

## Project Purpose

The primary objective of this project was to develop a machine learning model capable of accurately classifying breast cancer tumors into malignant or benign categories, using the Breast Cancer Wisconsin (Diagnostic) dataset. This dataset includes various measurements related to the characteristics of breast cancer cell nuclei.

## Data Preprocessing

- Loaded the dataset into a pandas DataFrame, combining features and the target variable.
- Named columns appropriately based on the dataset's feature names, adding a 'target' column for the classification outcome.

## Exploratory Data Analysis (EDA)

- Utilized pair plots for selected features ('mean radius', 'mean texture', 'mean perimeter', 'mean area', 'mean smoothness') against themselves, colored by 'target', to visualize distribution differences between malignant and benign tumors.
- Created a count plot for the target variable to examine the balance between malignant and benign samples.
- Generated a scatter plot for 'mean area' vs. 'mean smoothness', colored by 'target', to explore feature relationships.
- Plotted a heatmap of the correlation matrix to identify significant feature correlations.

## Data Preparation for Modeling

- Separated the dataset into X (features) and y (target), with 'target' indicating the cancer outcome.

## Feature Scaling

- Applied feature scaling to normalize the data, ensuring uniform influence on the model.

## Model Selection and Training

- Chose an SVC (Support Vector Classifier) model for its suitability in binary classification tasks.
- Trained the model on the scaled training data.

## Model Evaluation

- Used a confusion matrix for initial model performance assessment.

## Parameter Tuning and Optimization

- Employed GridSearchCV for finding optimal SVC parameters (C, gamma, kernel).
- The optimized model showed improved performance, with significant accuracy in classifying tumors.

## Conclusions and Insights

- EDA provided valuable insights into feature distributions and their impact on cancer classification.
- Feature scaling and parameter optimization were crucial in enhancing the SVC model's performance.
- The project underscores the importance of hyperparameter optimization in developing effective machine learning models.

## Tools Used

- Pandas for data manipulation
- Matplotlib and Seaborn for data visualization
- Scikit-learn for model development, including feature scaling, model training, and hyperparameter optimization

## Key Findings

- The optimized SVC model demonstrated high accuracy in distinguishing between malignant and benign tumors, as evidenced by the confusion matrix results.
- Hyperparameter optimization significantly contributed to the model's performance, underscoring its importance in machine learning workflows.

# Fintech App User Enrollment Prediction

## Project Objective

The primary objective of this project is to assist a fintech company in identifying users of its free mobile app version who are least likely to enroll in the paid subscription. By pinpointing these users, the company aims to target them with additional offers to encourage enrollment. This strategy is essential to optimize marketing efforts and reduce costs by avoiding offering promotions to users who are likely to convert without incentives.

## Methodology

1. Data Cleaning: The dataset undergoes initial cleaning, including parsing dates and adjusting the format of the hour column for consistency.
2. Exploratory Data Analysis (EDA): Histograms of numerical columns and a correlation matrix are generated to understand the data's distribution and the relationship between different variables.
3. Feature Engineering: New features are created by parsing screen list data into binary columns for each top screen viewed and aggregating related screens to reduce multicollinearity. A cutoff point for enrollment based on the time difference between first app open and enrollment date is also established.
4. Model Preparation: The dataset is split into training and testing sets, and feature scaling is applied to normalize the data.
5. Model Training: A logistic regression model with L1 regularization (to handle potential multicollinearity among features) is trained on the dataset.
6. Evaluation: The model's performance is assessed using cross-validation, focusing on the accuracy of predicting user enrollment.

## Tools Used
- **Python**: The primary programming language used for data cleaning, analysis, and model training.
- **Pandas & NumPy**: For data manipulation and numerical computations.
- **Matplotlib & Seaborn**: For data visualization, including histograms, bar plots, and heatmaps.
- **Scikit-learn**: For logistic regression modeling, feature scaling, and model evaluation.
- **Dateutil**: For parsing date and time data.

## Key Findings

- **User Behavior Insights**: Initial EDA revealed specific patterns in user behavior, such as the significant role of certain screens and user interactions within the first 48 hours after app download in predicting enrollment.
- **Model Performance**: The logistic regression model, with an accuracy of approximately 76.9%, demonstrates a reasonable ability to predict user enrollment based on app usage patterns and demographics.
- **Feature Importance**: The regularization applied in the logistic regression model highlighted the importance of certain features over others, enabling the identification of key factors influencing the likelihood of enrolling in the paid subscription.

## Conclusion

This project highlights the potential of data-driven approaches in enhancing marketing strategies for fintech products. By leveraging user interaction data and machine learning techniques, the company can more effectively target its marketing efforts, encouraging greater conversion rates to its paid subscription service. Future work could explore more complex models or deeper insights into user behavior to further refine prediction accuracy.

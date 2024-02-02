# YouTube Sentiment and Engagement Analysis Project

## Project Objective

The goal of this project is to analyze YouTube comments and video engagement metrics across different categories to understand viewer sentiment, the prevalence of emoji usage, and how engagement varies by category.

## Methodology

### Data Importing and Cleaning

- **Data Source**: YouTube comments and engagement metrics are imported from CSV files.
- **Cleaning Process**: Rows with missing values are dropped to ensure data quality.
- **Data Consolidation**: Multiple CSV files from a directory are concatenated into a single DataFrame for comprehensive analysis.

### Sentiment Analysis

- **Tool Used**: TextBlob is utilized to determine the polarity of each comment, indicating its sentiment as positive, negative, or neutral.
- **Analysis**: Comments are categorized into positive and negative groups based on their polarity scores.
- **Visualization**: Word clouds are generated for both positive and negative comments to highlight the frequency of word occurrences visually.

### Emoji Analysis

- **Emoji Frequency**: Comments are analyzed for emoji usage, and frequencies are calculated.
- **Visualization**: A bar chart is created to showcase the top 10 most common emojis found in the comments.

### Category Analysis

- **Category Mapping**: A JSON file is parsed to map category IDs to their names, facilitating easier identification.
- **Data Merging**: This mapping is converted into a DataFrame and merged with the main DataFrame to label each video by its category name.

### Engagement Metrics Visualization

- **Engagement Comparison**: Boxplots are used to compare the distribution of likes across different video categories.
- **Engagement Rate Calculation**: Metrics like the rate of likes, dislikes, and comments relative to the number of views are calculated.
- **Visualization**: Both boxplots and regression plots are used to visualize these metrics, and a heatmap is created to illustrate the correlation between views, likes, and dislikes.

## Key Findings

- Sentiment analysis revealed distinct word usage patterns in positive and negative comments, as visualized in the word clouds.
- Emoji analysis highlighted the most prevalent emojis, indicating a trend in viewer expression.
- Category analysis showed variations in engagement metrics across different YouTube categories, suggesting that viewer interaction varies significantly by content type.
- The correlation heatmap provided insights into the relationship between views, likes, and dislikes, indicating potential factors that drive engagement on YouTube.

## Tools Used

- **TextBlob** for sentiment analysis.
- **Pandas** for data manipulation and analysis.
- **Matplotlib** and **Seaborn** for data visualization.
- **JSON** for parsing category mapping data.

This project provides valuable insights into YouTube video engagement and viewer sentiment, offering a comprehensive look at how different factors influence viewer interaction across various content categories.

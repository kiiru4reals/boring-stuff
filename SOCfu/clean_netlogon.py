import pandas as pd

# Prompt user to enter the file paths for the two CSV files
file1_path = input("Enter the path to the first CSV file (e.g., file1.csv): ")
file2_path = input("Enter the path to the second CSV file (e.g., file2.csv): ")

# Define the output filename
output_file = "merged_output.csv"

# Read the CSV files into pandas DataFrames
try:
    df1 = pd.read_csv(file1_path)
    df2 = pd.read_csv(file2_path)
except FileNotFoundError as e:
    print(f"Error: {e}")
    exit(1)
except pd.errors.EmptyDataError:
    print("Error: One or both of the files are empty.")
    exit(1)
except pd.errors.ParserError:
    print("Error: Failed to parse one of the files. Please check the CSV format.")
    exit(1)

# Check if required columns exist
required_columns_file1 = ['computer_name', 'count']
required_columns_file2 = ['srcname', 'unauthuser', 'srcip']

if not all(col in df1.columns for col in required_columns_file1):
    print(f"Error: One or more of the required columns {required_columns_file1} are missing in {file1_path}.")
    exit(1)

if not all(col in df2.columns for col in required_columns_file2):
    print(f"Error: One or more of the required columns {required_columns_file2} are missing in {file2_path}.")
    exit(1)

# Merge the DataFrames based on computer_name/srcname
merged_df = pd.merge(df1, df2, left_on='computer_name', right_on='srcname', how='left')

# Keep only the necessary columns
merged_df = merged_df[['computer_name', 'count', 'unauthuser', 'srcip']]

# Save the merged DataFrame to a new CSV file
merged_df.to_csv(output_file, index=False)

print(f"Merging complete. Output saved to {output_file}.")

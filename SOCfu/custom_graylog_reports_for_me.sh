#!/bin/bash

compute_number_of_unique_urls_visited_by_users_in_the_network(){


    # Prompt the user for the input file path
    read -p "Enter the path to the input CSV file (URLs being visited): " input_file

    # Check if the input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Input file not found!"
        exit 1
    fi

    echo "====================== Creating output file ============================"
    # Get the current date in dd_mm_yyyy format
    current_date=$(date +%d_%m_%Y)

    # Define the output file name with the date appended
    output_file="clean_firewall_report_of_all_urls_visited_on_${current_date}.csv"

    # Define temporary files
    temp_file="temp_urls.csv"
    sorted_file="sorted_urls.csv"

    # Count unique URLs and create the 'count' column
    awk -F, 'NR==1{next} {url_count[$3]++} END {for (url in url_count) print "", url, url_count[url]}' OFS=, "$input_file" > "$temp_file"

    # Add headers to the cleaned data
    sed -i '1s/^/timestamp,url,count\n/' "$temp_file"

    # Sort the data by the 'count' column (3rd column) in descending order
    sort -t, -k3,3nr "$temp_file" > "$sorted_file"

    # Save the sorted data to the final output file
    mv "$sorted_file" "$output_file"

    # Clean up temporary files
    rm "$temp_file"

    echo "Processed file saved as $output_file"

}

create_report_with_active_users_on_the_network(){

    # Prompt the user for the input file path
    read -p "Enter the path to the input CSV file (active_users_report): " most_active_users_report

    # Check if the input file exists
    if [[ ! -f "$most_active_users_report" ]]; then
        echo "Input file not found!"
        exit 1
    fi

    # Get the current date in dd_mm_yyyy format
    current_date=$(date +%d_%m_%Y)

    # Define the output file name with the date appended
    output_file="clean_firewall_report_of_active_users_${current_date}.csv"

    # Define temporary files
    temp_file="temp_cleaned.csv"
    unique_users_file="unique_users.csv"

    # Remove rows with empty 'unauthuser' column and count occurrences
    awk -F, 'NR==1{print "unauthuser,count"; next} $3 != "" {user_count[$3]++} END {for (user in user_count) print user, user_count[user]}' OFS=, "$most_active_users_report" > "$unique_users_file"

    # Sort the unique users by the 'count' column in descending order
    sort -t, -k2,2nr "$unique_users_file" > "$output_file"

    # Clean up temporary files
    rm "$unique_users_file"

    echo "Processed file saved as $output_file"

}

what_services_are_our_users_interacting_with(){

    # Prompt the user for the input file path
    read -p "Enter the path to the input CSV file: (what services are our users interacting with) " input_csv

    # Check if the input file exists
    if [[ ! -f "$input_csv" ]]; then
        echo "Input file not found!"
        exit 1
    fi

    # Get the current date in dd_mm_yyyy format
    current_date=$(date +%d_%m_%Y)

    # Define the output file name with the date appended
    output_file="cleaned_services_report_of_accessed_services_${current_date}.csv"

    # Define temporary files
    unique_services_file="unique_services.csv"

    # Remove 'unauthuser' and 'srcip' columns, and count occurrences of unique 'appcat'
    awk -F, 'NR==1{next} {service_count[$2]++} END {for (service in service_count) print service, service_count[service]}' OFS=, "$input_csv" > "$unique_services_file"

    # Sort the unique services by the 'count' column in descending order and add the header
    { echo "appcat,count"; sort -t, -k2,2nr "$unique_services_file"; } > "$output_file"

    # Clean up temporary files
    rm "$unique_services_file"

    echo "Processed file saved as $output_file"
}

what_platforms_are_people_visiting_on_the_internet(){

    # Prompt the user for the input file path
    read -p "Enter the path to the input CSV file for application categories: " input_file

    # Check if the input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Input file not found!"
        exit 1
    fi

    # Get the current date in dd_mm_yyyy format
    current_date=$(date +%d_%m_%Y)

    # Define the output file name with the date appended
    output_file="clean_report_on_categories_visited_${current_date}.csv"

    # Define a temporary file for intermediate data
    temp_file_appcat="temp_appcat.csv"

    # Remove the 'unauthuser' and 'srcip' columns, aggregate 'appcat', and count occurrences
    awk -F, 'NR==1{next} {appcat_count[$2]++} END {for (appcat in appcat_count) print appcat, appcat_count[appcat]}' OFS=, "$input_file" > "$temp_file_appcat"

    # Add headers to the cleaned data
    sed -i '1s/^/appcat,count\n/' "$temp_file_appcat"

    # Append the cleaned data to the final output file under the 'Application categories visited in the network' section
    {
    echo ""
    echo "Application categories visited in the network,"
    cat "$temp_file_appcat"
    } >> "$output_file"

    # Clean up temporary files
    rm "$temp_file_appcat"

    echo "Processed file saved as $output_file"

}

create_excel_file_from_csvs(){

    # Prompt the user for the input files and output Excel file name
    read -p "Enter the path for the output Excel file: " output_excel

    # Ensure we have the csvkit installed
    if ! command -v csvstack &> /dev/null || ! command -v csvsql &> /dev/null; then
        echo "csvkit is required but not installed. Please install it using 'pip install csvkit'."
        exit 1
    fi

    # Define the output Excel file name
    output_excel="${output_excel}.xlsx"

    # Combine all CSVs into one Excel file with separate sheets
    csvsql --query "
        SELECT 'urls' AS sheet, * FROM clean_firewall_report_of_all_urls_visited_on_*.csv
        UNION ALL
        SELECT 'active_users' AS sheet, * FROM clean_firewall_report_of_active_users_*.csv
        UNION ALL
        SELECT 'services' AS sheet, * FROM cleaned_services_report_of_accessed_services_*.csv
        UNION ALL
        SELECT 'appcat' AS sheet, * FROM clean_report_on_categories_visited_*.csv" \
    --no-header-row | csvstack -g "urls,active_users,services,appcat" --prefix '.' --group-by "sheet" | csvsql --query 'SELECT * FROM stdin ORDER BY "sheet"' > "$output_excel"

    echo "Excel file with all reports saved as $output_excel"

}

compute_number_of_unique_urls_visited_by_users_in_the_network
create_report_with_active_users_on_the_network
what_services_are_our_users_interacting_with
what_platforms_are_people_visiting_on_the_internet
create_excel_file_from_csvs
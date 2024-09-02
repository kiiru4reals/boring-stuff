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
    previous_date=$(date -d "yesterday" +%d_%m_%Y)

    # Define the output file name with the date appended
    output_file="clean_firewall_report_of_all_urls_visited_on_${previous_date}.csv"

    # Define temporary files
    temp_file="temp_urls.csv"
    sorted_file="sorted_urls.csv"

    # Count unique URLs and create the 'count' column
    awk -F, 'NR==1{next} {hostname_count[$2]++} END {for (hostname in hostname_count) print "", hostname, hostname_count[hostname]}' OFS=, "$input_file" > "$temp_file"

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

process_vpn_log_report_business_hours(){

    # Prompt the user for the input file path
    read -p "Enter the path to the input CSV file for VPN logs: " input_file

    # Check if the input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Input file not found!"
        exit 1
    fi

    # Get the previous day's date in dd_mm_yyyy format
    previous_date=$(date -d "yesterday" +%d_%m_%Y)

    # Define the output file name with the date appended
    output_file="clean_vpn_log_report_business_hours_${previous_date}.csv"

    # Define a temporary file for intermediate data
    temp_file="temp_vpn.csv"

    # Step 1: Remove rows where xauthuser is 'N/A'
    awk -F, '$8 != "N/A"' "$input_file" > "$temp_file"

    # Step 2: Remove the 'user', 'tunnelip', and 'tunneltype' columns
    awk -F, '{OFS=","; print $1,$2,$3,$7,$8,$9,$10,$11}' "$temp_file" > "${temp_file}_2"

    # Step 3: Count occurrences of each unique xauthuser and create a new 'count' column
    awk -F, '
    NR==1 {print $0,"count"; next}
    {
        xauthuser_count[$4]++;
        data[$4] = $0
    }
    END {
        for (xauthuser in xauthuser_count) {
            print data[xauthuser],xauthuser_count[xauthuser]
        }
    }' "${temp_file}_2" > "${temp_file}_3"

    # Step 4: Sort by the 'count' column in descending order
    (head -n 1 "${temp_file}_3" && tail -n +2 "${temp_file}_3" | sort -t, -k9,9nr) > "$output_file"

    # Clean up temporary files
    rm "$temp_file" "${temp_file}_2" "${temp_file}_3"

    echo "Processed file saved as $output_file"

}

process_vpn_log_report_off_business_hours(){

    # Prompt the user for the input file path
    read -p "Enter the path to the input CSV file for VPN logs: " input_file

    # Check if the input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Input file not found!"
        exit 1
    fi

    # Get the previous day's date in dd_mm_yyyy format
    previous_date=$(date -d "yesterday" +%d_%m_%Y)

    # Define the output file name with the date appended
    output_file="clean_vpn_log_report_off_business_hours_${previous_date}.csv"

    # Define a temporary file for intermediate data
    temp_file="temp_vpn.csv"

    # Step 1: Remove rows where xauthuser is 'N/A'
    awk -F, '$8 != "N/A"' "$input_file" > "$temp_file"

    # Step 2: Remove the 'user', 'tunnelip', and 'tunneltype' columns
    awk -F, '{OFS=","; print $1,$2,$3,$7,$8,$9,$10,$11}' "$temp_file" > "${temp_file}_2"

    # Step 3: Count occurrences of each unique xauthuser and create a new 'count' column
    awk -F, '
    NR==1 {print $0,"count"; next}
    {
        xauthuser_count[$4]++;
        data[$4] = $0
    }
    END {
        for (xauthuser in xauthuser_count) {
            print data[xauthuser],xauthuser_count[xauthuser]
        }
    }' "${temp_file}_2" > "${temp_file}_3"

    # Step 4: Sort by the 'count' column in descending order
    (head -n 1 "${temp_file}_3" && tail -n +2 "${temp_file}_3" | sort -t, -k9,9nr) > "$output_file"

    # Clean up temporary files
    rm "$temp_file" "${temp_file}_2" "${temp_file}_3"

    echo "Processed file saved as $output_file"

}

clean_netlogon_file(){

    # Prompt user to enter the file paths for file1 and file2
    read -p "Enter the path to the Alienvault net logon file: " file1
    read -p "Enter the path to Graylog file with usernames: " file2

    # Define the output filename
    output_file="merged_output.csv"

    # Check if both files exist
    if [[ ! -f "$file1" || ! -f "$file2" ]]; then
        echo "One or both of the files do not exist. Please check the filenames."
        exit 1
    fi

    # Extract headers from file1 and create the output file with additional columns
    header=$(head -n 1 "$file1")
    echo "${header},unauthuser,srcip" > "$output_file"

    # Debugging: Print the header
    echo "Header: $header"

    # Loop through each line in file1 (skipping the header)
    tail -n +2 "$file1" | while IFS=, read -r computer_name count
    do
        # Debugging: Print the current line being processed
        echo "Processing: $computer_name, $count"

        # Find the corresponding line in file2 based on the computer_name/srcname
        match=$(awk -v cn="$computer_name" -F, '$1 == cn {print $2","$3}' "$file2")
        
        # Debugging: Print the match found
        echo "Match found: $match"
        
        # If a match is found, add the unauthuser and srcip to the output file
        if [[ -n "$match" ]]; then
            echo "${computer_name},${count},${match}" >> "$output_file"
        else
            # If no match is found, just add the computer_name and count to the output file
            echo "${computer_name},${count},," >> "$output_file"
        fi
    done

    echo "Merging complete. Output saved to $output_file."


}
compute_number_of_unique_urls_visited_by_users_in_the_network
# create_report_with_active_users_on_the_network
# what_services_are_our_users_interacting_with
# what_platforms_are_people_visiting_on_the_internet
# create_excel_file_from_csvs
process_vpn_log_report_business_hours
process_vpn_log_report_off_business_hours
clean_netlogon_file
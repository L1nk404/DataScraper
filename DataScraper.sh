#!/bin/bash

#######################################################
#  ___  ____ ____ _ ____ _  _ ____ ___     ___  _   _ #
#  |  \ |___ [__  | | __ |\ | |___ |  \    |__]  \_/  #
#  |__/ |___ ___] | |__] | \| |___ |__/    |__]   |   #
#                                                     #                                                   
#  _    _ _  _ _  _  ____ _  _ ____                   #
#  |    | |\ | |_/   |___  \/  |___                   #
#  |___ | | \| | \_ .|___ _/\_ |___                   #
#######################################################                           

# Please don't remove the credits

red="\033[31;1m"
green="\033[32;1m"
yellow="\033[33;1m"
cyan="\033[36;1m"
reset="\033[m"
bold="\033[1m"

BANNER="
        ██████╗  █████╗ ████████╗ █████╗                
        ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗               
        ██║  ██║███████║   ██║   ███████║               
        ██║  ██║██╔══██║   ██║   ██╔══██║               
        ██████╔╝██║  ██║   ██║   ██║  ██║               
        ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝               
                                                        
███████╗ ██████╗██████╗  █████╗ ██████╗ ███████╗██████╗ 
██╔════╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
███████╗██║     ██████╔╝███████║██████╔╝█████╗  ██████╔╝
╚════██║██║     ██╔══██╗██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗
███████║╚██████╗██║  ██║██║  ██║██║     ███████╗██║  ██║
╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝                                                    
"

echo -n -e "${cyan}${BANNER}${reset}\\n\\n"

# Function to display a progress bar
progress_bar() {
    local progress=$1
    local total=$2
    local width=50  # Width of the progress bar
    local completed=$(( (progress * width) / total ))
    local remaining=$(( width - completed ))

    # Print the progress bar
    printf "\r["
    printf "%0.s#" $(seq 1 $completed)
    printf "%0.s-" $(seq 1 $remaining)
    printf "] %d%%" $(( (progress * 100) / total ))
}

# Function to fetch files
get_files()
{
    search_query=site:$1+ext:$2

    # Creates a directorie if it doesn't exist
    mkdir -p cache 2> /dev/null

    # Dump the search result and extract URLs
    lynx --dump "https://google.com/search?&q=$search_query" | grep "\.pdf" | cut -d "=" -f 2 > cache/url.txt


    # Cheking if the file is not empty
    if [ -s cache/url.txt ]; then  # if not empty
        total_urls=$(wc -l < cache/url.txt)
        current_url=0

        echo -e "\\n${bold}${green}[>>] Downloading files...${reset}\\n"

        if [ "$3" = "-v" ]; then  # checks if verbose option is enabled
        {
            for url in $(cat cache/url.txt); do
                wget "$url" -P cache > cache/log.txt
                current_url=$((current_url + 1))
                progress_bar "$current_url" "$total_urls"
            done
        }
        else
        {
            for url in $(cat cache/url.txt); do
                wget "$url" -P cache 2> cache/log.txt  # Download files
                current_url=$((current_url + 1))
                progress_bar "$current_url" "$total_urls"
            done
        }
        fi
        # delete url.txt
        rm cache/url.txt   

        echo -e "\\n\\n${bold}${green}Done!${reset}\\n"
        echo
    else # if empty
        echo -e "${bold}${red}[!!] Can't find $2 files [!!]${reset}"        

        # delete url.txt
        rm cache/url.txt 
        exit 0
    fi

}

# Function for take metadata from files

get_metadata()
{
    directory=cache

    for file in "$directory"/*; do
        filename=$(basename "$file")  # get filename
        
        echo "======================================"
        echo -e "${bold}${green}[>>]${reset} ${filename}\\n"
        exiftool "${file}"
        echo
        echo
    done
}

main_function()
{
    get_files "$@"

    while true; do
    echo -e -n "${yellow}[?]${reset} Show metadata? [y/n] "
    read -r input

    # first input handle
    case "${input}" in
        y|Y)
            get_metadata
            break
        ;;
        n|N)
            break
        ;;
        *)
            continue        
    esac

    done

    while true; do
    echo -e -n "${red}${bold}[?] Delete files? [y/n] "
    read -r input

    #second input handle
    case "${input}" in
        y|Y)
            rm -rf cache
            break
        ;;
        n|N)
            break
        ;;
        *)
            continue        
    esac

    done
}

# Function to display the usage message
display_usage() {
    self=$(basename "$0")
    cat << EOF
${self} - A script to fetch and process file metadata.

Dependencies:
  exiftool    - to install, run "\$sudo apt install exiftool"
  lynx        - to install, run "\$sudo apt install lynx"

Usage:
  ${self} <target url>* <file extension>* [options]

Mandatory arguments:
  <target url>       The URL to search within.
  <file extension>   The file extension to search for (e.g., pdf, txt).

Options:
  -v                 Enable verbose mode.
  -h                 Show this help message and exit.

Description:
  This script searches for files with the specified extension within the given target URL
  and downloads them. The downloaded files are saved in the 'cache' directory.
  A progress bar is displayed during the download process.

  Verbose mode can be enabled using the -v option. When enabled, you can see the download 
  details. Also is a detailed log informationsaved in cache/log.txt. Do not delete this 
  file if you need to review the logs.

Examples:
  ${self} example.com pdf
  ${self} example.org txt -v

Notes:
  Ensure the 'cache' directory is not deleted manually if you want to review the files.

EOF
}

###########

if [ "$1" = "-h" ]; then
{
    display_usage    
    exit 0
}
elif [ -z "$1" ] || [ -z "$2" ]; then
{
    display_usage
    exit 1
}
else
{
    main_function "$@"
    exit 0
}
fi
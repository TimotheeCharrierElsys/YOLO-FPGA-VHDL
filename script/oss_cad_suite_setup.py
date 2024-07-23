import requests
from bs4 import BeautifulSoup
import re
import os
import tarfile
import sys

def get_latest_release_url(base_url):
    # Fetch the page content
    response = requests.get(base_url)
    response.raise_for_status()  # Raise an error for bad responses

    # Parse the HTML
    soup = BeautifulSoup(response.text, 'html.parser')

    # Find the release tag URL
    release_tag = soup.find('a', {'href': re.compile(r'/releases/tag/\d{4}-\d{2}-\d{2}')})
    if not release_tag:
        raise Exception("Could not find the release tag link")

    release_url = 'https://github.com' + release_tag['href']
    
    # Extract the date from the release tag URL
    date_match = re.search(r'(\d{4}-\d{2}-\d{2})', release_tag['href'])
    if not date_match:
        raise Exception("Could not extract date from the release tag URL")
    
    release_date = date_match.group(1)
    tgz_filename = f'oss-cad-suite-linux-x64-{release_date.replace("-", "")}.tgz'
    
    # Construct the download URL
    download_url = f'https://github.com/YosysHQ/oss-cad-suite-build/releases/download/{release_date}/{tgz_filename}'
    
    return download_url, tgz_filename

def download_file(url, local_filename):
    response = requests.get(url, stream=True)
    response.raise_for_status()  # Raise an error for bad responses

    total_size = int(response.headers.get('content-length', 0))
    chunk_size = 8192
    num_chunks = (total_size // chunk_size) + 1

    print(f"Downloading {local_filename} ({total_size / 1024:.2f} KB)")

    with open(local_filename, 'wb') as f:
        for i, chunk in enumerate(response.iter_content(chunk_size=chunk_size)):
            if chunk:
                f.write(chunk)
                # Print progress
                progress = (i + 1) / num_chunks * 100
                sys.stdout.write(f"\rProgress: {progress:.2f}%")
                sys.stdout.flush()
    
    print("\nDownload complete!")

def extract_and_cleanup(tgz_file, extract_dir):
    print("\Extracting File!")
    # Extract the tar.gz file
    with tarfile.open(tgz_file, "r:gz") as tar:
        tar.extractall(path=extract_dir)
    print(f"Extracted {tgz_file} to {extract_dir}")
    
    # Remove the tar.gz file
    os.remove(tgz_file)
    print(f"Removed {tgz_file}")

def main():
    base_url = 'https://github.com/YosysHQ/oss-cad-suite-build/releases'
    
    # Define the installation path as ~/Utils/
    home_directory = os.path.expanduser('~')
    installation_path = os.path.join(home_directory, 'Utils')
    
    try:
        download_url, tgz_filename = get_latest_release_url(base_url)
        tgz_filepath = os.path.join(installation_path, tgz_filename)
        
        # Ensure installation directory exists
        os.makedirs(installation_path, exist_ok=True)
        
        download_file(download_url, tgz_filepath)
        extract_and_cleanup(tgz_filepath, installation_path)
        
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    main()

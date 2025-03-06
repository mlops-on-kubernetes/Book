import kagglehub

# Download latest version


def download_dataset():
   path = kagglehub.dataset_download("allen-institute-for-ai/CORD-19-research-challenge")
   print("Path to dataset files:", path)

if __name__ == "__main__":
   
   download_dataset()
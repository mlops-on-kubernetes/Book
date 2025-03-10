# This script is for processing a dataset using PySpark
# It downloads the dataset from Kaggle, processes it, and writes the result to a CSV file

import kaggle
import time
import logging
import sys, os


def download_dataset(dataset):

   logger.info("Downloading the dataset")
   kaggle.api.authenticate()
   path = kaggle.api.dataset_download_files(dataset, path='spark_job/', unzip=True, quiet=False)
   logging.info(f"Dataset downloaded at {path}")
   return path

def process_data(input_file):
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import regexp_replace, col, upper
   from pyspark.sql.types import StructType, StructField, StringType

   logger.info("Processing the data")
   # Create a SparkSession
   spark = SparkSession.builder.appName("MediDrugProcessing").getOrCreate()

   if not os.path.exists(input_file):
       logger.info("Dataset not found. Downloading the dataset")
       download_dataset(dataset)


   while True:
      time.sleep(10)
   # Read the CSV file
   df = spark.read.csv(input_file, header=True)
   print(df.show())

   this_column = "Job Description"
   

   start_time = time.time()
   df = df.withColumn(this_column, upper(col(this_column)))
   end_time = time.time()

   execution_time = end_time - start_time
   print(f"Spark execution time: {execution_time:.2f} seconds")


   # Write the result to a CSV file
   #df.write.csv("spark_job/", header=True, mode="overwrite")
   df.coalesce(1).write.csv("spark_job/output/result.csv", header=True, mode="overwrite")

   # Stop the SparkSession
   spark.stop()

if __name__ == "__main__":

   dataset = "allen-institute-for-ai/CORD-19-research-challenge"
   dataset = "ravindrasinghrana/job-description-dataset"
   input_file = 'spark_job/job_descriptions.csv'


   logger = logging.getLogger()
   logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
   logger.setLevel(logging.INFO)

   logger.info("Starting the Spark job")
   

   start_time = time.time()
   process_data(input_file)
   end_time = time.time()

   execution_time = end_time - start_time
   print(f"Execution time: {execution_time:.2f} seconds")

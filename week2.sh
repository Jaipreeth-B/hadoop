#!/bin/bash

# Prerequisites: Ensure Hadoop services are running
start-dfs.sh
start-yarn.sh

# Step 1: Create a directory in HDFS
echo "--- Step 1: Creating /cse directory in HDFS ---"
hdfs dfs -mkdir /cse
echo "Verifying root directory:"
hdfs dfs -ls /

# Create a local test file so 'put' command succeeds
echo "Hello Hadoop HDFS File Management" > example.txt

# Step 2: Copy file from local file system to HDFS
echo "--- Step 2: Copying example.txt to /cse ---"
hdfs dfs -put example.txt /cse
echo "Verifying /cse directory:"
hdfs dfs -ls /cse

# Step 3: View the file content in HDFS
echo "--- Step 3: Reading /cse/example.txt from HDFS ---"
hdfs dfs -cat /cse/example.txt

# Step 4: Retrieve file from HDFS to local system
echo "--- Step 4: Retrieving /cse/example.txt to local directory ---"
hdfs dfs -get /cse/example.txt fetched_example.txt

# Step 5: Delete file from HDFS
echo "--- Step 5: Deleting /cse/example.txt ---"
hdfs dfs -rm /cse/example.txt

# Step 6: Delete directory from HDFS
echo "--- Step 6: Deleting /cse directory ---"
hdfs dfs -rmdir /cse

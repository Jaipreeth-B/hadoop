#!/bin/bash
set -e

# Load Hadoop Environment
if [ -f /etc/profile.d/hadoop.sh ]; then
    source /etc/profile.d/hadoop.sh
else
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    export HADOOP_HOME=/usr/local/hadoop
    export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
fi

# Ensure SSH service is running (required in WSL)
sudo service ssh start 2>/dev/null || true

# Prerequisites: Ensure Hadoop services are running
echo "--- Checking Hadoop Services ---"
if ! jps | grep -q "NameNode"; then
    echo "Starting DFS services..."
    start-dfs.sh
fi

if ! jps | grep -q "ResourceManager"; then
    echo "Starting YARN services..."
    start-yarn.sh
fi

# Wait for NameNode to exit safemode before writing
echo "Ensuring NameNode is ready..."
hdfs dfsadmin -safemode wait

# Step 1: Create a directory in HDFS
echo "--- Step 1: Creating /cse directory in HDFS ---"
hdfs dfs -rm -r -skipTrash /cse 2>/dev/null || true
hdfs dfs -mkdir -p /cse
echo "Verifying root directory:"
hdfs dfs -ls /

# Create a local test file so 'put' command succeeds
echo "Hello Hadoop HDFS File Management" > example.txt

# Step 2: Copy file from local file system to HDFS
echo "--- Step 2: Copying example.txt to /cse ---"
hdfs dfs -put -f example.txt /cse/
echo "Verifying /cse directory:"
hdfs dfs -ls /cse

# Step 3: View the file content in HDFS
echo "--- Step 3: Reading /cse/example.txt from HDFS ---"
hdfs dfs -cat /cse/example.txt

# Step 4: Retrieve file from HDFS to local system
echo "--- Step 4: Retrieving /cse/example.txt to local directory ---"
rm -f fetched_example.txt
hdfs dfs -get /cse/example.txt fetched_example.txt
echo "Local fetched file content:"
cat fetched_example.txt

# Step 5: Delete file from HDFS
echo "--- Step 5: Deleting /cse/example.txt ---"
hdfs dfs -rm /cse/example.txt

# Step 6: Delete directory from HDFS
echo "--- Step 6: Deleting /cse directory ---"
hdfs dfs -rmdir /cse

echo "=========================================="
echo "HDFS File operations completed successfully!"
echo "=========================================="

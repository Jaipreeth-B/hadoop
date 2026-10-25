#!/bin/bash
set -e

# ==========================================
# Additional Program 2: Top 10 Hashtags
# ==========================================

# 1. Load Hadoop Environment
if [ -f /etc/profile.d/hadoop.sh ]; then
    source /etc/profile.d/hadoop.sh
else
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    export HADOOP_HOME=/usr/local/hadoop
    export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
fi

# 2. Ensure SSH is running (for Ubuntu / WSL)
sudo service ssh status >/dev/null 2>&1 || sudo service ssh start 2>/dev/null || true

# 3. Ensure Hadoop services are running
echo "=== Checking Hadoop Services ==="
if ! jps | grep -q "NameNode"; then
    echo "Starting DFS services..."
    start-dfs.sh
fi

if ! jps | grep -q "ResourceManager"; then
    echo "Starting YARN services..."
    start-yarn.sh
fi

# Wait for NameNode to exit safemode
echo "Ensuring NameNode is ready..."
hdfs dfsadmin -safemode wait

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

HADOOP_CLASSPATH=$(hadoop classpath)

# ==========================================
# PROGRAM: TOP 10 HASHTAGS
# ==========================================
echo ""
echo "=========================================="
echo ">>> Executing Additional Program 2: Top 10 Hashtags <<<"
echo "=========================================="

# Create local directories
mkdir -p "$BASE_DIR/build/additional2"
mkdir -p "$BASE_DIR/data"

# Create sample input with tweets / posts containing hashtags
cat << "EOF" > "$BASE_DIR/data/hashtags_input.txt"
Big data is the future #hadoop #bigdata #tech
Learning MapReduce on Apache Hadoop #hadoop #mapreduce #coding
Data engineering with Hadoop and Spark #bigdata #spark #data
Artificial Intelligence and machine learning #ai #ml #tech
Python for data science #python #datascience #coding
Distributed systems with #hadoop #distributed #cloud
Cloud computing and #cloud #devops #tech
Hadoop cluster setup #hadoop #bigdata #linux
Open source technologies #opensource #coding #tech
Machine learning models #ai #ml #python
Deep learning revolution #ai #deeplearning #tech
Data analytics tools #data #analytics #bigdata
BigData processing is fast #bigdata #hadoop #analytics
EOF

echo "--- Compiling Hashtag Java classes ---"
javac -classpath "$HADOOP_CLASSPATH" -d "$BASE_DIR/build/additional2" "$BASE_DIR/additional2/"*.java

echo "--- Packaging Hashtag JAR ---"
jar -cvf "$BASE_DIR/hashtags.jar" -C "$BASE_DIR/build/additional2" .

echo "--- Preparing HDFS Input for Hashtags ---"
hdfs dfs -rm -r -skipTrash /hashtags 2>/dev/null || true
hdfs dfs -mkdir -p /hashtags/input
hdfs dfs -put -f "$BASE_DIR/data/hashtags_input.txt" /hashtags/input/

echo "--- Running Top 10 Hashtags MapReduce Job ---"
hadoop jar "$BASE_DIR/hashtags.jar" org.myorg.HashtagDriver /hashtags/input /hashtags/output

echo ""
echo "=========================================="
echo "Top 10 Hashtags Output in HDFS (/hashtags/output):"
echo "=========================================="
hdfs dfs -cat /hashtags/output/part-*
echo "=========================================="

echo "--- Saving Output to local project folder ---"
rm -f "$BASE_DIR/data/hashtags_output.txt"
hdfs dfs -get /hashtags/output/part-* "$BASE_DIR/data/hashtags_output.txt"
echo "Saved locally to: $BASE_DIR/data/hashtags_output.txt"

echo ""
echo "Additional Program 2: Top 10 Hashtags completed successfully!"

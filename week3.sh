#!/bin/bash
set -e

# ==========================================
# Week 3: MapReduce Word Count
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
if ! jps | grep -q "NameNode" || ! jps | grep -q "DataNode"; then
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
# PROGRAM: WORD COUNT
# ==========================================
echo ""
echo "=========================================="
echo ">>> Executing Week 3: Word Count <<<"
echo "=========================================="

# Create local directories
mkdir -p "$BASE_DIR/build/wordcount"
mkdir -p "$BASE_DIR/data"

# Create sample input for Word Count
cat << "EOF" > "$BASE_DIR/data/wordcount_input.txt"
Hello Hadoop
Hello World
Hello MapReduce
Hadoop is powerful
MapReduce is distributed
Hadoop MapReduce World
EOF

echo "--- Compiling WordCount Java classes ---"
javac -classpath "$HADOOP_CLASSPATH" -d "$BASE_DIR/build/wordcount" "$BASE_DIR/week3/"*.java

echo "--- Packaging WordCount JAR ---"
jar -cvf "$BASE_DIR/wordcount.jar" -C "$BASE_DIR/build/wordcount" .

echo "--- Preparing HDFS Input for WordCount ---"
hdfs dfs -rm -r -skipTrash /wordcount 2>/dev/null || true
hdfs dfs -mkdir -p /wordcount/input
hdfs dfs -put -f "$BASE_DIR/data/wordcount_input.txt" /wordcount/input/

echo "--- Running WordCount MapReduce Job ---"
hadoop jar "$BASE_DIR/wordcount.jar" org.myorg.WordDriver /wordcount/input /wordcount/output

echo ""
echo "=========================================="
echo "WordCount Output in HDFS (/wordcount/output):"
echo "=========================================="
hdfs dfs -cat /wordcount/output/part-*
echo "=========================================="

echo "--- Saving Output to local project folder ---"
rm -f "$BASE_DIR/data/wordcount_output.txt"
hdfs dfs -get /wordcount/output/part-* "$BASE_DIR/data/wordcount_output.txt"
echo "Saved locally to: $BASE_DIR/data/wordcount_output.txt"

echo ""
echo "Week 3 Word Count completed successfully!"

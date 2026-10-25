#!/bin/bash
set -e

# ==========================================
# Week 4: MapReduce Maximum Temperature
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
# PROGRAM: MAXIMUM TEMPERATURE
# ==========================================
echo ""
echo "=========================================="
echo ">>> Executing Week 4: Max Temperature <<<"
echo "=========================================="

# Create local directories
mkdir -p "$BASE_DIR/build/temperature"
mkdir -p "$BASE_DIR/data"

# Create sample input for Max Temperature (Year  Temperature)
cat << "EOF" > "$BASE_DIR/data/temp_input.txt"
1950 25
1950 32
1950 28
1951 35
1951 22
1952 40
1952 38
1953 31
1953 29
EOF

echo "--- Compiling Temp Java classes ---"
javac -classpath "$HADOOP_CLASSPATH" -d "$BASE_DIR/build/temperature" "$BASE_DIR/week4/"*.java

echo "--- Packaging Temp JAR ---"
jar -cvf "$BASE_DIR/maxtemp.jar" -C "$BASE_DIR/build/temperature" .

echo "--- Preparing HDFS Input for Max Temperature ---"
hdfs dfs -rm -r -skipTrash /maxtemp 2>/dev/null || true
hdfs dfs -mkdir -p /maxtemp/input
hdfs dfs -put -f "$BASE_DIR/data/temp_input.txt" /maxtemp/input/

echo "--- Running Max Temperature MapReduce Job ---"
hadoop jar "$BASE_DIR/maxtemp.jar" org.myorg.TempDriver /maxtemp/input /maxtemp/output

echo ""
echo "=========================================="
echo "Max Temperature Output in HDFS (/maxtemp/output):"
echo "=========================================="
hdfs dfs -cat /maxtemp/output/part-*
echo "=========================================="

echo "--- Saving Output to local project folder ---"
rm -f "$BASE_DIR/data/maxtemp_output.txt"
hdfs dfs -get /maxtemp/output/part-* "$BASE_DIR/data/maxtemp_output.txt"
echo "Saved locally to: $BASE_DIR/data/maxtemp_output.txt"

echo ""
echo "Week 4 Max Temperature completed successfully!"

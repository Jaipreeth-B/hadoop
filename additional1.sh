#!/bin/bash
set -e

# ==========================================
# Additional Program 1: Top 10 Movies by Average Rating
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
# PROGRAM: TOP 10 MOVIES
# ==========================================
echo ""
echo "=========================================="
echo ">>> Executing Additional Program 1: Top 10 Movies <<<"
echo "=========================================="

# Create local directories
mkdir -p "$BASE_DIR/build/additional1"
mkdir -p "$BASE_DIR/data"

# Create sample CSV input (userId,movieName,rating)
cat << "EOF" > "$BASE_DIR/data/movies_input.csv"
1,Inception,5
2,Inception,4
3,Avatar,4
4,Avatar,5
5,Interstellar,5
6,Interstellar,5
7,Titanic,3
8,Titanic,4
9,The_Matrix,5
10,The_Matrix,5
11,Gladiator,4
12,Gladiator,4
13,Memento,4
14,Memento,3
15,The_Prestige,5
16,The_Prestige,4
17,Dunkirk,4
18,Dunkirk,3
19,Oppenheimer,5
20,Oppenheimer,5
21,Tenet,3
22,Tenet,4
23,Joker,4
24,Joker,5
25,The_Dark_Knight,5
26,The_Dark_Knight,5
EOF

echo "--- Compiling Movie Java classes ---"
javac -classpath "$HADOOP_CLASSPATH" -d "$BASE_DIR/build/additional1" "$BASE_DIR/additional1/"*.java

echo "--- Packaging Movie JAR ---"
jar -cvf "$BASE_DIR/movies.jar" -C "$BASE_DIR/build/additional1" .

echo "--- Preparing HDFS Input for Movies ---"
hdfs dfs -rm -r -skipTrash /movies 2>/dev/null || true
hdfs dfs -mkdir -p /movies/input
hdfs dfs -put -f "$BASE_DIR/data/movies_input.csv" /movies/input/

echo "--- Running Top 10 Movies MapReduce Job ---"
hadoop jar "$BASE_DIR/movies.jar" org.myorg.MovieDriver /movies/input /movies/output

echo ""
echo "=========================================="
echo "Top 10 Movies Output in HDFS (/movies/output):"
echo "=========================================="
hdfs dfs -cat /movies/output/part-*
echo "=========================================="

echo "--- Saving Output to local project folder ---"
rm -f "$BASE_DIR/data/movies_output.txt"
hdfs dfs -get /movies/output/part-* "$BASE_DIR/data/movies_output.txt"
echo "Saved locally to: $BASE_DIR/data/movies_output.txt"

echo ""
echo "Additional Program 1: Top 10 Movies completed successfully!"

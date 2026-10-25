#!/bin/bash
set -e

# ==========================================
# Week 5: Apache Pig Installation & Operations
# Operations: PROJECT, FILTER, GROUP, JOIN, SORT
# ==========================================
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

CURRENT_USER=$(whoami)
echo "=== Setting up Apache Pig for user: $CURRENT_USER ==="

# 1. Load Hadoop Environment
if [ -f /etc/profile.d/hadoop.sh ]; then
    source /etc/profile.d/hadoop.sh
else
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    export HADOOP_HOME=/usr/local/hadoop
    export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
fi

# 2. Ensure SSH & Hadoop services are running
sudo service ssh status >/dev/null 2>&1 || sudo service ssh start 2>/dev/null || true

echo "=== Checking Hadoop Services ==="
if ! jps | grep -q "NameNode"; then
    echo "Starting DFS services..."
    start-dfs.sh
fi

if ! jps | grep -q "ResourceManager"; then
    echo "Starting YARN services..."
    start-yarn.sh
fi

if ! jps | grep -q "JobHistoryServer"; then
    echo "Starting MapReduce JobHistoryServer (port 10020)..."
    mr-jobhistory-daemon.sh start historyserver 2>/dev/null || mapred --daemon start historyserver 2>/dev/null || true
fi

# Wait for NameNode to exit safemode
hdfs dfsadmin -safemode wait

# 3. Install Apache Pig 0.17.0 if not present
PIG_DIR="/usr/local/pig"
if [ ! -d "$PIG_DIR/bin" ]; then
    echo "=== Installing Apache Pig 0.17.0 ==="
    (
        cd /tmp
        if [ ! -f "pig-0.17.0.tar.gz" ]; then
            echo "Downloading Apache Pig 0.17.0..."
            wget -q --show-progress https://archive.apache.org/dist/pig/pig-0.17.0/pig-0.17.0.tar.gz
        fi
        echo "Extracting Apache Pig..."
        tar -xzf pig-0.17.0.tar.gz
        sudo rm -rf "$PIG_DIR"
        sudo mv pig-0.17.0 "$PIG_DIR"
        sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$PIG_DIR"
    )
fi

# 4. Set Pig Environment Variables
export PIG_HOME="$PIG_DIR"
export PATH=$PATH:$PIG_HOME/bin
export PIG_CLASSPATH=$(hadoop classpath)

# Write to /etc/profile.d/pig.sh for persistence
sudo bash -c "cat << 'EOF' > /etc/profile.d/pig.sh
export PIG_HOME=$PIG_DIR
export PATH=\$PATH:\$PIG_HOME/bin
export PIG_CLASSPATH=\$(hadoop classpath)
EOF"
sudo chmod 644 /etc/profile.d/pig.sh

if ! grep -q "PIG_HOME=" ~/.bashrc; then
    cat << EOF >> ~/.bashrc

# Apache Pig Environment
export PIG_HOME=$PIG_DIR
export PATH=\$PATH:\$PIG_HOME/bin
export PIG_CLASSPATH=\$(hadoop classpath)
EOF
fi

echo "Pig version:"
pig -version | head -n 1 || true

# 5. Prepare Sample Datasets
echo ""
echo "=== Step 5: Preparing Sample Datasets ==="
mkdir -p "$BASE_DIR/data"
mkdir -p "$BASE_DIR/week5"

# Dataset 1: Employees (emp_id, name, dept_id, salary)
cat << "EOF" > "$BASE_DIR/data/employees.csv"
1,Alice,HR,55000
2,Bob,IT,75000
3,Charlie,IT,80000
4,David,Sales,45000
5,Emma,HR,60000
6,Frank,Finance,70000
7,Grace,IT,90000
8,Hannah,Sales,50000
EOF

# Dataset 2: Departments (dept_id, dept_name)
cat << "EOF" > "$BASE_DIR/data/departments.csv"
HR,Human_Resources
IT,Information_Technology
Sales,Sales_and_Marketing
Finance,Finance_and_Accounting
EOF

# 6. Upload Datasets to HDFS
echo "=== Step 6: Uploading Datasets to HDFS ==="
hdfs dfs -rm -r -skipTrash /pig 2>/dev/null || true
hdfs dfs -mkdir -p /pig/input
hdfs dfs -put -f "$BASE_DIR/data/employees.csv" /pig/input/
hdfs dfs -put -f "$BASE_DIR/data/departments.csv" /pig/input/

# 7. Execute Pig Latin Script
echo ""
echo "=========================================="
echo ">>> Executing Pig Latin Operations <<<"
echo "=========================================="

# Run Pig script in MapReduce mode with automatic fallback to local mode if needed
if ! pig -x mapreduce \
    -param EMP_INPUT=/pig/input/employees.csv \
    -param DEPT_INPUT=/pig/input/departments.csv \
    -param OUTPUT_DIR=/pig/output \
    "$BASE_DIR/week5/pig_operations.pig"; then
    
    echo "Notice: Falling back to local execution mode..."
    rm -rf "$BASE_DIR/data/pig_output"
    pig -x local \
        -param EMP_INPUT="$BASE_DIR/data/employees.csv" \
        -param DEPT_INPUT="$BASE_DIR/data/departments.csv" \
        -param OUTPUT_DIR="$BASE_DIR/data/pig_output" \
        "$BASE_DIR/week5/pig_operations.pig"
        
    USE_LOCAL=1
fi

# 8. Display Results
echo ""
echo "=========================================="
echo "1. PROJECT Operation (Name, Salary):"
echo "=========================================="
if [ "$USE_LOCAL" = "1" ]; then
    cat "$BASE_DIR/data/pig_output/projected/part-"*
else
    hdfs dfs -cat /pig/output/projected/part-*
fi

echo ""
echo "=========================================="
echo "2. FILTER Operation (Salary >= 60000):"
echo "=========================================="
if [ "$USE_LOCAL" = "1" ]; then
    cat "$BASE_DIR/data/pig_output/filtered/part-"*
else
    hdfs dfs -cat /pig/output/filtered/part-*
fi

echo ""
echo "=========================================="
echo "3. GROUP Operation (Dept, Employee Count, Avg Salary):"
echo "=========================================="
if [ "$USE_LOCAL" = "1" ]; then
    cat "$BASE_DIR/data/pig_output/grouped/part-"*
else
    hdfs dfs -cat /pig/output/grouped/part-*
fi

echo ""
echo "=========================================="
echo "4. JOIN Operation (Employee with Full Department Name):"
echo "=========================================="
if [ "$USE_LOCAL" = "1" ]; then
    cat "$BASE_DIR/data/pig_output/joined/part-"*
else
    hdfs dfs -cat /pig/output/joined/part-*
fi

echo ""
echo "=========================================="
echo "5. SORT Operation (Ordered by Salary Descending):"
echo "=========================================="
if [ "$USE_LOCAL" = "1" ]; then
    cat "$BASE_DIR/data/pig_output/sorted/part-"*
else
    hdfs dfs -cat /pig/output/sorted/part-*
fi
echo "=========================================="

# 9. Save all results locally into data/pig_output
if [ "$USE_LOCAL" != "1" ]; then
    mkdir -p "$BASE_DIR/data/pig_output"
    hdfs dfs -get -f /pig/output/* "$BASE_DIR/data/pig_output/" 2>/dev/null || true
fi
echo ""
echo "All Pig operation outputs saved locally to: $BASE_DIR/data/pig_output/"
echo "Week 5 Apache Pig completed successfully!"

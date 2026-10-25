#!/bin/bash
set -e

# ==========================================
# Hadoop 3.1.4 Automated Setup (Ubuntu / Linux / WSL)
# ==========================================
CURRENT_USER=$(whoami)
echo "Setting up Hadoop for user: $CURRENT_USER"

# ==========================================
# STEP 1: Install Dependencies (Java 8 & SSH)
# ==========================================
echo "=== Step 1: Installing Java 8 and SSH ==="
sudo apt update -y
sudo apt install openjdk-8-jdk openjdk-8-jre openssh-server -y

# Verify Java
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin
java -version

# ==========================================
# STEP 2: Configure SSH for Passwordless Access
# ==========================================
echo "=== Step 2: Configuring SSH ==="
sudo service ssh status >/dev/null 2>&1 || sudo service ssh start

mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
fi

if ! grep -q -f ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys 2>/dev/null; then
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi
chmod 600 ~/.ssh/authorized_keys

# Pre-populate known_hosts to prevent interactive authenticity prompts
ssh-keyscan -H localhost 127.0.0.1 0.0.0.0 >> ~/.ssh/known_hosts 2>/dev/null || true
chmod 644 ~/.ssh/known_hosts

# Test passwordless SSH
ssh -o BatchMode=yes -o StrictHostKeyChecking=no localhost "echo 'SSH localhost connection successful!'"

# ==========================================
# STEP 3: Install Hadoop 3.1.4
# ==========================================
echo "=== Step 3: Installing Hadoop 3.1.4 ==="
if [ ! -d "/usr/local/hadoop/bin" ]; then
    cd /tmp
    if [ ! -f "hadoop-3.1.4.tar.gz" ]; then
        echo "Downloading Hadoop 3.1.4..."
        wget -q --show-progress https://archive.apache.org/dist/hadoop/common/hadoop-3.1.4/hadoop-3.1.4.tar.gz
    fi
    echo "Extracting Hadoop 3.1.4..."
    tar -xzf hadoop-3.1.4.tar.gz
    sudo rm -rf /usr/local/hadoop
    sudo mv hadoop-3.1.4 /usr/local/hadoop
fi

# Ensure current user owns the Hadoop installation
sudo chown -R "$CURRENT_USER:$CURRENT_USER" /usr/local/hadoop

# ==========================================
# STEP 4: Configure Global & User Environment
# ==========================================
echo "=== Step 4: Configuring Environment Variables ==="
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Write to /etc/profile.d/hadoop.sh (for system-wide access)
sudo bash -c 'cat << "EOF" > /etc/profile.d/hadoop.sh
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
EOF'
sudo chmod 644 /etc/profile.d/hadoop.sh

# Write to ~/.bashrc if not already present
if ! grep -q 'HADOOP_HOME=/usr/local/hadoop' ~/.bashrc; then
    cat << 'EOF' >> ~/.bashrc

# Hadoop Environment Variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
EOF
fi

# ==========================================
# STEP 5: Configure hadoop-env.sh & workers
# ==========================================
echo "=== Step 5: Updating hadoop-env.sh and workers ==="
if ! grep -q "HDFS_NAMENODE_USER" /usr/local/hadoop/etc/hadoop/hadoop-env.sh; then
    cat << EOF >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh

# User and Java configurations for Hadoop
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HDFS_NAMENODE_USER=$CURRENT_USER
export HDFS_DATANODE_USER=$CURRENT_USER
export HDFS_SECONDARYNAMENODE_USER=$CURRENT_USER
export YARN_RESOURCEMANAGER_USER=$CURRENT_USER
export YARN_NODEMANAGER_USER=$CURRENT_USER
EOF
fi

# Set workers file to localhost
echo "localhost" > /usr/local/hadoop/etc/hadoop/workers

# ==========================================
# STEP 6: Configure Hadoop XML Site Files
# ==========================================
echo "=== Step 6: Configuring XML Files ==="

# 6.1 core-site.xml
cat << "EOF" > /usr/local/hadoop/etc/hadoop/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

# 6.2 hdfs-site.xml
mkdir -p /usr/local/hadoop/hdfs/namenode
mkdir -p /usr/local/hadoop/hdfs/datanode

cat << "EOF" > /usr/local/hadoop/etc/hadoop/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///usr/local/hadoop/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///usr/local/hadoop/hdfs/datanode</value>
    </property>
    <property>
        <name>dfs.datanode.hostname</name>
        <value>localhost</value>
    </property>
</configuration>
EOF

# 6.3 mapred-site.xml
cat << "EOF" > /usr/local/hadoop/etc/hadoop/mapred-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
</configuration>
EOF

# 6.4 yarn-site.xml
cat << "EOF" > /usr/local/hadoop/etc/hadoop/yarn-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
    <property>
        <name>yarn.application.classpath</name>
        <value>/usr/local/hadoop/etc/hadoop:/usr/local/hadoop/share/hadoop/common/lib/*:/usr/local/hadoop/share/hadoop/common/*:/usr/local/hadoop/share/hadoop/hdfs:/usr/local/hadoop/share/hadoop/hdfs/lib/*:/usr/local/hadoop/share/hadoop/hdfs/*:/usr/local/hadoop/share/hadoop/mapreduce/lib/*:/usr/local/hadoop/share/hadoop/mapreduce/*:/usr/local/hadoop/share/hadoop/yarn:/usr/local/hadoop/share/hadoop/yarn/lib/*:/usr/local/hadoop/share/hadoop/yarn/*</value>
    </property>
</configuration>
EOF

# ==========================================
# STEP 7: Format NameNode
# ==========================================
echo "=== Step 7: Formatting NameNode ==="
# Stop any running instances first
stop-yarn.sh 2>/dev/null || true
stop-dfs.sh 2>/dev/null || true

# Format NameNode (non-interactive)
/usr/local/hadoop/bin/hdfs namenode -format -force

# ==========================================
# STEP 8: Start Services (DFS and YARN)
# ==========================================
echo "=== Step 8: Starting Hadoop Services ==="
start-dfs.sh
start-yarn.sh

# Wait for NameNode to finish initialization and leave safemode
hdfs dfsadmin -safemode wait

# ==========================================
# STEP 9: Verify Services
# ==========================================
echo "=========================================="
echo "Checking running services with jps:"
echo "=========================================="
jps

echo "=========================================="
echo "Hadoop installation and startup complete!"
echo "Web Interfaces available at:"
echo "HDFS NameNode:   http://localhost:9870"
echo "YARN ResourceManager: http://localhost:8088"
echo "=========================================="

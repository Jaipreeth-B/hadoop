#!/bin/bash

# ==========================================
# STEP 1: Install Java (OpenJDK 8)
# ==========================================
sudo apt update
sudo apt install openjdk-8-jdk openjdk-8-jre -y
java -version
javac -version

# ==========================================
# STEP 2: Set Java Environment Variables
# ==========================================
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc

# ==========================================
# STEP 3: Create Hadoop User
# ==========================================
sudo adduser --disabled-password --gecos "" hadoop
sudo usermod -aG sudo hadoop

# ==========================================
# STEP 4: Install and Configure SSH
# ==========================================
sudo apt install ssh -y
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# ==========================================
# STEP 5: Install Hadoop 3.1.4
# ==========================================
cd /tmp
wget https://archive.apache.org/dist/hadoop/common/hadoop-3.1.4/hadoop-3.1.4.tar.gz
tar -xzvf hadoop-3.1.4.tar.gz
sudo mv hadoop-3.1.4 /usr/local/hadoop

# ==========================================
# STEP 6: Configure Hadoop Environment
# ==========================================
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
echo 'export HADOOP_HOME=/usr/local/hadoop' >> ~/.bashrc
echo 'export HADOOP_MAPRED_HOME=$HADOOP_HOME' >> ~/.bashrc
echo 'export HADOOP_COMMON_HOME=$HADOOP_HOME' >> ~/.bashrc
echo 'export HADOOP_HDFS_HOME=$HADOOP_HOME' >> ~/.bashrc
echo 'export YARN_HOME=$HADOOP_HOME' >> ~/.bashrc
echo 'export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native' >> ~/.bashrc
echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> ~/.bashrc
echo 'export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"' >> ~/.bashrc

source ~/.bashrc

# ==========================================
# STEP 7: Configure Hadoop Files
# ==========================================

# 1. Update hadoop-env.sh
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh

# 2. Write core-site.xml
cat << 'XML' > /usr/local/hadoop/etc/hadoop/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/usr/local/hadoop/htemp</value>
    </property>
</configuration>
XML

# 3. Write hdfs-site.xml
cat << 'XML' > /usr/local/hadoop/etc/hadoop/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.name.dir</name>
        <value>file:/usr/local/hadoop/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.data.dir</name>
        <value>file:/usr/local/hadoop/hdfs/datanode</value>
    </property>
</configuration>
XML

# Create HDFS directories
mkdir -p /usr/local/hadoop/hdfs/namenode
mkdir -p /usr/local/hadoop/hdfs/datanode

# 4. Write mapred-site.xml
cp /usr/local/hadoop/etc/hadoop/mapred-site.xml.template /usr/local/hadoop/etc/hadoop/mapred-site.xml 2>/dev/null || true
cat << 'XML' > /usr/local/hadoop/etc/hadoop/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
XML

# 5. Write yarn-site.xml
cat << 'XML' > /usr/local/hadoop/etc/hadoop/yarn-site.xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
XML

# ==========================================
# STEP 8: Format NameNode (run only once)
# ==========================================
/usr/local/hadoop/bin/hdfs namenode -format

# ==========================================
# STEP 9 & 10: Start Services and Verify
# ==========================================
cd /usr/local/hadoop/sbin
./start-dfs.sh
./start-yarn.sh

echo "=========================================="
echo "Checking running services with jps:"
echo "=========================================="
jps

echo "=========================================="
echo "Web Interfaces available at:"
echo "HDFS: http://localhost:9870"
echo "YARN: http://localhost:8088"
echo "=========================================="

package org.myorg;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class HashtagDriver {
    public static void main(String[] args) throws Exception {
        Job j = Job.getInstance(new Configuration(), "Top 10 Hashtags");
        j.setJarByClass(HashtagDriver.class);
        j.setMapperClass(HashtagMapper.class);
        j.setReducerClass(HashtagReducer.class);
        j.setMapOutputKeyClass(Text.class);
        j.setMapOutputValueClass(IntWritable.class);
        j.setOutputKeyClass(IntWritable.class);
        j.setOutputValueClass(Text.class);
        j.setNumReduceTasks(1);
        FileInputFormat.addInputPath(j, new Path(args[0]));
        FileOutputFormat.setOutputPath(j, new Path(args[1]));
        System.exit(j.waitForCompletion(true) ? 0 : 1);
    }
}

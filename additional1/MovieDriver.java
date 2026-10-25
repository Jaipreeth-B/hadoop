package org.myorg;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class MovieDriver {
    public static void main(String[] args) throws Exception {
        Job j = Job.getInstance(new Configuration(), "Top 10 Movies");
        j.setJarByClass(MovieDriver.class);
        j.setMapperClass(MovieMapper.class);
        j.setReducerClass(MovieReducer.class);
        j.setMapOutputKeyClass(Text.class);
        j.setMapOutputValueClass(IntWritable.class);
        j.setOutputKeyClass(DoubleWritable.class);
        j.setOutputValueClass(Text.class);
        j.setNumReduceTasks(1);
        FileInputFormat.addInputPath(j, new Path(args[0]));
        FileOutputFormat.setOutputPath(j, new Path(args[1]));
        System.exit(j.waitForCompletion(true) ? 0 : 1);
    }
}

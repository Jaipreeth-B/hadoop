package org.myorg;
import java.io.IOException;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Mapper;

public class HashtagMapper extends Mapper<LongWritable,Text,Text,IntWritable> {
    public void map(LongWritable k, Text v, Context c)
    throws IOException, InterruptedException {
        for (String w : v.toString().split("\\s+")) {
            if (w.startsWith("#"))
                c.write(new Text(w), new IntWritable(1));
        }
    }
}

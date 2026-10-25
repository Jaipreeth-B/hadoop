package org.myorg;
import java.io.IOException;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Mapper;

public class MovieMapper extends Mapper<LongWritable,Text,Text,IntWritable> {
    public void map(LongWritable k, Text v, Context c)
    throws IOException, InterruptedException {
        String[] a = v.toString().split(",");
        if (a.length == 3) {
            try {
                c.write(new Text(a[1].trim()),
                    new IntWritable(Integer.parseInt(a[2].trim())));
            } catch (NumberFormatException e) { }
        }
    }
}

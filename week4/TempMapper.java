package org.myorg;
import java.io.IOException;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Mapper;

public class TempMapper extends Mapper<LongWritable,Text,Text,IntWritable> {
    public void map(LongWritable k, Text v, Context c)
    throws IOException, InterruptedException {
        String[] a = v.toString().split("\\s+");
        if (a.length >= 2) {
            try {
                c.write(new Text(a[0]),
                    new IntWritable(Integer.parseInt(a[1])));
            } catch (NumberFormatException e) {
                // Skip invalid temperature
            }
        }
    }
}

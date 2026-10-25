package org.myorg;
import java.io.IOException;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Reducer;

public class TempReducer extends Reducer<Text,IntWritable,Text,IntWritable> {
    public void reduce(Text k, Iterable<IntWritable> v, Context c)
    throws IOException, InterruptedException {
        int max = Integer.MIN_VALUE;
        for (IntWritable n : v)
            if (n.get() > max) max = n.get();
        c.write(k, new IntWritable(max));
    }
}

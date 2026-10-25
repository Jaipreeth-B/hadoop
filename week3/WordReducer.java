package org.myorg;
import java.io.IOException;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Reducer;

public class WordReducer extends Reducer<Text,IntWritable,Text,IntWritable> {
    public void reduce(Text k, Iterable<IntWritable> v, Context c)
    throws IOException, InterruptedException {
        int sum = 0;
        for (IntWritable n : v)
            sum += n.get();
        c.write(k, new IntWritable(sum));
    }
}

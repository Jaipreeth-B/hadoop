package org.myorg;
import java.io.IOException;
import java.util.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Reducer;

public class HashtagReducer
extends Reducer<Text,IntWritable,IntWritable,Text> {

    TreeMap<Integer,List<String>> tags = new TreeMap<>();

    public void reduce(Text k, Iterable<IntWritable> v, Context c)
    throws IOException, InterruptedException {
        int sum = 0;
        for (IntWritable n : v)
            sum += n.get();
        tags.computeIfAbsent(sum, x -> new ArrayList<>()).add(k.toString());
    }

    protected void cleanup(Context c)
    throws IOException, InterruptedException {
        int rank = 0;
        for (Map.Entry<Integer,List<String>> e :
             tags.descendingMap().entrySet()) {
            for (String tag : e.getValue()) {
                c.write(new IntWritable(e.getKey()), new Text(tag));
                if (++rank == 10) return;
            }
        }
    }
}

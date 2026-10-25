package org.myorg;
import java.io.IOException;
import java.util.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.Reducer;

public class MovieReducer
extends Reducer<Text,IntWritable,DoubleWritable,Text> {

    TreeMap<Double,List<String>> movies = new TreeMap<>();

    public void reduce(Text k, Iterable<IntWritable> v, Context c)
    throws IOException, InterruptedException {
        int sum = 0, count = 0;
        for (IntWritable n : v) {
            sum += n.get();
            count++;
        }
        if (count > 0) {
            double avg = (double) sum / count;
            movies.computeIfAbsent(avg, x -> new ArrayList<>())
                  .add(k.toString());
        }
    }

    protected void cleanup(Context c)
    throws IOException, InterruptedException {
        int rank = 0;
        for (Map.Entry<Double,List<String>> e :
             movies.descendingMap().entrySet()) {
            for (String movie : e.getValue()) {
                c.write(new DoubleWritable(e.getKey()), new Text(movie));
                if (++rank == 10) return;
            }
        }
    }
}

---
title: 'Notes on Google PowerDrill'
date: 2017-12-29
hideToc: true
---

#### Links
* [Hall et al.: Processing a Trillion Cells per Mouse Click](http://vldb.org/pvldb/vol5/p1436_alexanderhall_vldb2012.pdf)
* [Hall lecture video](https://www.youtube.com/watch?v=fbZjbkTrt8A)
* [Wired article](https://www.wired.com/2012/08/google-trillion-pieces-of-data/) (typical Wired garbage, but still contains a few details not found in the paper)


#### Notes

_Formatted in a question / answer style_

**Introduction & Background**

What is PowerDrill (PD)?

* A web-based analysis tool built by Google AdWords team
* The columnar storage backend and execution engine is called "PD Serving", and is the focus of this paper

What types of analysis can you do in PD?

* Drilldown: start with the entire dataset and perform slice/filter/aggregate operations
* UI consists of bar graphs (`GROUP BY`) and selection/filters (`WHERE`)
    * Bias towards discrete/categorical data (strings, dates, etc.)

What kind of data is being analyzed?

* Paper is not specific about this, but video is
* The most important AdWords datasets
* Log data
    * lots of string columns (e.g. search query text)
    * Wide datasets: thousands of columns
* Usecases given:
    * responding to user requests (support requests?)
    * spam analysis (somewhat interactive)
    * Generating alerts for mission-critical systems (clickfraud according to the video)

Who is using PD?

* Google internal only
* 800 monthly users, 4 million monthly queries (c. 2012)

Why use columnar storage?

* Compression: same-typed data is lower entropy so yields higher compression rate
    * specialized compression techniques for certain datatypes (e.g. dictionary encoding, RLE)
* Typical datasets: ~1000's of of columns. Typical queries: ~10's of columns
    * skip reading lots of raw data
* Optimized for full-scans, heavily used by aggregates/rollups


When are full-scans better than indexed reads?

* Unless reading a very small number of records, sequential table scans will be cheaper than random I/O to read individual tuples
    * applies to set filters, e.g. `WHERE col IN (val_0, val_1, val_2, ...)`, common for strings
* Also: imaginably some columns (e.g. text) can have some large indexes built for them)
* Sequential scanning will have better cache locality
* PowerDrill takes a hybrid approach between indexed and full-scans
    * Import Time: split data into chunks, include some metadata
    * Query Time: look at metadata to determine set of chunks to read, then perform full-scan of these chunks

**Specifics of the partitioning system (Figure 1)**

* How does PowerDrill partition data into chunks at import time?
    * Choose a set of fields, iteratively split chunks into smaller chunks on ranges of those fields
    * All columns are stored in physically separate files, but the values are all ordered the same
* Columns encoded with "double dictionary": a global column dictionary, and then 1 chunk dict per chunk
    * global dictionary => per-column, all distinct values. for strings, id's are mapped in sorted order (e.g. "aardvark", "beer", "beast" => IDs 0, 2, 1).
* Advantages of double dict:
    * Low memory footprint (strings => small consecutive numbers)
        * This becomes important as we attempt to keep as much in memory as possible
    * Query processing speedups:
        * Filtering only hits the chunk dictionaries
        * Aggregations require only reading from the _active chunks_

<pre>
column "search_string"

+-------------------+   +-------------------+  +-------------------+
| column dictionary |   | chunk 1  | elems  |  | chunk 2 |  elems  |
+-------------------+   +-------------------+  +-------------------+
| 0  |  aardvark    |   | 0  |  2  | 2,0,1, |  | 0  |  0 | 3,2,0,1,|
| 1  |  beast       |   | 1  |  3  | 1,0,1, |  | 1  |  1 | 2,1,2,3 |
| 2  |  beast       |   | 2  |  4  | 2,1    |  | 2  |  3 |         |
| 3  |  expose      |   +-------------------+  | 3  |  4 |         |
| 4  |  googly      |                          +-------------------+
+-------------------+
</pre>

* Query execution. Working with following example:
<pre>
    SELECT search_string, COUNT(*) AS c FROM data
    WHERE search_string IN ("aardvark", "beast", "unmatched")
    GROUP BY search_string ORDER BY c DESC LIMIT 10
</pre>
    * `unmatched` is not in any chunk, and `aardvark` (ID 0) and `beast` (ID 1) are only mapped in chunk 2. Thus, only one _active chunk_ (chunk 2).
    * All active chunks will be scanned
        * Output will be the following:
<pre>
search_string  |  c
--------------------
beast          | 2
aardvark       | 1
</pre>

Some extra goodies:

* Expensive computed fields are computed just once on first execution, and then materialized into the dataset as new _virtual columns_
    * e.g. `date(dcol)` creates a new virtual column `virtual_date(dcol)` that is then used in subsequent applications of the filter

**Benchmarks**

How did we measure?

* Compared CSV, record-io and Dremel storage backends to PD Serving (Basic in Table 1)
    * PD Serving columns were all in a single chunk (i.e. no partitioning)
* Benchmarked on 3 different queries:
    1. Unfiltered `GROUP BY` on single low cardinality column
    1. `GROUP BY` on derived field `date(timestamp) AS date`
    1. Unfiltered `GROUP BY` on high cardinality column (100k+ distinct values)
* Measurements were taken of query latency and memory usage over 5 trials
* PD Serving beat out the others by a ~2 orders of magnitude on latency, edges out Dremel on memory usage
    * CSV and Random IO store row-wise, so must perform a full scans over the full dataset, driving up memory usage
    * PD Serving's double pruning of chunks, and its array-based aggregates were more efficient than the hash table aggregates
      performed by the other systems

How did we perform?

* PD Serving beat out all the other 3 systems
    * CSV / Random IO are row

**Optimizations**

* Enabling partitioning
* Reduce global dictionary memory with fine-tuned trie representation
* Various compression techniques I sort of glossed over, probably worth a look however. These seemed to help the most with high cardinality fields such as `table_name`

**Conclusions**

There are a few major takeaways I got from this paper. The main one is that shoving as much into memory as possible is key for low-latency execution. The corollary to this is that your runtime data structures should be optimized for memory usage, so compressed columnar formats are really good here.

For OLAP workloads, often the entire dataset will need to be read, to compute an aggregate, etc. Point filters and range scans are rarer than set filters (`value IN (v0, v1, v2)`), so we need to usually read all or most of the data anyway. In that case, it's best to optimize your storage format to allow for aggressive pruning at planning time. This requires having your data partitioned in such that your partitions are small and at the same time, each query is only likely to hit one (or a handful) of partitions.

**Unanswered Questions**

The optimized tries structure for the global-dictionaries sounds neat, but they lost me a bit with the 4-bit encoding piece. Would be nice to get a better summary/diagram of what's going on here.

Overall, a cool piece of software decently well-explained by its creators. Definitely recommend the companion video as it cleared a few things up for me about the partitioning section.

# OpenSearch Job Benchmarking

This project compares the performance of different job processing approaches for OpenSearch indexing operations in a Rails application. The primary goal is to determine which job processing system performs better for OpenSearch indexing tasks, particularly focusing on the comparison between thread-based (SolidQueue) and fiber-based (AsyncJob) approaches.

## Project Overview

The project benchmarks two different job processing systems:

1. **SolidQueue** - A thread-based job processing system (using 3 threads)
2. **AsyncJob** - A fiber-based job processing system

The benchmarks focus on OpenSearch document indexing operations with varying batch sizes to determine which approach scales better.

## Implementation

### Job Types

- **JobTest1Job** - Uses SolidQueue (thread-based)
- **JobTest2Job** - Uses AsyncJob (fiber-based)

Both job types perform the same OpenSearch indexing operations but use different job processing backends.

### Benchmark Methodology

The benchmarking process:

1. Generates test documents with varying batch sizes (10, 100, 1000)
2. Enqueues jobs for both SolidQueue and AsyncJob
3. Measures performance metrics (execution time, throughput)
4. Tracks resource usage (CPU, memory)
5. Compares results between the two approaches

### Resource Monitoring

The project includes a `ResourceMetricsService` that tracks:

- Memory usage (using the `get_process_mem` gem)
- CPU time

This monitoring happens directly within the jobs to provide accurate measurements.

## Benchmark Results

### Performance Metrics

| Batch Size | Metric | SolidQueue | AsyncJob | Difference |
|------------|--------|------------|----------|------------|
| 10 | Avg Enqueue Time | 0.17s | 0.07s | AsyncJob 58.8% faster |
| 10 | Avg Total Time | 7.18s | 7.08s | AsyncJob 1.5% faster |
| 10 | Avg Throughput | 1.39 docs/s | 1.41 docs/s | AsyncJob 1.4% faster |
| 100 | Avg Enqueue Time | 0.48s | 0.28s | AsyncJob 41.7% faster |
| 100 | Avg Total Time | 7.49s | 7.29s | AsyncJob 2.7% faster |
| 100 | Avg Throughput | 13.35 docs/s | 13.71 docs/s | AsyncJob 2.7% faster |
| 1000 | Avg Enqueue Time | 4.72s | 2.61s | AsyncJob 44.7% faster |
| 1000 | Avg Total Time | 21.76s | 19.64s | AsyncJob 10.8% faster |
| 1000 | Avg Throughput | 45.97 docs/s | 50.92 docs/s | AsyncJob 10.8% faster |

### Resource Usage Metrics

**AsyncJob Resource Usage:**
- Memory Usage:
  - Average: 90.44 MB
  - Maximum: 116.53 MB
- CPU Usage:
  - Total CPU time: 0.0703 seconds

**SolidQueue Resource Usage:**
- No data available (likely due to process isolation)

## Analysis

### Performance Analysis

1. **Small Batch Sizes (10 documents)**:
   - AsyncJob is slightly faster (1.5%)
   - Enqueue time is significantly faster with AsyncJob (58.8%)

2. **Medium Batch Sizes (100 documents)**:
   - AsyncJob shows more advantage (2.7% faster)
   - Enqueue time continues to be much faster with AsyncJob (41.7%)

3. **Large Batch Sizes (1000 documents)**:
   - AsyncJob's advantage becomes more significant (10.8% faster)
   - Enqueue time remains much faster with AsyncJob (44.7%)

### Scaling Analysis

AsyncJob shows better scaling with larger batch sizes:
- For small batches, the difference is minimal (1.5%)
- For large batches, the difference becomes substantial (10.8%)

This suggests that AsyncJob's fiber-based approach handles I/O-bound operations like OpenSearch indexing more efficiently as the workload increases.

## Conclusions

1. **AsyncJob (fiber-based) outperforms SolidQueue (thread-based)** for OpenSearch indexing operations, with the advantage becoming more significant as batch size increases.

2. **AsyncJob shows significantly faster enqueue times** across all batch sizes, suggesting more efficient job queuing.

3. **AsyncJob scales better with larger workloads**, making it particularly suitable for high-throughput OpenSearch indexing operations.

4. For applications using thread-based job queues like SolidQueue with 3 threads (which is standard), similar performance characteristics can be expected when compared to AsyncJob.

## Recommendations

1. **For OpenSearch indexing operations**, especially with larger batch sizes, AsyncJob's fiber-based approach provides better performance.

2. **For applications with high-throughput requirements**, AsyncJob's better scaling with larger workloads makes it a more suitable choice.

3. **For applications where enqueue time is critical**, AsyncJob's significantly faster enqueue times provide a clear advantage.

## Running the Benchmarks

```bash
# Install dependencies
bundle install

# Create OpenSearch index
bundle exec rake benchmark:create_index

# Run benchmarks
bundle exec rake benchmark:run

# Delete OpenSearch index
bundle exec rake benchmark:delete_index
```

## Dependencies

- Ruby 3.3.2
- Rails 8.0.2
- OpenSearch
- SolidQueue
- AsyncJob
- get_process_mem (for memory tracking)

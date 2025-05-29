import redis
import time
import random
import string
import statistics

# Redis connection details
REDIS_HOST = "redisval-bu8xv7.serverless.use1.cache.amazonaws.com"
REDIS_PORT = 6379  # TLS port (verify if TLS supported on this port!)
REDIS_PASSWORD = None

NUM_OPERATIONS = 10000
KEY_PREFIX = "bench_key_"

def random_string(length=10):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def benchmark_operation(redis_client, op_name, action_fn):
    latencies = []
    start = time.time()

    for _ in range(NUM_OPERATIONS):
        t0 = time.perf_counter()
        action_fn()
        t1 = time.perf_counter()
        latencies.append((t1 - t0) * 1000)  # latency in ms

    total_time = time.time() - start
    throughput = NUM_OPERATIONS / total_time

    avg_latency = statistics.mean(latencies)
    p50 = statistics.median(latencies)
    p90 = statistics.quantiles(latencies, n=100)[89]
    p99 = statistics.quantiles(latencies, n=100)[98]

    return {
        "op": op_name,
        "total_time": total_time,
        "throughput": throughput,
        "avg_latency_ms": avg_latency,
        "p50_latency_ms": p50,
        "p90_latency_ms": p90,
        "p99_latency_ms": p99
    }

def benchmark_redis(redis_client):
    results = []

    counter = 0
    def set_fn():
        nonlocal counter
        key = f"{KEY_PREFIX}{counter}"
        value = random_string(50)
        redis_client.set(key, value)
        counter += 1
    results.append(benchmark_operation(redis_client, "SET", set_fn))

    counter = 0
    def get_fn():
        nonlocal counter
        key = f"{KEY_PREFIX}{counter}"
        redis_client.get(key)
        counter += 1
    results.append(benchmark_operation(redis_client, "GET", get_fn))

    counter = 0
    def del_fn():
        nonlocal counter
        key = f"{KEY_PREFIX}{counter}"
        redis_client.delete(key)
        counter += 1
    results.append(benchmark_operation(redis_client, "DEL", del_fn))

    return results

def main():
    try:
        client = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_PASSWORD,
            ssl=True,                # your TLS enabled here
            decode_responses=True
        )

        client.ping()
        print(f"✅ Connected to Redis at {REDIS_HOST}:{REDIS_PORT} over TLS")

        print("🚀 Running benchmark with latency stats...")
        results = benchmark_redis(client)

        print("\n📊 Benchmark Results:")
        for r in results:
            print(f"{r['op']} Operation")
            print(f"  Total Time       : {r['total_time']:.4f} sec")
            print(f"  Throughput       : {r['throughput']:.2f} ops/sec")
            print(f"  Average Latency  : {r['avg_latency_ms']:.3f} ms")
            print(f"  p50 Latency      : {r['p50_latency_ms']:.3f} ms")
            print(f"  p90 Latency      : {r['p90_latency_ms']:.3f} ms")
            print(f"  p99 Latency      : {r['p99_latency_ms']:.3f} ms\n")

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
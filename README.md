# ToolForRedis

This is Tool for Redis.   
Written by pure Swift language 5.3 base on SwiftNIO framework.

* Supported Command.

  - Basic.
    + auth
    + select
    + scan
    + type
    + ttl
    + expire
    + persist
    + info
    + config
    + renamenx
    + del

  - String datatype.
    + get
    + set

  - List datatype.
    + lrange
    + lset
    + rpush
    + lrem

  - Set datatype.
    + sscan
    + sadd
    + srem

  - Hash datatype.
    + hscan
    + hset
    + hdel

  - Zset datatype.
    + zrange
    + zadd
    + zrem

  - Pub/Sub.
    + subscribe
    + unsubscribe
    + publish

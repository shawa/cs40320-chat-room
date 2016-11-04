# Lab 2: Skeleton Multithreaded Server

Node.js implementation. Thread pool pattern to limit the number of possible clients is emulated by a counter. Unless the counter is less than the max, new clients are load-shedded and ignored until the rest of the clients have disconnected.

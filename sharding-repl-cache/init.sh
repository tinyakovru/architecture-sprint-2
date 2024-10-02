#!/bin/bash

docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
exit();
EOF

docker compose exec -T shard1-1 mongosh --port 27022 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1-1:27022" },
        { _id : 1, host : "shard1-2:27023" },
        { _id : 2, host : "shard1-3:27024" }
      ]
    }
);
exit();
EOF

docker compose exec -T shard2-1 mongosh --port 27025 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 3, host : "shard2-1:27025" },
        { _id : 4, host : "shard2-2:27026" },
        { _id : 5, host : "shard2-3:27027" }
      ]
    }
  );
exit();
EOF

docker compose exec -T router1 mongosh --port 27020 --quiet <<EOF

sh.addShard( "shard1/shard1-1:27022");
sh.addShard( "shard2/shard2-1:27025");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

EOF

docker compose exec -T router2 mongosh --port 27021 --quiet <<EOF

sh.addShard( "shard1/shard1-1:27022");
sh.addShard( "shard2/shard2-1:27025");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

db.helloDoc.countDocuments()
exit();
EOF

docker compose exec -T shard1-1 mongosh --port 27022 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
exit();
EOF

docker compose exec -T shard1-2 mongosh --port 27023 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
exit();
EOF

docker compose exec -T shard1-3 mongosh --port 27024 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
exit();
EOF

docker compose exec -T shard2-1 mongosh --port 27025 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
exit();
EOF

docker compose exec -T shard2-2 mongosh --port 27026 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
exit();
EOF

docker compose exec -T shard2-3 mongosh --port 27027 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
exit();
EOF


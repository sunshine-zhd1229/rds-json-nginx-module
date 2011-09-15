# vi:filetype=

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(2);

plan tests => repeat_each() * 2 * blocks();

$ENV{TEST_NGINX_MYSQL_PORT} ||= 3306;

our $http_config = <<'_EOC_';
    upstream backend {
        drizzle_server 127.0.0.1:$TEST_NGINX_MYSQL_PORT protocol=mysql
                       dbname=ngx_test user=ngx_test password=ngx_test;
    }
_EOC_

no_diff();
no_long_string();

run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval: $::http_config
--- config
    location /mysql {
        drizzle_query '
            select * from cats order by id asc
        ';
        drizzle_pass backend;
        rds_json on;
        rds_json_root rows;
    }
--- request
GET /mysql
--- response_body chomp
{"rows":[{"id":2,"name":null},{"id":3,"name":"bob"}]}



=== TEST 2: update
--- http_config eval: $::http_config
--- config
    location /mysql {
        drizzle_pass backend;
        #drizzle_dbname $dbname;
        drizzle_query "update cats set name='bob' where name='bob'";
        rds_json on;
        rds_json_root data;
    }
--- request
GET /mysql
--- response_body chop
{"errcode":0,"errstr":"Rows matched: 1  Changed: 0  Warnings: 0"}



=== TEST 3: select empty result
--- http_config eval: $::http_config
--- config
    location /mysql {
        drizzle_pass backend;
        drizzle_query "select * from cats where name='tom'";
        rds_json on;
        rds_json_root data;
    }
--- request
GET /mysql
--- response_body chop
{"data":[]}



=== TEST 4: sanity + compact
--- http_config eval: $::http_config
--- config
    location /mysql {
        drizzle_query '
            select * from cats order by id asc
        ';
        drizzle_pass backend;
        rds_json on;
        rds_json_root rows;
        rds_json_format compact;
    }
--- request
GET /mysql
--- response_body chomp
{"rows":[["id","name"],[2,null],[3,"bob"]]}



=== TEST 5: select empty result + compact
--- http_config eval: $::http_config
--- config
    location /mysql {
        drizzle_pass backend;
        drizzle_query "select * from cats where name='tom'";
        rds_json on;
        rds_json_root data;
        rds_json_format compact;
    }
--- request
GET /mysql
--- response_body chop
{"data":[["id","name"]]}


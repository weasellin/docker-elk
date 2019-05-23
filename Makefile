jks_gen:
	docker-compose -f docker-compose-jks-gen.yml down
	docker-compose -f docker-compose-jks-gen.yml build
	docker-compose -f docker-compose-jks-gen.yml up
	cp ./search-guard-ssl/output/*.jks ./elasticsearch/config/sg/
	rm -rf ./search-guard-ssl/output/*

build:
	docker-compose build

down:
	docker-compose down

run: build down
	docker-compose up -d elasticsearch && \
	docker-compose exec elasticsearch \
		/bin/bash -c \
		'until $$(curl -XGET http://localhost:9200/_cat/health?v > /dev/null); \
		 do printf "Waiting Elasticsearch service up, trying again in 5 seconds ... \n"; \
		 sleep 5; \
		 done && bin/init_sg.sh' && \
	docker-compose up -d logstash && \
	docker-compose up -d kibana

# usage: make passwd_hash PASSWD=xxxxxxxx
passwd_hash:
	docker-compose exec elasticsearch \
		plugins/search-guard-6/tools/hash.sh -p ${PASSWD}

send_test_log:
	echo "{\"es_index\": \"logstash-user1\", \"message\": \"Hello from user1.\"}" | nc localhost 5000
	echo "{\"es_index\": \"logstash-user2\", \"message\": \"Hello from user2.\"}" | nc localhost 5000

USER:=user1

show_index:
	curl -u ${USER}:${USER} \
		 -H 'Content-Type: application/json' \
		-X GET \
		http://localhost:9200/logstash-* \
	| jq 'keys[]'

show_logs:
	curl -u ${USER}:${USER} \
		-H 'Content-Type: application/json' \
		-X GET \
		http://localhost:9200/logstash-${USER}-*/_search \
	| jq '.hits.hits[] | {index: ._index, message: ._source.message}'

show_all_logs:
	curl -u admin:admin \
		-H 'Content-Type: application/json' \
		-X GET \
		http://localhost:9200/logstash-*/_search \
	| jq '.hits.hits[] | {index: ._index, message: ._source.message}'

show_kibana_meta:
	curl -u admin:admin \
		 -H 'Content-Type: application/json' \
		 -X GET \
		 http://localhost:9200/.kibana_*/_search \
	| jq '.hits.hits[] | {index: ._index, id: ._id, type: ._source.type, title: ._source."index-pattern".title}'

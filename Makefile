# CONST 
DEV_ENV_DIR := ./dev.env
BASE_CONFIG_DIR := ./configs
GEN_CONFIG_DIR := ${BASE_CONFIG_DIR}/gen
CLICKHOUSE_DOCKER_COMPOSE_FILE := ./docker-compose-clickhouse.yml
KAFKA_DOCKER_COMPOSE_FILE := ./docker-compose-kafka.yml
REDIS_DOCKER_COMPOSE_FILE := ./docker-compose-redis.yml
RABBITMQ_DOCKER_COMPOSE_FILE := ./docker-compose-rabbitmq.yml
LOCALSTACK_DOCKER_COMPOSE_FILE := ./docker-compose-localstack.yml
MYSQL_DOCKER_COMPOSE_FILE := ./docker-compose-mysql.yml

# Import dot env file
ifneq (,$(wildcard ${DEV_ENV_DIR}))
	include ${DEV_ENV_DIR}
else
endif

.PHONY: gen-clickhouse-config
gen-clickhouse-config:
	rm -rf ${GEN_CONFIG_DIR} ; \
	mkdir -p ${GEN_CONFIG_DIR}/ch-server-1 ; \
	mkdir -p ${GEN_CONFIG_DIR}/ch-server-1-rep ; \
	mkdir -p ${GEN_CONFIG_DIR}/ch-server-2 ; \
	mkdir -p ${GEN_CONFIG_DIR}/ch-server-2-rep
	# Setup keeper 1
	SERVER_ID=1 envsubst < ${BASE_CONFIG_DIR}/enable_keeper.xml > ${GEN_CONFIG_DIR}/ch-server-1/enable_keeper.xml
	REPLICA=r1 SHARD=s1 envsubst < ${BASE_CONFIG_DIR}/macros.xml > ${GEN_CONFIG_DIR}/ch-server-1/macros.xml
	cp ${BASE_CONFIG_DIR}/remote_servers.xml ${BASE_CONFIG_DIR}/use_keeper.xml ${BASE_CONFIG_DIR}/base_clickhouse.xml ${GEN_CONFIG_DIR}/ch-server-1/
	# Setup keeper 2
	SERVER_ID=2 envsubst < ${BASE_CONFIG_DIR}/enable_keeper.xml > ${GEN_CONFIG_DIR}/ch-server-1-rep/enable_keeper.xml
	REPLICA=r2 SHARD=s1 envsubst < ${BASE_CONFIG_DIR}/macros.xml > ${GEN_CONFIG_DIR}/ch-server-1-rep/macros.xml
	cp ${BASE_CONFIG_DIR}/remote_servers.xml ${BASE_CONFIG_DIR}/use_keeper.xml ${BASE_CONFIG_DIR}/base_clickhouse.xml ${GEN_CONFIG_DIR}/ch-server-1-rep/
	# Setup keeper 3
	SERVER_ID=3 envsubst < ${BASE_CONFIG_DIR}/enable_keeper.xml > ${GEN_CONFIG_DIR}/ch-server-2/enable_keeper.xml
	REPLICA=r1 SHARD=s2 envsubst < ${BASE_CONFIG_DIR}/macros.xml > ${GEN_CONFIG_DIR}/ch-server-2/macros.xml
	cp ${BASE_CONFIG_DIR}/remote_servers.xml ${BASE_CONFIG_DIR}/use_keeper.xml ${BASE_CONFIG_DIR}/base_clickhouse.xml ${GEN_CONFIG_DIR}/ch-server-2/
	# Setup rep s2
	REPLICA=r2 SHARD=s2 envsubst < ${BASE_CONFIG_DIR}/macros.xml > ${GEN_CONFIG_DIR}/ch-server-2-rep/macros.xml
	cp ${BASE_CONFIG_DIR}/remote_servers.xml ${BASE_CONFIG_DIR}/use_keeper.xml ${BASE_CONFIG_DIR}/base_clickhouse.xml ${GEN_CONFIG_DIR}/ch-server-2-rep/

.PHONY: clickhouse-up
clickhouse-up:
	docker-compose --env-file ${DEV_ENV_DIR} -f ${CLICKHOUSE_DOCKER_COMPOSE_FILE} up --build

.PHONY: clickhouse-clean
clickhouse-clean:
	docker container rm --force $$(docker ps -a -f name=ch-client -aq)
	docker container rm --force $$(docker ps -a -f name=ch-server -aq)
	docker volume rm $$(docker volume ls -f name=docker-compose-sum_ch-server -q) 
	docker volume prune -f

.PHONY: kafka-up
kafka-up:
	docker-compose --env-file ${DEV_ENV_DIR} -f ${KAFKA_DOCKER_COMPOSE_FILE} up --build

.PHONY: kafka-clean
kafka-clean:
	docker container rm --force $$(docker ps -a -f name=kafka-node -aq)
	docker container rm --force $$(docker ps -a -f name=kafka-ui -aq)
	docker volume rm $$(docker volume ls -f name=docker-compose-sum_kafka-node -q)


.PHONY: redis-up
redis-up:
	docker-compose --env-file ${DEV_ENV_DIR} -f ${REDIS_DOCKER_COMPOSE_FILE} up --build

.PHONY: redis-clean
redis-clean:
	docker container rm --force $$(docker ps -a -f name=redis-node -aq)
	docker volume rm $$(docker volume ls -f name=docker-compose-sum_redis-node -q)

.PHONY: rabbitmq-up
rabbitmq-up:
	docker-compose --env-file ${DEV_ENV_DIR} -f ${RABBITMQ_DOCKER_COMPOSE_FILE} up --build

.PHONY: rabbitmq-clean
rabbitmq-clean:
	docker container rm --force $$(docker ps -a -f name=rabbitmq-node -aq)
	docker volume rm $$(docker volume ls -f name=docker-compose-sum_rabbitmq-node -q)

.PHONY: localstack-up
localstack-up:
	docker-compose --env-file ${DEV_ENV_DIR} -f ${LOCALSTACK_DOCKER_COMPOSE_FILE} up --build

.PHONY: localstack-clean
localstack-clean:
	docker container rm --force $$(docker ps -a -f name=localstack -aq)
	docker volume rm $$(docker volume ls -f name=docker-compose-sum_localstack -q)

.PHONY: mysql-up
mysql-up:
	docker-compose --env-file ${DEV_ENV_DIR} -f ${MYSQL_DOCKER_COMPOSE_FILE} up --build

.PHONY: mysql-clean
mysql-clean:
	docker container rm --force $$(docker ps -a -f name=mysql -aq)
	docker container rm --force $$(docker ps -a -f name=adminer -aq)
	docker volume rm $$(docker volume ls -f name=docker-compose-sum_mysql -q)

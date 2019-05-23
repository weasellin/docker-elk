#!/bin/sh
plugins/search-guard-6/tools/sgadmin.sh \
	-cd config/sg/ \
	-ts config/sg/truststore.jks \
	-tspass ${TS_PASS} \
	-ks config/sg/${CRT_CLIENT_NAME}-keystore.jks \
	-kspass ${KS_PASS} \
	-nhnv \
	-icl

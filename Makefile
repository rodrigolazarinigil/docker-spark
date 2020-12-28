SPARK_VERSION ?= 3.0.1
JAVA_VERSION ?= 14
HADOOP_VERSION ?= 3.2
IMAGE_VERSION = v${SPARK_VERSION}-j${JAVA_VERSION}

TMP_SPARK_HOME ?= ${PWD}/base_spark

# Download base spark code from Apache
download_base_spark:
	mkdir -p ${TMP_SPARK_HOME}
	rm -rf ${TMP_SPARK_HOME}/*
	curl -fSL https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz | tar -xz -C ${TMP_SPARK_HOME} --strip-components 1

# Builds the pyspark docker image using the oficial Dockerfile
build_pyspark_image:
	${TMP_SPARK_HOME}/bin/docker-image-tool.sh \
		-r spark \
		-t v${SPARK_VERSION}-j${JAVA_VERSION} \
		-p ${TMP_SPARK_HOME}/kubernetes/dockerfiles/spark/bindings/python/Dockerfile \
		-b java_image_tag=${JAVA_VERSION}-slim \
		build

build_gcp_gitsync_pyspark_image: build_pyspark_image
	cd gcp_gitsync_pyspark && \
		docker build -t ${IMAGE_VERSION}-gcp \
		--build-arg base_spark_image=spark/spark-py:${IMAGE_VERSION} .

run_local:
	docker run --rm \
		-v ${PWD}/gcp_gitsync_pyspark/jobs/:/tmp/jobs \
		-e PYTHONPATH=/opt/ \
		-e ENV=LOCAL \
		${IMAGE_VERSION}-gcp \
		spark-submit \
			--master local[4] \
			--name test \
			/tmp/jobs/sample_job.py

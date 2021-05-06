SPARK_VERSION ?= 3.0.1
JAVA_VERSION ?= 14
HADOOP_VERSION ?= 3.2
IMAGE_VERSION = v${SPARK_VERSION}-j${JAVA_VERSION}

SPARK_IMAGE_NAME = spark-py
SPARK_IMAGE_FULL_NAME = spark/${SPARK_IMAGE_NAME}:${IMAGE_VERSION}

CUSTOM_SPARK_IMAGE_NAME = custom-spark-py
CUSTOM_SPARK_IMAGE_FULL_NAME = ${CUSTOM_SPARK_IMAGE_NAME}:${IMAGE_VERSION}-latest

IMAGE_REGISTRY_PREFIX = us.gcr.io/<company_prefix>
TMP_SPARK_HOME = ${PWD}/base_spark

# Download base spark code from Apache
download_base_spark:
	mkdir -p ${TMP_SPARK_HOME}
	rm -rf ${TMP_SPARK_HOME}/*
	curl -fSL https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz | tar -xz -C ${TMP_SPARK_HOME} --strip-components 1

# Builds the pyspark docker image using the oficial Dockerfile
build_spark_image:
	${TMP_SPARK_HOME}/bin/docker-image-tool.sh \
		-r spark \
		-t ${IMAGE_VERSION} \
		-p ${TMP_SPARK_HOME}/kubernetes/dockerfiles/spark/bindings/python/Dockerfile \
		-b java_image_tag=${JAVA_VERSION}-slim \
		build

# Builds our custom spark image with additional jars and the most commom python libraries
build_custom_spark_image: build_spark_image
	docker build -t ${CUSTOM_SPARK_IMAGE_FULL_NAME} --build-arg base_spark_image=${SPARK_IMAGE_FULL_NAME} .


# Push the image to registry
push_image:
	docker tag ${CUSTOM_SPARK_IMAGE_FULL_NAME} ${IMAGE_REGISTRY_PREFIX}/${CUSTOM_SPARK_IMAGE_NAME}:${IMAGE_VERSION}-${VERSION}
	docker push ${IMAGE_REGISTRY_PREFIX}/${CUSTOM_SPARK_IMAGE_NAME}:${IMAGE_VERSION}-${VERSION}
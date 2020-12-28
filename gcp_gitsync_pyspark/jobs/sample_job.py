from pyspark.sql import SparkSession

if __name__ == "__main__":
    spark_session = SparkSession.builder.getOrCreate()
    df = spark_session.read.csv("/tmp/jobs/sample.csv")
    df.printSchema()
    df.show(10)
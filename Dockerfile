FROM gcr.io/dataflow-templates-base/java17-template-launcher-base:latest

ENV FLEX_TEMPLATE_JAVA_MAIN_CLASS="com.google.cloud.teleport.v2.templates.DataStreamToBigQuery"
ENV FLEX_TEMPLATE_JAVA_CLASSPATH="run.jar"

RUN echo "Compiling"
COPY v2/datastream-to-bigquery/target/datastream-to-bigquery-1.0-SNAPSHOT.jar run.jar


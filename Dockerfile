FROM genepi/imputationserver:v1.5.7

COPY cloudgene.conf /opt/cloudgene/cloudgene.conf

COPY apps.yaml ${CLOUDGENE_REPOSITORY}

RUN mkdir -p -v /localdata

RUN cloudgene clone ${CLOUDGENE_REPOSITORY}

RUN ls /localdata

CMD ["/opt/cloudgene/cloudgene"]

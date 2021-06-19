FROM genepi/imputationserver:v1.5.7

RUN mkdir -p -v /localdata/mds && \
    for file_name in HM3_b37.bed HM3_b37.bim HM3_b37.fam; do \
        wget -qO - http://genepi.qimr.edu.au/staff/sarahMe/enigma/MDS/${file_name}.gz | gunzip > /localdata/mds/${file_name}; \
    done

RUN (apt-get update || exit 0) && \
    apt-get install -y "vcftools" && \
    apt-get clean && \
    apt-get purge && \
    wget -qO /tmp/plink_linux.zip https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20210606.zip && \
    unzip /tmp/plink_linux.zip plink -d /usr/local/bin && \
    wget -qO /tmp/plink2_linux.zip https://s3.amazonaws.com/plink2-assets/plink2_linux_x86_64_20210608.zip && \
    unzip /tmp/plink2_linux.zip plink2 -d /usr/local/bin && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY cloudgene-override/* /opt/cloudgene/
COPY bin/* /usr/local/bin/

CMD ["/bin/bash"]

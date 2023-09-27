FROM sbtscala/scala-sbt:eclipse-temurin-jammy-19.0.1_10_1.9.0_3.2.2 as builder

COPY src/extract-all /src/extract-all
RUN cd /src/extract-all \
    && sbt assembly

FROM apache/hadoop:3
USER root

# Download data
RUN mkdir -p -v /localdata/mds && \
    for file_name in HM3_b37.bed HM3_b37.bim HM3_b37.fam; do \
    wget \
    --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0" \
    --progress=dot:giga -O - "https://genepi.qimr.edu.au/staff/sarahMe/enigma/MDS/${file_name}.gz" | gunzip > /localdata/mds/${file_name}; \
    done
RUN mkdir -p -v /localdata/liftover && \
    for genome_reference in hg16 hg17 hg18 hg38; do \
    file_name="${genome_reference}ToHg19.over.chain.gz"; \
    wget --progress=dot:mega -O "/localdata/liftover/${file_name}" "https://hgdownload.soe.ucsc.edu/goldenPath/${genome_reference}/liftOver/${file_name}"; \
    done
RUN mkdir -p -v /localdata/imputationserver && \
    wget --progress=dot:giga -O "/localdata/imputationserver/1000genomes-phase3.zip" "https://imputationserver.sph.umich.edu/static/downloads/releases/1000genomes-phase3-3.0.0.zip"

# Install Cloudgene.
ENV CLOUDGENE_VERSION=2.6.3
RUN mkdir /opt/cloudgene \
    && cd /opt/cloudgene \
    && curl --silent install.cloudgene.io | bash -s ${CLOUDGENE_VERSION}
ENV PATH="/opt/cloudgene:/usr/local/mambaforge/bin:${PATH}" \
    CPATH="/usr/local/mambaforge/include:${CPATH}" 

# Install additional software
# and make sure `which` is available at `/usr/bin/which/ as per 
# https://github.com/ContinuumIO/anaconda-issues/issues/11133
# and ensure that thew newly installed shared libraries are available 
# to all programs by updating `ldconfig`
RUN wget --progress=dot:giga -O "/tmp/conda.sh" "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh" && \
    bash /tmp/conda.sh -b -p /usr/local/mambaforge && \
    rm -rf /tmp/* && \
    sync && \
    conda config --system --append channels "bioconda" && \
    sync && \
    mamba install --yes \
    "p7zip>=15.09" \
    "zstd" \
    "parallel" \
    "python>=3.11" \
    "r-base" \
    "r-calibrate" \
    "r-knitr" \
    "r-markdown" \
    "r-rmarkdown" \
    "r-ggplot2" \
    "r-data.table" \
    "perl-vcftools-vcf>=0.1.16" \
    "plink" \
    "plink2" \
    "tabix>=1.11" \
    "ucsc-liftover" \
    "m2-less" \
    "which" && \
    sync && \
    mamba clean --yes --all --force-pkgs-dirs && \
    sync && \
    find /usr/local/mambaforge/ -follow -type f -name "*.a" -delete && \
    sync && \
    ln -s /usr/local/mambaforge/bin/which /usr/bin/which && \
    sync && \
    echo /usr/local/mambaforge/lib > /etc/ld.so.conf.d/mambaforge.conf && \
    sync && \
    ldconfig && \
    sync

# Install scripts
COPY bin/* /usr/local/bin/
COPY --from=builder /src/extract-all/target/scala-*/extract-all.jar /usr/local/bin/extract-all.jar

CMD ["/bin/bash"]

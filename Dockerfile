FROM sbtscala/scala-sbt:eclipse-temurin-jammy-19.0.1_10_1.9.0_3.2.2 as builder

COPY src/extract-all /src/extract-all
RUN cd /src/extract-all && \
    sbt assembly

FROM apache/hadoop:3 as downloader
USER root

# Download data
RUN mkdir -p -v /localdata/mds && \
    for file_name in HM3_b37.bed HM3_b37.bim HM3_b37.fam; do \
    wget \
    --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0" \
    --progress=dot:giga --output-document="https://genepi.qimr.edu.au/staff/sarahMe/enigma/MDS/${file_name}.gz" | gunzip > /localdata/mds/${file_name}; \
    done
RUN mkdir -p -v /localdata/liftover && \
    pushd /localdata/liftover/ && \
    for genome_reference in hg16 hg17 hg18 hg38; do \
    file_name="${genome_reference}ToHg19.over.chain.gz"; \
    wget --progress=dot:mega "https://hgdownload.soe.ucsc.edu/goldenPath/${genome_reference}/liftOver/${file_name}" && \
    curl --silent "https://hgdownload.soe.ucsc.edu/goldenPath/${genome_reference}/liftOver/md5sum.txt" | grep "${file_name}" | md5sum --check || exit 1; \
    done && \
    popd
ADD --chmod=655 --checksum=sha256:d441541008cfe7ae1c545631d57ac8ec3dbc646da2155cfce870c5303b133346 \
    "https://github.com/genepi/imputationserver/releases/download/v.1.7.5/imputationserver.zip" \
    "/localdata/imputationserver.zip"
ADD --chmod=655 --checksum=sha256:1910bebd658a406aa0f263bc886151b3060569c808aaf58dc149ad73b1283594  \
    "https://download.gwas.science/imputationserver/1000genomes-phase3-3.0.0.zip" \
    "/localdata/1000genomes-phase3.zip"

FROM apache/hadoop:3
USER root

RUN yum install -y less which && \
    yum clean all -y && \
    sync && \
    rm -rf /var/cache/yum && \
    rm -rf /tmp/* && \
    sync

# Install Cloudgene.
ENV CLOUDGENE_VERSION=2.6.3
RUN mkdir /opt/cloudgene && \
    cd /opt/cloudgene && \
    curl --silent install.cloudgene.io | bash -s ${CLOUDGENE_VERSION}
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
    "tqdm" \
    "r-base" \
    "r-calibrate" \
    "bioconductor-geneplotter" \
    "r-knitr" \
    "r-markdown" \
    "r-rcolorbrewer" \
    "r-rmarkdown" \
    "r-ggplot2" \
    "r-data.table" \
    "perl-vcftools-vcf>=0.1.16" \
    "plink" \
    "plink2" \
    "tabix>=1.11" \
    "ucsc-liftover" && \
    sync && \
    mamba clean --yes --all --force-pkgs-dirs && \
    sync && \
    find /usr/local/mambaforge/ -follow -type f -name "*.a" -delete && \
    sync && \
    echo /usr/local/mambaforge/lib > /etc/ld.so.conf.d/mambaforge.conf && \
    sync && \
    ldconfig && \
    sync

# Install
COPY --from=downloader /localdata /localdata
COPY --from=builder /src/extract-all/target/scala-*/extract-all.jar /usr/local/bin/extract-all.jar
COPY bin/* /usr/local/bin/

CMD ["/bin/bash"]

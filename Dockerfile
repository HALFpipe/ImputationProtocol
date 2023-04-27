FROM genepi/imputationserver:v1.5.7

# download data
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

# install software
RUN wget --progress=dot:mega -O "/tmp/plink_linux.zip" "https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20210606.zip" && \
    unzip /tmp/plink_linux.zip plink -d /usr/local/bin && \
    wget --progress=dot:mega -O "/tmp/plink2_linux.zip" "https://s3.amazonaws.com/plink2-assets/alpha2/plink2_linux_x86_64.zip" && \
    unzip /tmp/plink2_linux.zip plink2 -d /usr/local/bin && \
    wget --progress=dot:giga -O "/tmp/miniconda.sh" "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" && \
    bash /tmp/miniconda.sh -b -p /usr/local/miniconda && \
    wget --progress=dot:mega -O "/tmp/calibrate.tar.gz" "https://cran.r-project.org/src/contrib/Archive/calibrate/calibrate_1.7.2.tar.gz" && \
    R CMD INSTALL /tmp/calibrate.tar.gz && \
    wget --progress=dot:mega -O "/usr/local/bin/liftOver" "https://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver" && \
    rm -rf /tmp/* && sync

ENV PATH="/usr/local/miniconda/bin:$PATH" \
    CPATH="/usr/local/miniconda/include:$CPATH" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

RUN conda config --add channels bioconda && \
    conda install --yes \
    "p7zip>=15.09" \
    "parallel" \
    "perl-vcftools-vcf>=0.1.16" \
    "python>=3.11" \
    "tabix>=1.11" \
    "zstd" && \
    sync && \
    chmod -R a+rX /usr/local/miniconda && \
    sync && \
    chmod +x /usr/local/bin/* /usr/local/miniconda/bin/* && \
    sync && \
    conda clean --yes --all && \
    sync && \
    rm -rf ~/.conda ~/.cache/pip/* && \
    sync

# install scripts
COPY cloudgene-override/* /opt/cloudgene/
COPY bin/* /usr/local/bin/

CMD ["/bin/bash"]
